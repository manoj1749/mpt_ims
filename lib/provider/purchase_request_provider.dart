import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_request.dart';
import '../models/pr_item.dart';
import '../models/purchase_order.dart';
import 'base_provider.dart';

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

class PurchaseRequestNotifier extends BaseProvider<PurchaseRequest> {
  final Box<PurchaseOrder> poBox;

  PurchaseRequestNotifier(Box<PurchaseRequest> box, this.poBox)
      : super(box, 'purchase_requests');

  @override
  Map<String, dynamic> modelToMap(PurchaseRequest request) {
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

  @override
  PurchaseRequest mapToModel(Map<String, dynamic> map) {
    return PurchaseRequest(
      prNo: map['prNo'] ?? '',
      date: map['date'] ?? '',
      requiredBy: map['requiredBy'] ?? '',
      status: map['status'] ?? 'Draft',
      jobNo: map['jobNo'],
      items: (map['items'] as List<dynamic>?)?.map((item) => PRItem(
        materialCode: item['materialCode'] ?? '',
        materialDescription: item['materialDescription'] ?? '',
        unit: item['unit'] ?? '',
        quantity: item['quantity'] ?? '',
        prNo: item['prNo'] ?? '',
        orderedQuantities: Map<String, double>.from(item['orderedQuantities'] ?? {}),
        totalReceivedQuantity: (item['totalReceivedQuantity'] as num?)?.toDouble() ?? 0.0,
      )).toList() ?? [],
    );
  }

  @override
  String getModelId(PurchaseRequest request) => request.prNo;

  // Backward compatibility methods
  Future<void> loadPurchaseRequests() => loadData();
  Future<void> addRequest(PurchaseRequest request) => add(request);
  Future<void> updateRequest(int index, PurchaseRequest updated) async {
    await update(updated);
  }

  @override
  Future<bool> delete(PurchaseRequest request) async {
    // Check if PR has partial or completed orders
    if (request.status == 'Partially Ordered' || request.status == 'Completed') {
      // Check if any PO exists for this PR
      bool hasActivePO = poBox.values.any((po) =>
          po.items.any((poItem) => poItem.prDetails.containsKey(request.prNo)));

      if (hasActivePO) {
        return false; // Cannot delete PR while PO exists
      }
    }

    return super.delete(request);
  }

  Future<bool> deleteRequest(PurchaseRequest request) => delete(request);

  // Helper methods
  List<PurchaseRequest> searchRequests(String query) {
    return search(query, (request, query) =>
        request.prNo.toLowerCase().contains(query) ||
        request.requiredBy.toLowerCase().contains(query) ||
        request.status.toLowerCase().contains(query) ||
        (request.jobNo?.toLowerCase().contains(query) ?? false));
  }

  PurchaseRequest? getRequestByNo(String prNo) {
    try {
      return state.firstWhere((request) => request.prNo == prNo);
    } catch (e) {
      return null;
    }
  }
}
