import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';
import 'base_provider.dart';
import 'store_inward_provider.dart';
import '../utils/company_config.dart';

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
                'originalCostPerUnit': item.originalCostPerUnit,
                'amendedCostPerUnit': item.amendedCostPerUnit,
                'amendmentHistory': item.amendmentHistory
                    .map((e) => {
                          'dateTime': e.dateTime,
                          'oldPrice': e.oldPrice,
                          'newPrice': e.newPrice,
                        })
                    .toList(),
              })
          .toList(),
      'total': order.total,
      'igst': order.igst,
      'cgst': order.cgst,
      'sgst': order.sgst,
      'grandTotal': order.grandTotal,
      'status': order.status,
      'hasAmendments': order.hasAmendments,
      'isForeclosed': order.isForeclosed,
      'foreclosureReason': order.foreclosureReason,
      'foreclosureDate': order.foreclosureDate,
      'hasGR': order.hasGR,
      'previousPONo': order.previousPONo,
      'isServiceBill': order.isServiceBill,
    };
  }

  Map<String, dynamic> mapFromModel(PurchaseOrder order) {
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
                'originalCostPerUnit': item.originalCostPerUnit,
                'amendedCostPerUnit': item.amendedCostPerUnit,
                'amendmentHistory': item.amendmentHistory
                    .map((e) => {
                          'dateTime': e.dateTime,
                          'oldPrice': e.oldPrice,
                          'newPrice': e.newPrice,
                        })
                    .toList(),
                'termsAndConditions': item.termsAndConditions,
              })
          .toList(),
      'total': order.total,
      'igst': order.igst,
      'cgst': order.cgst,
      'sgst': order.sgst,
      'grandTotal': order.grandTotal,
      'status': order.status,
      'hasAmendments': order.hasAmendments,
      'isForeclosed': order.isForeclosed,
      'foreclosureReason': order.foreclosureReason,
      'foreclosureDate': order.foreclosureDate,
      'hasGR': order.hasGR,
      'previousPONo': order.previousPONo,
      'isServiceBill': order.isServiceBill,
    };
  }

  @override
  PurchaseOrder mapToModel(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>? ?? [])
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
              originalCostPerUnit:
                  (item['originalCostPerUnit'] as num?)?.toDouble(),
              amendedCostPerUnit:
                  (item['amendedCostPerUnit'] as num?)?.toDouble(),
              amendmentHistory: (item['amendmentHistory'] as List<dynamic>?)
                      ?.map((e) => AmendmentEntry(
                            dateTime: e['dateTime'] ?? '',
                            oldPrice:
                                (e['oldPrice'] as num?)?.toDouble() ?? 0.0,
                            newPrice:
                                (e['newPrice'] as num?)?.toDouble() ?? 0.0,
                          ))
                      .toList() ??
                  [],
            ))
        .toList();

    final inferredServiceBill = (map['poNo']?.toString().startsWith('SB-PO-') ??
            false) ||
        (items.isNotEmpty && items.every((i) => i.materialCode == 'SERVICE'));

    bool? parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return null;
    }

    final parsedIsServiceBill = parseBool(map['isServiceBill']);

    return PurchaseOrder(
      poNo: map['poNo'] ?? '',
      poDate: map['poDate'] ?? '',
      supplierName: map['supplierName'] ?? '',
      transport: map['transport'] ?? '',
      deliveryRequirements: map['deliveryRequirements'] ?? '',
      items: items,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      igst: (map['igst'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      status: map['status'],
      hasAmendments: map['hasAmendments'] ?? false,
      isForeclosed: map['isForeclosed'] ?? false,
      foreclosureReason: map['foreclosureReason'],
      foreclosureDate: map['foreclosureDate'],
      hasGR: map['hasGR'] ?? false,
      previousPONo: map['previousPONo'],
      isServiceBill: parsedIsServiceBill ?? inferredServiceBill,
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
    final existingIndex =
        box.values.toList().indexWhere((o) => o.poNo == order.poNo);
    final resolvedIndex = existingIndex != -1 ? existingIndex : index;

    final existingOrder = box.getAt(resolvedIndex);
    if (existingOrder == null) return;

    // Enforce GR lock: block updates if any GR exists for this PO
    if (_ref != null) {
      final storeInwardBox = _ref!.read(storeInwardBoxProvider);
      final hasGRs = storeInwardBox.values.any((inward) =>
          inward.poNo == existingOrder.poNo &&
          inward.items.any(
              (item) => item.prQuantities.containsKey(existingOrder.poNo)));
      if (hasGRs) {
        return; // silently ignore updates; UI should also block
      }
    }

    // Amendment tracking is now handled in add_purchase_order_page.dart
    // Just save the order as-is
    await update(order);
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
    return state
        .where((order) => !order.isFullyReceived && !order.isForeclosed)
        .toList();
  }

  // Foreclose a PO with reason
  Future<void> foreclosePO(PurchaseOrder order, String reason) async {
    final updatedOrder = order.copyWith(
      isForeclosed: true,
      foreclosureReason: reason,
      foreclosureDate: DateTime.now().toIso8601String(),
      status: 'Foreclosed',
    );
    await update(updatedOrder);
  }

  String generateOrderNumber() {
    // Prefix depends on company configuration:
    // MagnetPowerTech -> 'M', Aimant Industries -> 'AI'.
    final prefix = poNumberPrefix;

    // Current year (last 2 digits) + current month (2 digits), e.g. 2608
    // for August 2026.
    final now = DateTime.now();
    final yearStr = now.year.toString().substring(2);
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$yearStr$monthStr';

    final fullPrefix = '$prefix$yearMonthPrefix';
    final expectedLength = fullPrefix.length + 2;

    // Find all VALID sequential order numbers for the current prefix+month
    final validSequentialOrders = state.where((order) {
      // Check if PO number matches the expected format: prefix + YYMM + 2 digits
      if (!order.poNo.startsWith(fullPrefix) ||
          order.poNo.length != expectedLength) {
        return false;
      }

      // Check if the last 2 characters are all digits
      final sequencePart = order.poNo.substring(fullPrefix.length);
      return RegExp(r'^\d{2}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this month, start from 1
    if (validSequentialOrders.isEmpty) {
      return '${fullPrefix}01';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((order) {
      return int.parse(order.poNo.substring(fullPrefix.length));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 2-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(2, '0');

    return '$fullPrefix$sequenceStr'; // e.g., M260901, AI260901, etc.
  }
}
