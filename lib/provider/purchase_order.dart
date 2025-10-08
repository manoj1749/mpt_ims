import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';
import 'base_provider.dart';
import 'store_inward_provider.dart';

final purchaseOrderBoxProvider = Provider<Box<PurchaseOrder>>((ref) {
  throw UnimplementedError();
});

final purchaseOrderListProvider =
    StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
  (ref) => PurchaseOrderNotifier(ref.read(purchaseOrderBoxProvider), ref),
);

class PurchaseOrderNotifier extends BaseProvider<PurchaseOrder> {
  final StateNotifierProviderRef? _ref;

  PurchaseOrderNotifier(Box<PurchaseOrder> box, [this._ref])
      : super(box, 'purchase_orders');

  @override
  Map<String, dynamic> modelToMap(PurchaseOrder order) {
    return {
      'poNo': order.poNo,
      'poDate': order.poDate,
      'supplierName': order.supplierName,
      'transport': order.transport,
      'deliveryRequirements': order.deliveryRequirements,
      'items': order.items
          .map((item) => {
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
              })
          .toList(),
      'total': order.total,
      'igst': order.igst,
      'cgst': order.cgst,
      'sgst': order.sgst,
      'grandTotal': order.grandTotal,
      'status': order.status,
    };
  }

  @override
  PurchaseOrder mapToModel(Map<String, dynamic> map) {
    return PurchaseOrder(
      poNo: map['poNo'] ?? '',
      poDate: map['poDate'] ?? '',
      supplierName: map['supplierName'] ?? '',
      transport: map['transport'] ?? '',
      deliveryRequirements: map['deliveryRequirements'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => POItem(
                materialCode: item['materialCode'] ?? '',
                materialDescription: item['materialDescription'] ?? '',
                unit: item['unit'] ?? '',
                quantity: item['quantity'] ?? '0',
                costPerUnit: item['costPerUnit'] ?? '0',
                totalCost: item['totalCost'] ?? '0',
                saleRate: item['saleRate'] ?? '0',
                marginPerUnit: item['marginPerUnit'] ?? '0',
                totalMargin: item['totalMargin'] ?? '0',
                prDetails: POItem.castPRDetails(item['prDetails']),
                receivedQuantities:
                    POItem.castReceivedQuantities(item['receivedQuantities']),
              ))
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      igst: (map['igst'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      status: map['status'],
    );
  }

  @override
  String getModelId(PurchaseOrder order) => order.poNo;

  @override
  Future<bool> delete(PurchaseOrder order) async {
    // Check if PO has any GRs (received items)
    if (_ref != null) {
      final storeInwardBox = _ref!.read(storeInwardBoxProvider);
      bool hasGRs = storeInwardBox.values.any((inward) => inward.items
          .any((item) => item.prQuantities.containsKey(order.poNo)));

      if (hasGRs) {
        return false; // Cannot delete PO with received items
      }
    }

    return super.delete(order);
  }

  // Map old method names to new base provider methods
  Future<void> loadOrders() => loadData();
  Future<void> addOrder(PurchaseOrder order) => add(order);
  Future<void> updateOrder(int index, PurchaseOrder order) async {
    final existingOrder = box.getAt(index);
    if (existingOrder != null) {
      await update(order);
    }
  }

  Future<bool> deleteOrder(PurchaseOrder order) => delete(order);

  // Helper methods
  PurchaseOrder? getOrderByNo(String poNo) {
    try {
      return state.firstWhere((order) => order.poNo == poNo);
    } catch (_) {
      return null;
    }
  }

  List<PurchaseOrder> getOrdersBySupplier(String supplierName) {
    return state.where((order) => order.supplierName == supplierName).toList();
  }

  List<PurchaseOrder> getOrdersByStatus(String status) {
    return state.where((order) => order.status == status).toList();
  }

  List<PurchaseOrder> searchOrders(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((order) =>
            order.poNo.toLowerCase().contains(lowercaseQuery) ||
            order.supplierName.toLowerCase().contains(lowercaseQuery) ||
            order.status.toLowerCase().contains(lowercaseQuery) ||
            order.items.any((item) =>
                item.materialCode.toLowerCase().contains(lowercaseQuery) ||
                item.materialDescription
                    .toLowerCase()
                    .contains(lowercaseQuery)))
        .toList();
  }

  List<PurchaseOrder> getPendingOrders() {
    return state.where((order) => !order.isFullyReceived).toList();
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
    final validSequentialOrders = state.where((order) {
      // Check if PO number matches the expected format: PO + YYYY + 6 digits
      if (!order.poNo.startsWith('PO$yearPrefix') || order.poNo.length != 12) {
        return false;
      }

      // Check if the last 6 characters are all digits
      final sequencePart = order.poNo.substring(6);
      return RegExp(r'^\d{6}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this financial year, start from 1
    if (validSequentialOrders.isEmpty) {
      return 'PO${yearPrefix}000001';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((order) {
      return int.parse(order.poNo.substring(6));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 6-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(6, '0');

    return 'PO$yearPrefix$sequenceStr'; // e.g., PO25260001, PO25260002, etc.
  }
}
