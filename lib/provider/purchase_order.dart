import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_order.dart';
import '../services/sync_service.dart';

final purchaseOrderBoxProvider = Provider<Box<PurchaseOrder>>((ref) {
  throw UnimplementedError();
});

final purchaseOrderListProvider =
    StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
        (ref) => PurchaseOrderNotifier(
          ref.read(purchaseOrderBoxProvider),
          ref.read(syncServiceProvider),
        ));

class PurchaseOrderNotifier extends StateNotifier<List<PurchaseOrder>> {
  final Box<PurchaseOrder> _box;
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PurchaseOrderNotifier(this._box, this._syncService) : super([]) {
    // Load purchase orders when initialized
    loadPurchaseOrders();
  }

  Future<void> loadPurchaseOrders() async {
    try {
      print('Loading purchase order data from Firestore...');
      final querySnapshot = await _firestore.collection('purchase_orders').get();
      print('Found ${querySnapshot.docs.length} purchase orders in Firestore');

      // Clear existing purchase orders from Hive
      await _box.clear();

      // Add new purchase orders to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final order = _syncService.purchaseOrderFromMap(data);
        await _box.add(order);
      }

      // Update state
      state = _box.values.toList();
      print('Successfully loaded purchase order data');
    } catch (e) {
      print('Error loading purchase order data: $e');
      rethrow;
    }
  }

  Future<void> addOrder(PurchaseOrder order) async {
    try {
      // Add to Firestore first
      final docRef = _firestore.collection('purchase_orders').doc(order.poNo);
      final data = _convertToMap(order);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await _box.add(order);

      // Update state
      state = _box.values.toList();
    } catch (e) {
      print('Error adding purchase order: $e');
      rethrow;
    }
  }

  Future<void> updateOrder(int index, PurchaseOrder order) async {
    try {
      // Update in Firestore first
      final docRef = _firestore.collection('purchase_orders').doc(order.poNo);
      final data = _convertToMap(order);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.update(data);

      // Then update in Hive
      await _box.putAt(index, order);

      // Update state
      state = _box.values.toList();
    } catch (e) {
      print('Error updating purchase order: $e');
      rethrow;
    }
  }

  Future<bool> deleteOrder(PurchaseOrder order) async {
    // Check if PO has partial or completed receipts
    if (order.status == 'Partially Received' || order.status == 'Completed') {
      return false; // Cannot delete PO that has received items
    }

    try {
      final index = state.indexOf(order);
      if (index != -1) {
        // Delete from Firestore first
        final docRef = _firestore.collection('purchase_orders').doc(order.poNo);
        await docRef.delete();

        // Then delete from Hive
        await _box.deleteAt(index);

        // Update state
        state = List.from(state)..removeAt(index);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting purchase order: $e');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      // Delete all documents from Firestore first
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection('purchase_orders').get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then clear Hive
      await _box.clear();

      // Update state
      state = [];
    } catch (e) {
      print('Error clearing all purchase orders: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await loadPurchaseOrders();
    } catch (e) {
      print('Error refreshing purchase orders: $e');
      rethrow;
    }
  }

  // Helper method to convert PurchaseOrder to Map
  Map<String, dynamic> _convertToMap(PurchaseOrder order) {
    return {
      'poNo': order.poNo,
      'poDate': order.poDate,
      'supplierName': order.supplierName,
      'transport': order.transport,
      'deliveryRequirements': order.deliveryRequirements,
      'items': order.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'costPerUnit': item.costPerUnit,
        'totalCost': item.totalCost,
        'saleRate': item.saleRate,
        'marginPerUnit': item.marginPerUnit,
        'totalMargin': item.totalMargin,
        'prDetails': item.prDetails.map((key, value) => MapEntry(key, {
          'prNo': value.prNo,
          'jobNo': value.jobNo,
          'quantity': value.quantity,
        })),
        'receivedQuantities': item.receivedQuantities,
      }).toList(),
      'total': order.total,
      'igst': order.igst,
      'cgst': order.cgst,
      'sgst': order.sgst,
      'grandTotal': order.grandTotal,
      'status': order.status,
    };
  }
}
