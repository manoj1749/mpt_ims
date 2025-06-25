import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  PurchaseRequestNotifier(this.box, this.poBox, this._syncService)
      : super(box.values.toList());

  Future<void> addRequest(PurchaseRequest request) async {
    await box.add(request);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> updateRequest(int index, PurchaseRequest updated) async {
    await box.putAt(index, updated);
    state = box.values.toList();
    await _syncToFirebase();
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

    final index = state.indexOf(request);
    if (index != -1) {
      await box.deleteAt(index);
      state = List.from(state)..removeAt(index);
      await _syncToFirebase();
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    try {
      await _syncFromFirebase();
      state = box.values.toList();
    } catch (e) {
      print('Error refreshing purchase requests: $e');
      rethrow;
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('purchase_requests', box);
    } catch (e) {
      print('Error syncing purchase requests to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'purchase_requests',
        box,
        _syncService.purchaseRequestFromMap,
      );
    } catch (e) {
      print('Error syncing purchase requests from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
