import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_order.dart';

final purchaseOrderBoxProvider = Provider<Box<PurchaseOrder>>((ref) {
  throw UnimplementedError();
});

final purchaseOrderListProvider =
    StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
        (ref) => PurchaseOrderNotifier(ref.read(purchaseOrderBoxProvider)));

class PurchaseOrderNotifier extends StateNotifier<List<PurchaseOrder>> {
  final Box<PurchaseOrder> _box;

  PurchaseOrderNotifier(this._box) : super(_box.values.toList());

  void addOrder(PurchaseOrder order) {
    _box.add(order);
    state = _box.values.toList();
  }

  void updateOrder(int index, PurchaseOrder order) {
    _box.putAt(index, order);
    state = _box.values.toList();
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
      return true;
    }
    return false;
  }

  void clearAll() {
    _box.clear();
    state = [];
  }
}
