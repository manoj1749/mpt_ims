// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/material_request.dart';

final materialRequestBoxProvider = Provider<Box<MaterialRequest>>((ref) {
  return Hive.box<MaterialRequest>('material_requests');
});

final materialRequestListProvider = Provider<List<MaterialRequest>>((ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return box.values.toList();
});

class MaterialRequestProvider extends StateNotifier<List<MaterialRequest>> {
  final Box<MaterialRequest> _box;

  MaterialRequestProvider(this._box) : super(_box.values.toList()) {
    // Print all material requests when provider is initialized
    print('\n=== Material Requests Debug ===');
    for (var mr in _box.values) {
      print('\nMaterial Request: ${mr.issueNo}');
      print('Date: ${mr.date}');
      print('Job No: ${mr.jobNo}');
      print('Issued By: ${mr.issuedBy}');
      print('Status: ${mr.status}');
      
      for (var item in mr.items) {
        print('\n  Item: ${item.materialCode} - ${item.materialDescription}');
        print('  Quantity: ${item.quantity} ${item.unit}');
        print('  Total Issued: ${item.totalIssuedQuantity}');
        print('  Pending: ${item.pendingQuantity}');
        
        if (item.issuedQuantities.isNotEmpty) {
          print('\n  Issued Quantities:');
          for (var entry in item.issuedQuantities.entries) {
            print('    MI ${entry.key}: ${entry.value}');
          }
        }
      }
    }
  }

  List<MaterialRequest> get requests => state;

  // Get active requests for a specific job
  List<MaterialRequest> getActiveRequestsForJob(String jobNo) {
    return state.where((mr) => 
      mr.jobNo == jobNo && 
      mr.status != 'Completed' &&
      mr.items.any((item) => item.pendingQuantity > 0)
    ).toList();
  }

  Future<void> addMaterialRequest(MaterialRequest request) async {
    print('\n=== Adding Material Request ===');
    print('Issue No: ${request.issueNo}');
    print('Date: ${request.date}');
    print('Job No: ${request.jobNo}');
    print('Status: ${request.status}');
    
    for (var item in request.items) {
      print('\n  Item: ${item.materialCode} - ${item.materialDescription}');
      print('  Quantity: ${item.quantity} ${item.unit}');
    }

    await _box.add(request);
    state = _box.values.toList();
    print('Material Request added successfully');
  }

  Future<void> updateMaterialRequest(MaterialRequest request) async {
    print('\n=== Updating Material Request ===');
    print('Issue No: ${request.issueNo}');
    print('Date: ${request.date}');
    print('Job No: ${request.jobNo}');
    print('Status: ${request.status}');
    
    for (var item in request.items) {
      print('\n  Item: ${item.materialCode} - ${item.materialDescription}');
      print('  Quantity: ${item.quantity} ${item.unit}');
      print('  Total Issued: ${item.totalIssuedQuantity}');
      print('  Pending: ${item.pendingQuantity}');
      
      if (item.issuedQuantities.isNotEmpty) {
        print('\n  Issued Quantities:');
        for (var entry in item.issuedQuantities.entries) {
          print('    MI ${entry.key}: ${entry.value}');
        }
      }
    }

    final index = _box.values.toList().indexWhere((r) => r.issueNo == request.issueNo);
    if (index != -1) {
      await _box.putAt(index, request);
      state = _box.values.toList();
      print('Material Request updated successfully');
    } else {
      print('Error: Material Request not found');
    }
  }

  Future<void> updateMaterialRequestStatus(String issueNo, {bool checkCompletion = true}) async {
    final request = getMaterialRequestByNo(issueNo);
    if (request != null) {
      if (checkCompletion) {
        // Check if all items are fully issued
        bool allItemsIssued = request.items.every((item) => item.pendingQuantity <= 0);
        request.status = allItemsIssued ? 'Completed' : 'Active';
      }
      await updateMaterialRequest(request);
    }
  }

  Future<void> deleteMaterialRequest(String issueNo) async {
    print('\n=== Deleting Material Request ===');
    print('Issue No: $issueNo');
    
    final index = _box.values.toList().indexWhere((r) => r.issueNo == issueNo);
    if (index != -1) {
      await _box.deleteAt(index);
      state = _box.values.toList();
      print('Material Request deleted successfully');
    } else {
      print('Error: Material Request not found');
    }
  }

  MaterialRequest? getMaterialRequestByNo(String issueNo) {
    try {
      final request = _box.values.firstWhere((request) => request.issueNo == issueNo);
      print('\n=== Getting Material Request ===');
      print('Issue No: ${request.issueNo}');
      print('Date: ${request.date}');
      print('Job No: ${request.jobNo}');
      print('Status: ${request.status}');
      return request;
    } catch (e) {
      print('Error: Material Request not found');
      return null;
    }
  }

  String generateIssueNo() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    // Get count of issues for today
    final todayIssues = _box.values.where((issue) {
      return issue.issueNo.startsWith('MR$year$month$day');
    }).length;

    final count = (todayIssues + 1).toString().padLeft(3, '0');
    return 'MR$year$month$day$count';
  }
}

final materialRequestProvider =
    StateNotifierProvider<MaterialRequestProvider, List<MaterialRequest>>(
        (ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return MaterialRequestProvider(box);
});
