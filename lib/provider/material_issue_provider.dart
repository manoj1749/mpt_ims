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

  // Update issue status
  Future<void> updateStatus(String issueNo, String status) async {
    final issue = getMaterialRequest(issueNo);
    if (issue != null) {
      issue.status = status;
      await updateMaterialRequest(issue);
    }
  }
}

class MaterialIssueProvider with ChangeNotifier {
  final Box<MaterialIssue> _issueBox;
  final Box<MaterialRequest> _requestBox;
  final Box<StockMaintenance> _stockBox;

  MaterialIssueProvider(this._issueBox, this._requestBox, this._stockBox);

  List<MaterialIssue> get issues => _issueBox.values.toList();

  // Get material requests for a specific job number
  List<MaterialRequest> getMaterialRequestsForJob(String jobNo) {
    return _requestBox.values
        .where((mr) => mr.jobNo == jobNo && mr.status != 'Completed')
        .toList();
  }

  // Check if we have sufficient stock for a material request
  bool hasSufficientStock(String materialCode, String jobNo, double requestedQty) {
    final stockItem = _stockBox.values
        .firstWhere((item) => item.materialCode == materialCode);
    
    // Get job-specific stock if it exists
    final jobDetails = stockItem.jobDetails[jobNo];
    if (jobDetails == null) return false;
    
    // For the specific job number, we can only issue what's allocated but not consumed
    final availableQty = jobDetails.allocatedQuantity - jobDetails.consumedQuantity;
    return availableQty >= requestedQty;
  }

  // Create a new material issue
  Future<void> createMaterialIssue(MaterialIssue issue) async {
    // Validate stock availability and update stock for each item
    for (var item in issue.items) {
      for (var mrDetail in item.mrDetails.entries) {
        final jobNo = mrDetail.value.jobNo;
        final requestedQty = mrDetail.value.quantity;
        
        // Get the stock item
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);
        
        // Get job-specific stock if it exists
        final jobDetails = stockItem.jobDetails[jobNo];
        if (jobDetails == null) {
          throw Exception('No stock allocated for job $jobNo');
        }
        
        // Check available quantity
        final availableQty = jobDetails.allocatedQuantity - jobDetails.consumedQuantity;
        if (availableQty < requestedQty) {
          throw Exception('Insufficient stock for ${item.materialDescription} for job $jobNo. Available: $availableQty, Requested: $requestedQty');
        }

        // Get the material request item
        final materialRequest = _requestBox.values.firstWhere(
          (mr) => mr.jobNo == jobNo && mr.items.any((i) => i.issueNo == mrDetail.key),
        );
        final mrItem = materialRequest.items.firstWhere((i) => i.issueNo == mrDetail.key);

        // Check if there's enough pending quantity in the material request
        if (mrItem.pendingQuantity < requestedQty) {
          throw Exception('Cannot issue more than the pending quantity for material request ${mrDetail.key}');
        }
      }
    }

    // If all validations pass, create the issue and update stock
    await _issueBox.add(issue);
    
    // Update stock quantities and material request issued quantities
    for (var item in issue.items) {
      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);
      
      for (var mrDetail in item.mrDetails.entries) {
        final jobNo = mrDetail.value.jobNo;
        final issuedQty = mrDetail.value.quantity;
        
        // Update stock at all levels (PR -> PO -> GRN)
        stockItem.issueStockForJob(jobNo, issue.issueNo, issuedQty);
        await stockItem.save();

        // Update issued quantity in material request
        final materialRequest = _requestBox.values.firstWhere(
          (mr) => mr.jobNo == jobNo && mr.items.any((i) => i.issueNo == mrDetail.key),
        );
        final mrItem = materialRequest.items.firstWhere((i) => i.issueNo == mrDetail.key);
        mrItem.addIssuedQuantity(issue.issueNo, issuedQty);
        await materialRequest.save();

        // If all requested quantity has been issued, update the material request status
        if (mrItem.pendingQuantity <= 0) {
          materialRequest.status = 'Completed';
          await materialRequest.save();
        }
      }
    }

    notifyListeners();
  }

  // Update an existing material issue
  Future<void> updateMaterialIssue(MaterialIssue issue) async {
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      final oldIssue = _issueBox.values.elementAt(index);

      // First, revert the old stock deductions
      for (var item in oldIssue.items) {
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);
        
        for (var mrDetail in item.mrDetails.entries) {
          final jobNo = mrDetail.value.jobNo;
          final issuedQty = mrDetail.value.quantity;
          
          // Revert consumed quantity for the job
          final jobDetails = stockItem.jobDetails[jobNo]!;
          jobDetails.consumedQuantity -= issuedQty;
          await stockItem.save();

          // Revert issued quantity in material request
          final materialRequest = _requestBox.values.firstWhere(
            (mr) => mr.jobNo == jobNo && mr.items.any((i) => i.issueNo == mrDetail.key),
          );
          final mrItem = materialRequest.items.firstWhere((i) => i.issueNo == mrDetail.key);
          mrItem.removeIssuedQuantity(issue.issueNo);
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
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      final issue = _issueBox.values.elementAt(index);

      // Revert stock deductions
      for (var item in issue.items) {
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);
        
        for (var mrDetail in item.mrDetails.entries) {
          final jobNo = mrDetail.value.jobNo;
          final issuedQty = mrDetail.value.quantity;
          
          // Revert consumed quantity for the job
          final jobDetails = stockItem.jobDetails[jobNo]!;
          jobDetails.consumedQuantity -= issuedQty;
          await stockItem.save();

          // Revert issued quantity in material request
          final materialRequest = _requestBox.values.firstWhere(
            (mr) => mr.jobNo == jobNo && mr.items.any((i) => i.issueNo == mrDetail.key),
          );
          final mrItem = materialRequest.items.firstWhere((i) => i.issueNo == mrDetail.key);
          mrItem.removeIssuedQuantity(issueNo);
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
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      await _issueBox.putAt(index, issue);
      state = _issueBox.values.toList();
    }
  }

  Future<void> deleteMaterialIssue(String issueNo) async {
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
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

final materialIssueProvider =
    StateNotifierProvider<MaterialIssueNotifier, List<MaterialIssue>>((ref) {
  final box = ref.watch(materialIssueBoxProvider);
  return MaterialIssueNotifier(box, ref);
});
