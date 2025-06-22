// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_request.dart';
import '../models/material_issue.dart';
import '../models/stock_maintenance.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'material_request_provider.dart';

final materialIssueBoxProvider = Provider<Box<MaterialIssue>>((ref) {
  return Hive.box<MaterialIssue>('material_issues');
});

final materialIssueListProvider = Provider<List<MaterialIssue>>((ref) {
  final box = ref.watch(materialIssueBoxProvider);
  return box.values.toList();
});

class MaterialIssueNotifier extends StateNotifier<List<MaterialIssue>> {
  final Box<MaterialIssue> _issueBox;
  final Box<MaterialRequest> _requestBox;
  final Box<StockMaintenance> _stockBox;
  final Ref ref;

  MaterialIssueNotifier(
      this._issueBox, this._requestBox, this._stockBox, this.ref)
      : super([]) {
    state = _issueBox.values.toList();

    // Print debug info
    print('\n=== Material Issues Debug ===');
    for (var issue in state) {
      print('\nMaterial Issue: ${issue.issueNo}');
      print('Issue Date: ${issue.issueDate}');
      print('Issued To: ${issue.issuedTo}');
      print('Job Numbers: ${issue.formattedJobNo}');

      for (var item in issue.items) {
        print('\n  Item: ${item.materialCode} - ${item.materialDescription}');
        print('  Quantity: ${item.quantity} ${item.unit}');

        for (var mrDetail in item.mrDetails.entries) {
          print('\n    MR No: ${mrDetail.key}');
          print('    Job No: ${mrDetail.value.jobNo}');
          print('    Quantity: ${mrDetail.value.quantity}');
        }
      }
    }
  }

  List<MaterialIssue> get issues => state;

  // Get material requests for a specific job number
  List<MaterialRequest> getMaterialRequestsForJob(String jobNo) {
    return _requestBox.values
        .where((mr) => mr.jobNo == jobNo && mr.status != 'Completed')
        .toList();
  }

  // Check if we have sufficient stock for a material request in the specific job
  bool hasSufficientStock(
      String materialCode, String jobNo, double requestedQty) {
    try {
      final stockItem = _stockBox.values
          .firstWhere((item) => item.materialCode == materialCode);

      // Get job-specific stock if it exists
      final jobDetails = stockItem.jobDetails[jobNo];
      if (jobDetails == null) {
        print('No job details found for job $jobNo');
        return false;
      }

      // For the specific job number, we can only issue what's allocated but not consumed
      final availableQty =
          jobDetails.allocatedQuantity - jobDetails.consumedQuantity;
      print(
          'Available quantity for job $jobNo: $availableQty (Allocated: ${jobDetails.allocatedQuantity}, Consumed: ${jobDetails.consumedQuantity})');
      return availableQty >= requestedQty;
    } catch (e) {
      print('Error checking stock: $e');
      return false;
    }
  }

  // Create a new material issue
  Future<void> createMaterialIssue(MaterialIssue issue) async {
    print('\n=== Creating Material Issue ===');
    print('Issue No: ${issue.issueNo}');
    print('Issue Date: ${issue.issueDate}');
    print('Job Numbers: ${issue.formattedJobNo}');

    // Validate stock availability for each item
    for (var item in issue.items) {
      print(
          '\nChecking Item: ${item.materialCode} - ${item.materialDescription}');

      for (var mrDetail in item.mrDetails.entries) {
        final mrNo = mrDetail.key;
        final jobNo = mrDetail.value.jobNo;
        final requestedQty = mrDetail.value.quantity;

        print('\n  MR No: $mrNo');
        print('  Job No: $jobNo');
        print('  Requested Qty: $requestedQty');

        // Validate stock availability
        if (!hasSufficientStock(item.materialCode, jobNo, requestedQty)) {
          throw Exception(
              'Insufficient stock for material ${item.materialCode} in job $jobNo');
        }

        // Get and validate material request
        final materialRequest = _requestBox.values.firstWhere(
          (mr) => mr.issueNo == mrNo,
          orElse: () => throw Exception('Material Request $mrNo not found'),
        );

        final mrItem = materialRequest.items.firstWhere(
          (i) => i.materialCode == item.materialCode,
          orElse: () => throw Exception(
              'Material ${item.materialCode} not found in MR $mrNo'),
        );

        // Check pending quantity
        if (mrItem.pendingQuantity < requestedQty) {
          throw Exception(
              'Cannot issue more than pending quantity for MR $mrNo');
        }
      }
    }

    // If all validations pass, create the issue and update stock
    await _issueBox.add(issue);
    state = [...state, issue];
    print('\nMaterial Issue created successfully');

    // Update stock and material request status
    await _updateStockAndMRStatus(issue);
  }

  // Update an existing material issue
  Future<void> updateMaterialIssue(MaterialIssue issue) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      final oldIssue = _issueBox.values.elementAt(index);

      // First revert the old stock deductions and MR status
      await _revertStockAndMRStatus(oldIssue);

      // Then validate and apply the new issue
      await createMaterialIssue(issue);
      await _issueBox.putAt(index, issue);
      state = [...state.where((i) => i.issueNo != issue.issueNo), issue];
    }
  }

  // Delete a material issue
  Future<void> deleteMaterialIssue(String issueNo) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      final issue = _issueBox.values.elementAt(index);
      await _revertStockAndMRStatus(issue);
      await _issueBox.deleteAt(index);
      state = state.where((i) => i.issueNo != issueNo).toList();
    }
  }

  // Helper method to update stock and MR status
  Future<void> _updateStockAndMRStatus(MaterialIssue issue) async {
    print('\n=== Updating Stock and MR Status ===');
    for (var item in issue.items) {
      print('\nProcessing Item: ${item.materialCode}');
      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      for (var mrDetail in item.mrDetails.entries) {
        final mrNo = mrDetail.key;
        final jobNo = mrDetail.value.jobNo;
        final issuedQty = mrDetail.value.quantity;

        print('\n  MR No: $mrNo');
        print('  Job No: $jobNo');
        print('  Issued Qty: $issuedQty');

        // Find the oldest PR for this job that has available stock
        final prInfo = stockItem.findAvailablePRForJob(jobNo, issuedQty);
        if (prInfo == null) {
          throw Exception('No available PR found for job $jobNo');
        }

        final prNo = prInfo.$1;
        print('  Selected PR: $prNo');

        // Issue stock using the stock maintenance method
        stockItem.issueStockForJob(jobNo, issue.issueNo, issuedQty);
        await stockItem.save();
        print('  Stock updated successfully');

        // Update material request
        final materialRequest =
            _requestBox.values.firstWhere((mr) => mr.issueNo == mrNo);
        final mrItem = materialRequest.items
            .firstWhere((i) => i.materialCode == item.materialCode);

        print(
            '  Before MR update - Total Issued: ${mrItem.totalIssuedQuantity}, Pending: ${mrItem.pendingQuantity}');
        mrItem.addIssuedQuantity(issue.issueNo, issuedQty);
        print(
            '  After MR update - Total Issued: ${mrItem.totalIssuedQuantity}, Pending: ${mrItem.pendingQuantity}');

        // Check if all items in this MR are fully issued
        bool allItemsIssued = materialRequest.items.every((item) {
          print(
              '    Item ${item.materialCode} - Pending: ${item.pendingQuantity}');
          return item.pendingQuantity <= 0;
        });

        if (allItemsIssued) {
          print('  All items in MR fully issued, marking as Completed');
          materialRequest.status = 'Completed';
          await materialRequest.save();
          print('  Material Request status updated to Completed');
        } else {
          print('  Not all items are fully issued, keeping status as Active');
          materialRequest.status = 'Active';
          await materialRequest.save();
        }
      }
    }
    print('\nStock and MR Status update completed');
  }

  // Helper method to revert stock and MR status
  Future<void> _revertStockAndMRStatus(MaterialIssue issue) async {
    print('\n=== Reverting Stock and MR Status ===');
    for (var item in issue.items) {
      print('\nProcessing Item: ${item.materialCode}');
      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      for (var mrDetail in item.mrDetails.entries) {
        final mrNo = mrDetail.key;
        final jobNo = mrDetail.value.jobNo;
        final issuedQty = mrDetail.value.quantity;

        print('\n  MR No: $mrNo');
        print('  Job No: $jobNo');
        print('  Issued Qty to revert: $issuedQty');

        // Find the PR that was used for this issue
        final prInfo = stockItem.findAvailablePRForJob(jobNo, issuedQty);
        if (prInfo != null) {
          final prNo = prInfo.$1;
          print('  Found PR: $prNo');

          // Revert stock in all related records
          final prDetail = stockItem.prDetails[prNo]!;
          prDetail.issuedQuantity -= issuedQty;

          // Find and update related PO and GRN records
          for (var poDetail in stockItem.poDetails.values) {
            for (var grnQtys in poDetail.receivedQuantities.values) {
              if (grnQtys.containsKey(prNo)) {
                final grnNo = poDetail.receivedQuantities.entries
                    .firstWhere((e) => e.value.containsKey(prNo))
                    .key;
                final grnDetail = stockItem.grnDetails[grnNo]!;
                grnDetail.issuedQuantity -= issuedQty;
              }
            }
          }

          // Update job details
          final jobDetail = stockItem.jobDetails[jobNo]!;
          jobDetail.consumedQuantity -= issuedQty;
        }

        await stockItem.save();
        print('  Stock reverted successfully');

        // Revert material request
        final materialRequest =
            _requestBox.values.firstWhere((mr) => mr.issueNo == mrNo);
        final mrItem = materialRequest.items
            .firstWhere((i) => i.materialCode == item.materialCode);

        print(
            '  Before MR revert - Total Issued: ${mrItem.totalIssuedQuantity}, Pending: ${mrItem.pendingQuantity}');
        mrItem.removeIssuedQuantity(issue.issueNo);
        print(
            '  After MR revert - Total Issued: ${mrItem.totalIssuedQuantity}, Pending: ${mrItem.pendingQuantity}');

        // Update MR status
        if (materialRequest.status == 'Completed' &&
            mrItem.pendingQuantity > 0) {
          print('  Reverting MR status to Active');
          materialRequest.status = 'Active';
        }
        await materialRequest.save();
        print('  Material Request reverted successfully');
      }
    }
    print('\nStock and MR Status revert completed');
  }

  MaterialIssue? getMaterialIssueByNo(String issueNo) {
    try {
      return _issueBox.values.firstWhere((issue) => issue.issueNo == issueNo);
    } catch (e) {
      return null;
    }
  }

  String generateIssueNo() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final todayIssues = _issueBox.values.where((issue) {
      return issue.issueNo.startsWith('MI$year$month$day');
    }).length;

    final count = (todayIssues + 1).toString().padLeft(3, '0');
    return 'MI$year$month$day$count';
  }
}

final materialIssueProvider =
    StateNotifierProvider<MaterialIssueNotifier, List<MaterialIssue>>((ref) {
  final issueBox = ref.watch(materialIssueBoxProvider);
  final requestBox = ref.watch(materialRequestBoxProvider);
  final stockBox = Hive.box<StockMaintenance>('stock_maintenance');
  return MaterialIssueNotifier(issueBox, requestBox, stockBox, ref);
});
