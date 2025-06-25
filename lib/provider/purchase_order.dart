import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  PurchaseOrderNotifier(this._box, this._syncService) : super(_box.values.toList());

  Future<void> addOrder(PurchaseOrder order) async {
    await _box.add(order);
    state = _box.values.toList();
    await _syncToFirebase();
  }

  Future<void> updateOrder(int index, PurchaseOrder order) async {
    await _box.putAt(index, order);
    state = _box.values.toList();
    await _syncToFirebase();
  }

  Future<bool> deleteOrder(PurchaseOrder order) async {
    // Check if PO has partial or completed receipts
    if (order.status == 'Partially Received' || order.status == 'Completed') {
      return false; // Cannot delete PO that has received items
    }

    final index = state.indexOf(order);
    if (index != -1) {
      await _box.deleteAt(index);
      state = List.from(state)..removeAt(index);
      await _syncToFirebase();
      return true;
    }
    return false;
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = [];
    await _syncToFirebase();
  }

  Future<void> refresh() async {
    try {
      await _syncFromFirebase();
      state = _box.values.toList();
    } catch (e) {
      print('Error refreshing purchase orders: $e');
      rethrow;
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('purchase_orders', _box);
    } catch (e) {
      print('Error syncing purchase orders to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'purchase_orders',
        _box,
        _syncService.purchaseOrderFromMap,
      );
    } catch (e) {
      print('Error syncing purchase orders from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
