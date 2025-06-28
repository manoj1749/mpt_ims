import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_request.dart';
import '../models/purchase_order.dart';
import '../services/sync_service.dart';

final purchaseRequestBoxProvider = Provider<Box<PurchaseRequest>>((ref) {
  throw UnimplementedError();
});

final prPurchaseOrderBoxProvider = Provider<Box<PurchaseOrder>>((ref) {
  throw UnimplementedError();
});

final purchaseRequestListProvider =
    StateNotifierProvider<PurchaseRequestNotifier, List<PurchaseRequest>>(
  (ref) => PurchaseRequestNotifier(
    ref.read(purchaseRequestBoxProvider),
    ref.read(prPurchaseOrderBoxProvider),
    ref.read(syncServiceProvider),
  ),
);

class PurchaseRequestNotifier extends StateNotifier<List<PurchaseRequest>> {
  final Box<PurchaseRequest> box;
  final Box<PurchaseOrder> poBox;
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PurchaseRequestNotifier(this.box, this.poBox, this._syncService)
      : super([]) {
    // Load purchase requests when initialized
    loadPurchaseRequests();
  }

  Future<void> loadPurchaseRequests() async {
    try {
      print('Loading purchase request data from Firestore...');
      final querySnapshot = await _firestore.collection('purchase_requests').get();
      print('Found ${querySnapshot.docs.length} purchase requests in Firestore');

      // Clear existing purchase requests from Hive
      await box.clear();

      // Add new purchase requests to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final request = _syncService.purchaseRequestFromMap(data);
        await box.add(request);
      }

      // Update state
      state = box.values.toList();
      print('Successfully loaded purchase request data');
    } catch (e) {
      print('Error loading purchase request data: $e');
      rethrow;
    }
  }

  Future<void> addRequest(PurchaseRequest request) async {
    try {
      // Add to Firestore first
      final docRef = _firestore.collection('purchase_requests').doc(request.prNo);
      final data = _convertToMap(request);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(request);

      // Update state
      state = box.values.toList();
    } catch (e) {
      print('Error adding purchase request: $e');
      rethrow;
    }
  }

  Future<void> updateRequest(int index, PurchaseRequest updated) async {
    try {
      // Update in Firestore first
      final docRef = _firestore.collection('purchase_requests').doc(updated.prNo);
      final data = _convertToMap(updated);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.update(data);

      // Then update in Hive
      await box.putAt(index, updated);

      // Update state
      state = box.values.toList();
    } catch (e) {
      print('Error updating purchase request: $e');
      rethrow;
    }
  }

  Future<bool> deleteRequest(PurchaseRequest request) async {
    // Check if PR has partial or completed orders
    if (request.status == 'Partially Ordered' ||
        request.status == 'Completed') {
      // Check if any PO exists for this PR
      bool hasActivePO = poBox.values.any((po) =>
          po.items.any((poItem) => poItem.prDetails.containsKey(request.prNo)));

      if (hasActivePO) {
        return false; // Cannot delete PR while PO exists
      }
    }

    try {
      final index = state.indexOf(request);
      if (index != -1) {
        // Delete from Firestore first
        final docRef = _firestore.collection('purchase_requests').doc(request.prNo);
        await docRef.delete();

        // Then delete from Hive
        await box.deleteAt(index);

        // Update state
        state = List.from(state)..removeAt(index);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting purchase request: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await loadPurchaseRequests();
    } catch (e) {
      print('Error refreshing purchase requests: $e');
      rethrow;
    }
  }

  // Helper method to convert PurchaseRequest to Map
  Map<String, dynamic> _convertToMap(PurchaseRequest request) {
    return {
      'prNo': request.prNo,
      'date': request.date,
      'requiredBy': request.requiredBy,
      'status': request.status,
      'jobNo': request.jobNo,
      'items': request.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'prNo': item.prNo,
        'orderedQuantities': item.orderedQuantities,
        'totalReceivedQuantity': item.totalReceivedQuantity,
      }).toList(),
    };
  }
}
