import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_request.dart';
import '../models/purchase_order.dart';

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
  ),
);

class PurchaseRequestNotifier extends StateNotifier<List<PurchaseRequest>> {
  final Box<PurchaseRequest> box;
  final Box<PurchaseOrder> poBox;

  PurchaseRequestNotifier(this.box, this.poBox) : super(box.values.toList());

  Future<void> addRequest(PurchaseRequest request) async {
    await box.add(request);
    state = box.values.toList();
  }

  Future<void> updateRequest(int index, PurchaseRequest updated) async {
    await box.putAt(index, updated);
    state = box.values.toList();
  }

  Future<bool> deleteRequest(PurchaseRequest request) async {
    // Check if PR has partial or completed orders
    if (request.status == 'Partially Ordered' || request.status == 'Completed') {
      // Check if any PO exists for this PR
      bool hasActivePO = poBox.values.any((po) => 
        po.items.any((poItem) => 
          poItem.prDetails.containsKey(request.prNo)
        )
      );

      if (hasActivePO) {
        return false; // Cannot delete PR while PO exists
      }
    }

    final index = state.indexOf(request);
    if (index != -1) {
      await box.deleteAt(index);
      state = List.from(state)..removeAt(index);
      return true;
    }
    return false;
  }
}
