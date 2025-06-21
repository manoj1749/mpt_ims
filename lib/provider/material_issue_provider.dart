// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_request.dart';
import '../models/material_issue.dart';
import '../models/stock_maintenance.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'material_request_provider.dart';

final MaterialRequestListProvider =
    NotifierProvider<MaterialRequestNotifier, List<MaterialRequest>>(
  () => MaterialRequestNotifier(),
);

class MaterialRequestNotifier extends Notifier<List<MaterialRequest>> {
  late Box<MaterialRequest> _issueBox;

  @override
  List<MaterialRequest> build() {
    _issueBox = ref.watch(materialRequestBoxProvider);
    return _issueBox.values.toList();
  }

  // Add a new Material Request
  Future<void> addMaterialRequest(MaterialRequest issue) async {
    await _issueBox.add(issue);
    state = [...state, issue];
  }

  // Update an existing Material Request
  Future<void> updateMaterialRequest(MaterialRequest issue) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      await _issueBox.putAt(index, issue);
      state = [..._issueBox.values];
    }
  }

  // Delete a Material Request
  Future<void> deleteMaterialRequest(String issueNo) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      await _issueBox.deleteAt(index);
      state = [..._issueBox.values];
    }
  }

  // Get a Material Request by issue number
  MaterialRequest? getMaterialRequest(String issueNo) {
    try {
      return _issueBox.values.firstWhere(
        (issue) => issue.issueNo == issueNo,
        orElse: () => throw Exception('Material Request not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Generate new issue number
  String generateIssueNo() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    // Get count of issues for today
    final todayIssues = _issueBox.values.where((issue) {
      return issue.issueNo.startsWith('MI$year$month$day');
    }).length;

    final count = (todayIssues + 1).toString().padLeft(3, '0');
    return 'MI$year$month$day$count';
  }
}

class MaterialIssueProvider with ChangeNotifier {
  final Box<MaterialIssue> _issueBox;
  final Box<MaterialRequest> _requestBox;
  final Box<StockMaintenance> _stockBox;

  MaterialIssueProvider(this._issueBox, this._requestBox, this._stockBox) {
    // Print all material issues when provider is initialized
    print('\n=== Material Issues Debug ===');
    for (var issue in _issueBox.values) {
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
          print('    Issued Quantities: ${item.issuedQuantities[mrDetail.key]}');
        }
      }
    }
  }

  List<MaterialIssue> get issues => _issueBox.values.toList();

  // Get material requests for a specific job number
  List<MaterialRequest> getMaterialRequestsForJob(String jobNo) {
    return _requestBox.values
        .where((mr) => mr.jobNo == jobNo && mr.status != 'Completed')
        .toList();
  }

  // Check if we have sufficient stock for a material request in the specific job
  bool hasSufficientStock(
      String materialCode, String jobNo, double requestedQty) {
    final stockItem = _stockBox.values
        .firstWhere((item) => item.materialCode == materialCode);

    // Get job-specific stock if it exists
    final jobDetails = stockItem.jobDetails[jobNo];
    if (jobDetails == null) return false;

    // For the specific job number, we can only issue what's allocated but not consumed
    final availableQty =
        jobDetails.allocatedQuantity - jobDetails.consumedQuantity;
    return availableQty >= requestedQty;
  }

  // Create a new material issue
  Future<void> createMaterialIssue(MaterialIssue issue) async {
    print('\n=== Creating Material Issue ===');
    print('Issue No: ${issue.issueNo}');
    print('Issue Date: ${issue.issueDate}');
    print('Job Numbers: ${issue.formattedJobNo}');

    // Validate stock availability and update stock for each item
    for (var item in issue.items) {
      print('\nChecking Item: ${item.materialCode} - ${item.materialDescription}');
      
      for (var mrDetail in item.mrDetails.entries) {
        final mrNo = mrDetail.key;
        final jobNo = mrDetail.value.jobNo;
        final requestedQty = mrDetail.value.quantity;

        print('\n  MR No: $mrNo');
        print('  Job No: $jobNo');
        print('  Requested Qty: $requestedQty');

        // Get the stock item
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);
        
        print('  Current Stock: ${stockItem.currentStock}');
        if (stockItem.jobDetails.containsKey(jobNo)) {
          final jobStock = stockItem.jobDetails[jobNo]!;
          print('  Job Stock - Allocated: ${jobStock.allocatedQuantity}, Consumed: ${jobStock.consumedQuantity}');
        }

        // Get the material request
        final materialRequest = _requestBox.values.firstWhere(
          (mr) => mr.issueNo == mrNo,
          orElse: () => throw Exception('Material Request $mrNo not found'),
        );

        print('  MR Status: ${materialRequest.status}');

        // Get the material request item
        final mrItem = materialRequest.items
            .firstWhere((i) => i.materialCode == item.materialCode);

        print('  MR Item - Total Qty: ${mrItem.quantity}, Issued: ${mrItem.totalIssuedQuantity}, Pending: ${mrItem.pendingQuantity}');

        // Check if there's enough pending quantity in the material request
        if (mrItem.pendingQuantity < requestedQty) {
          throw Exception(
              'Cannot issue more than the pending quantity for material request $mrNo');
        }

        // Find available PR for the job that has stock
        final prInfo = stockItem.findAvailablePRForJob(jobNo, requestedQty);
        if (prInfo == null) {
          throw Exception('No available stock found for job $jobNo');
        }
        print('  Found PR: ${prInfo.$1} with available qty: ${prInfo.$2}');
      }
    }

    // If all validations pass, create the issue and update stock
    await _issueBox.add(issue);
    print('\nMaterial Issue created successfully');

    // Update stock quantities and material request issued quantities
    for (var item in issue.items) {
      print('\nUpdating stock for: ${item.materialCode}');
      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      for (var mrDetail in item.mrDetails.entries) {
        final mrNo = mrDetail.key;
        final jobNo = mrDetail.value.jobNo;
        final issuedQty = mrDetail.value.quantity;

        print('\n  Updating MR: $mrNo');
        print('  Job No: $jobNo');
        print('  Issued Qty: $issuedQty');

        // Get the material request
        final materialRequest = _requestBox.values.firstWhere(
          (mr) => mr.issueNo == mrNo,
        );
        final mrItem = materialRequest.items
            .firstWhere((i) => i.materialCode == item.materialCode);

        // Update issued quantity in material request
        mrItem.addIssuedQuantity(issue.issueNo, issuedQty);
        print('  Updated MR Item - Total Issued: ${mrItem.totalIssuedQuantity}, Pending: ${mrItem.pendingQuantity}');

        // Issue stock from the specific job's allocation
        stockItem.issueStockForJob(jobNo, issue.issueNo, issuedQty);
        print('  Updated Job Stock');

        // If all requested quantity has been issued, update the material request status
        if (mrItem.pendingQuantity <= 0) {
          materialRequest.status = 'Completed';
          print('  MR Status updated to Completed');
        }
        await materialRequest.save();
      }
      await stockItem.save();
    }

    notifyListeners();
    print('\nMaterial Issue process completed successfully');
  }

  // Update an existing material issue
  Future<void> updateMaterialIssue(MaterialIssue issue) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      final oldIssue = _issueBox.values.elementAt(index);

      // First, revert the old stock deductions
      for (var item in oldIssue.items) {
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);

        for (var mrDetail in item.mrDetails.entries) {
          final jobNo = mrDetail.value.jobNo;
          final issuedQty = mrDetail.value.quantity;

          // Revert job-specific consumed quantity
          final jobDetails = stockItem.jobDetails[jobNo]!;
          jobDetails.consumedQuantity -= issuedQty;
          await stockItem.save();

          // Revert issued quantity in material request
          final materialRequest = _requestBox.values.firstWhere(
            (mr) =>
                mr.jobNo == jobNo &&
                mr.items.any((i) => i.issueNo == mrDetail.key),
          );
          final mrItem = materialRequest.items
              .firstWhere((i) => i.issueNo == mrDetail.key);
          mrItem.removeIssuedQuantity(issue.issueNo);

          // Reset material request status if needed
          if (materialRequest.status == 'Completed' &&
              mrItem.pendingQuantity > 0) {
            materialRequest.status = 'Active';
          }
          await materialRequest.save();
        }
      }

      // Then validate and apply the new issue
      await createMaterialIssue(issue);
      await _issueBox.putAt(index, issue);
      notifyListeners();
    }
  }

  // Delete a material issue
  Future<void> deleteMaterialIssue(String issueNo) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      final issue = _issueBox.values.elementAt(index);

      // Revert stock deductions
      for (var item in issue.items) {
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);

        for (var mrDetail in item.mrDetails.entries) {
          final jobNo = mrDetail.value.jobNo;
          final issuedQty = mrDetail.value.quantity;

          // Revert job-specific consumed quantity
          final jobDetails = stockItem.jobDetails[jobNo]!;
          jobDetails.consumedQuantity -= issuedQty;
          await stockItem.save();

          // Revert issued quantity in material request
          final materialRequest = _requestBox.values.firstWhere(
            (mr) =>
                mr.jobNo == jobNo &&
                mr.items.any((i) => i.issueNo == mrDetail.key),
          );
          final mrItem = materialRequest.items
              .firstWhere((i) => i.issueNo == mrDetail.key);
          mrItem.removeIssuedQuantity(issueNo);

          // Reset material request status if needed
          if (materialRequest.status == 'Completed' &&
              mrItem.pendingQuantity > 0) {
            materialRequest.status = 'Active';
          }
          await materialRequest.save();
        }
      }

      await _issueBox.deleteAt(index);
      notifyListeners();
    }
  }

  // Get a material issue by its number
  MaterialIssue? getMaterialIssueByNo(String issueNo) {
    try {
      return _issueBox.values.firstWhere((issue) => issue.issueNo == issueNo);
    } catch (e) {
      return null;
    }
  }
}

final materialIssueBoxProvider = Provider<Box<MaterialIssue>>((ref) {
  throw UnimplementedError();
});

final materialIssueListProvider = Provider<List<MaterialIssue>>((ref) {
  final box = ref.watch(materialIssueBoxProvider);
  return box.values.toList();
});

final materialIssueProvider =
    StateNotifierProvider<MaterialIssueNotifier, List<MaterialIssue>>((ref) {
  final box = ref.watch(materialIssueBoxProvider);
  return MaterialIssueNotifier(box, ref);
});

class MaterialIssueNotifier extends StateNotifier<List<MaterialIssue>> {
  late Box<MaterialIssue> _issueBox;
  final Ref ref;

  MaterialIssueNotifier(Box<MaterialIssue> box, this.ref) : super([]) {
    _issueBox = box;
    state = _issueBox.values.toList();
  }

  List<MaterialIssue> get issues => state;

  Future<void> createMaterialIssue(MaterialIssue issue) async {
    await _issueBox.add(issue);
    state = _issueBox.values.toList();
  }

  Future<void> updateMaterialIssue(MaterialIssue issue) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      await _issueBox.putAt(index, issue);
      state = _issueBox.values.toList();
    }
  }

  Future<void> deleteMaterialIssue(String issueNo) async {
    final index =
        _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      await _issueBox.deleteAt(index);
      state = _issueBox.values.toList();
    }
  }

  MaterialIssue? getMaterialIssueByNo(String issueNo) {
    try {
      return _issueBox.values.firstWhere((issue) => issue.issueNo == issueNo);
    } catch (e) {
      return null;
    }
  }
}
