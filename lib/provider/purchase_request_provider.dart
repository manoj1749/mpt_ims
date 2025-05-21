import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_request.dart';

final purchaseRequestBoxProvider = Provider<Box<PurchaseRequest>>((ref) {
  throw UnimplementedError();
});

final purchaseRequestListProvider =
    StateNotifierProvider<PurchaseRequestNotifier, List<PurchaseRequest>>(
  (ref) => PurchaseRequestNotifier(ref.read(purchaseRequestBoxProvider)),
);

class PurchaseRequestNotifier extends StateNotifier<List<PurchaseRequest>> {
  final Box<PurchaseRequest> box;

  PurchaseRequestNotifier(this.box) : super(box.values.toList());

  Future<void> addRequest(PurchaseRequest request) async {
    await box.add(request);
    state = box.values.toList();
  }

  Future<void> updateRequest(int index, PurchaseRequest updated) async {
    await box.putAt(index, updated);
    state = box.values.toList();
  }

  Future<void> deleteRequest(PurchaseRequest request) async {
    final index = state.indexOf(request);
    if (index != -1) {
      await box.deleteAt(index);
      state = List.from(state)..removeAt(index);
    }
  }
}
