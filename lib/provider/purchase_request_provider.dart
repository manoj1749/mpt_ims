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
      'items': request.items
          .map((item) => {
                'materialCode': item.materialCode,
                'materialDescription': item.materialDescription,
                'unit': item.unit,
                'quantity': item.quantity,
                'prNo': item.prNo,
                'orderedQuantities': item.orderedQuantities,
                'totalReceivedQuantity': item.totalReceivedQuantity,
              })
          .toList(),
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
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => PRItem(
                    materialCode: item['materialCode'] ?? '',
                    materialDescription: item['materialDescription'] ?? '',
                    unit: item['unit'] ?? '',
                    quantity: item['quantity'] ?? '',
                    prNo: item['prNo'] ?? '',
                    orderedQuantities: Map<String, double>.from(
                        item['orderedQuantities'] ?? {}),
                    totalReceivedQuantity:
                        (item['totalReceivedQuantity'] as num?)?.toDouble() ??
                            0.0,
                  ))
              .toList() ??
          [],
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
    if (request.status == 'Partially Ordered' ||
        request.status == 'Completed') {
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

  Future<bool> deleteRequestItem(PurchaseRequest request, PRItem item) async {
    // Block deletion if there is any PO referencing this PR + material code
    final hasActivePOForItem = poBox.values.any((po) => po.items.any((poItem) {
          final matchesPR = poItem.prDetails.containsKey(request.prNo);
          final matchesMaterial = poItem.materialCode == item.materialCode;
          return matchesPR && matchesMaterial;
        }));

    if (hasActivePOForItem) {
      return false;
    }

    final newItems = request.items
        .where((i) =>
            !(i.materialCode == item.materialCode &&
              i.materialDescription == item.materialDescription &&
              i.unit == item.unit &&
              i.quantity == item.quantity))
        .toList();

    // If all items removed, delete entire PR (reuses existing PR deletion rules)
    if (newItems.isEmpty) {
      return delete(request);
    }

    final updated = request.copyWith(items: newItems);
    updated.updateStatus();

    await update(updated);
    return true;
  }

  // Helper methods
  List<PurchaseRequest> searchRequests(String query) {
    return search(
        query,
        (request, query) =>
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

  String generateOrderNumber() {
    // Get current financial year (April to March)
    final now = DateTime.now();
    int financialYear = now.year;
    if (now.month < 4) {
      financialYear--; // If before April, use previous financial year
    }
    final nextFinancialYear = financialYear + 1;

    // Get last 2 digits of current and next financial year
    final currentYearStr = financialYear.toString().substring(2);
    final nextYearStr = nextFinancialYear.toString().substring(2);
    final yearPrefix = '$currentYearStr$nextYearStr';

    // Find all VALID sequential order numbers for the current financial year
    final validSequentialOrders = state.where((request) {
      // Check if PR number matches the expected format: PR + YYYY + 6 digits
      if (!request.prNo.startsWith('PR$yearPrefix') || request.prNo.length != 12) {
        return false;
      }

      // Check if the last 6 characters are all digits
      final sequencePart = request.prNo.substring(6);
      return RegExp(r'^\d{6}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this financial year, start from 1
    if (validSequentialOrders.isEmpty) {
      return 'PR${yearPrefix}000001';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((request) {
      return int.parse(request.prNo.substring(6));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 6-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(6, '0');

    return 'PR$yearPrefix$sequenceStr'; // e.g., PR25260001, PR25260002, etc.
  }
}
