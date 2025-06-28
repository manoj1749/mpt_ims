// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/material_request.dart';
import '../services/sync_service.dart';

final materialRequestBoxProvider = Provider<Box<MaterialRequest>>((ref) {
  return Hive.box<MaterialRequest>('material_requests');
});

final materialRequestListProvider = Provider<List<MaterialRequest>>((ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return box.values.toList();
});

class MaterialRequestProvider extends StateNotifier<List<MaterialRequest>> {
  final Box<MaterialRequest> _box;
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MaterialRequestProvider(this._box, this._syncService) : super([]) {
    // Load material requests when initialized
    loadMaterialRequests();
  }

  Future<void> loadMaterialRequests() async {
    try {
      print('Loading material request data from Firestore...');
      final querySnapshot = await _firestore.collection('material_requests').get();
      print('Found ${querySnapshot.docs.length} material requests in Firestore');

      // Clear existing material requests from Hive
      await _box.clear();

      // Add new material requests to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final request = _syncService.materialRequestFromMap(data);
        await _box.add(request);
      }

      // Update state
      state = _box.values.toList();
      print('Successfully loaded material request data');

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
    } catch (e) {
      print('Error loading material request data: $e');
      rethrow;
    }
  }

  List<MaterialRequest> get requests => state;

  // Get active requests for a specific job
  List<MaterialRequest> getActiveRequestsForJob(String jobNo) {
    return state
        .where((mr) =>
            mr.jobNo == jobNo &&
            mr.status != 'Completed' &&
            mr.items.any((item) => item.pendingQuantity > 0))
        .toList();
  }

  Future<void> addMaterialRequest(MaterialRequest request) async {
    try {
      print('\n=== Adding Material Request ===');
      print('Issue No: ${request.issueNo}');
      print('Date: ${request.date}');
      print('Job No: ${request.jobNo}');
      print('Status: ${request.status}');

      for (var item in request.items) {
        print('\n  Item: ${item.materialCode} - ${item.materialDescription}');
        print('  Quantity: ${item.quantity} ${item.unit}');
      }

      // Add to Firestore first
      final docRef = _firestore.collection('material_requests').doc(request.issueNo);
      final data = _convertToMap(request);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await _box.add(request);

      // Update state
      state = _box.values.toList();
      print('Material Request added successfully');
    } catch (e) {
      print('Error adding material request: $e');
      rethrow;
    }
  }

  Future<void> updateMaterialRequest(MaterialRequest request) async {
    try {
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

      final index =
          _box.values.toList().indexWhere((r) => r.issueNo == request.issueNo);
      if (index != -1) {
        // Update in Firestore first
        final docRef = _firestore.collection('material_requests').doc(request.issueNo);
        final data = _convertToMap(request);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);

        // Then update in Hive
        await _box.putAt(index, request);

        // Update state
        state = _box.values.toList();
        print('Material Request updated successfully');
      } else {
        print('Error: Material Request not found');
      }
    } catch (e) {
      print('Error updating material request: $e');
      rethrow;
    }
  }

  Future<void> updateMaterialRequestStatus(String issueNo,
      {bool checkCompletion = true}) async {
    final request = getMaterialRequestByNo(issueNo);
    if (request != null) {
      if (checkCompletion) {
        // Check if all items are fully issued
        bool allItemsIssued =
            request.items.every((item) => item.pendingQuantity <= 0);
        request.status = allItemsIssued ? 'Completed' : 'Active';
      }
      await updateMaterialRequest(request);
    }
  }

  Future<void> deleteMaterialRequest(String issueNo) async {
    try {
      print('\n=== Deleting Material Request ===');
      print('Issue No: $issueNo');

      final index = _box.values.toList().indexWhere((r) => r.issueNo == issueNo);
      if (index != -1) {
        // Delete from Firestore first
        final docRef = _firestore.collection('material_requests').doc(issueNo);
        await docRef.delete();

        // Then delete from Hive
        await _box.deleteAt(index);

        // Update state
        state = _box.values.toList();
        print('Material Request deleted successfully');
      } else {
        print('Error: Material Request not found');
      }
    } catch (e) {
      print('Error deleting material request: $e');
      rethrow;
    }
  }

  MaterialRequest? getMaterialRequestByNo(String issueNo) {
    try {
      final request =
          _box.values.firstWhere((request) => request.issueNo == issueNo);
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

  Future<void> refresh() async {
    try {
      await loadMaterialRequests();
    } catch (e) {
      print('Error refreshing material requests: $e');
      rethrow;
    }
  }

  // Helper method to convert MaterialRequest to Map
  Map<String, dynamic> _convertToMap(MaterialRequest request) {
    return {
      'issueNo': request.issueNo,
      'date': request.date,
      'jobNo': request.jobNo,
      'issuedBy': request.issuedBy,
      'status': request.status,
      'items': request.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'totalIssuedQuantity': item.totalIssuedQuantity,
        'issuedQuantities': item.issuedQuantities,
      }).toList(),
    };
  }
}

final materialRequestProvider =
    StateNotifierProvider<MaterialRequestProvider, List<MaterialRequest>>(
        (ref) {
  final box = ref.watch(materialRequestBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return MaterialRequestProvider(box, syncService);
});
