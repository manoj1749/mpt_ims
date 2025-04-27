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

  void deleteOrder(int index) {
    _box.deleteAt(index);
    state = _box.values.toList();
  }

  void clearAll() {
    _box.clear();
    state = [];
  }
}

final purchaseOrderProvider =
    StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>((ref) {
  final box = Hive.box<PurchaseOrder>('purchase_orders');
  return PurchaseOrderNotifier(box);
});
