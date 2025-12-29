// lib/models/purchase_order.dart
import 'package:hive/hive.dart';
import 'po_item.dart';
part 'purchase_order.g.dart';

@HiveType(typeId: 4)
class PurchaseOrder extends HiveObject {
  @HiveField(0)
  String poNo;

  @HiveField(1)
  String poDate;

  @HiveField(2)
  String supplierName;

  @HiveField(4)
  String transport;

  @HiveField(5)
  String deliveryRequirements;

  @HiveField(6)
  List<POItem> items;

  @HiveField(7)
  double total;

  @HiveField(8)
  double igst;

  @HiveField(9)
  double cgst;

  @HiveField(10)
  double sgst;

  @HiveField(11)
  double grandTotal;

  @HiveField(12)
  String? _status;

  @HiveField(13, defaultValue: false)
  bool hasAmendments = false;

  @HiveField(14, defaultValue: false)
  bool isForeclosed = false;

  @HiveField(15)
  String? foreclosureReason;

  @HiveField(16)
  String? foreclosureDate;

  @HiveField(17, defaultValue: false)
  bool hasGR = false;

  @HiveField(18)
  String? previousPONo;

  @HiveField(19)
  String? originalPoDate;

  @HiveField(20, defaultValue: false)
  bool isServiceBill = false;

  String get status => _status ?? 'Placed';

  set status(String value) {
    _status = value;
  }

  bool get isFullyReceived {
    return items.every((item) => item.isFullyReceived);
  }

  // Get all unique job numbers from all items
  Set<String> get jobNumbers {
    final jobs = <String>{};
    for (var item in items) {
      for (var prDetail in item.prDetails.values) {
        if (prDetail.jobNo != 'General') {
          jobs.add(prDetail.jobNo);
        }
      }
    }
    return jobs;
  }

  // Check if this PO contains any general stock items
  bool get hasGeneralStockItems {
    return items.any((item) =>
        item.prDetails.values.any((detail) => detail.jobNo == 'General'));
  }

  // Get a formatted string for board number display
  String get formattedBoardNo {
    final jobs = jobNumbers;
    if (jobs.isEmpty && hasGeneralStockItems) {
      return 'General Stock';
    } else if (jobs.isNotEmpty) {
      return jobs.join(', ');
    } else {
      return 'General Stock';
    }
  }

  // Update PO status based on received quantities
  void updateStatus() {
    if (isFullyReceived) {
      status = 'Completed';
      return;
    }

    // Check if any PR in any item has received quantities
    bool hasPartiallyReceived = false;
    for (var item in items) {
      for (var prDetail in item.prDetails.entries) {
        final prNo = prDetail.key;
        final receivedQty = item.getReceivedQuantityForPR(prNo);
        if (receivedQty > 0) {
          hasPartiallyReceived = true;
          break;
        }
      }
      if (hasPartiallyReceived) break;
    }

    status = hasPartiallyReceived ? 'Partially Received' : 'Placed';
  }

  PurchaseOrder({
    required this.poNo,
    required this.poDate,
    required this.supplierName,
    required this.transport,
    required this.deliveryRequirements,
    required this.items,
    required this.total,
    required this.igst,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    String? status,
    bool? hasAmendments,
    this.isForeclosed = false,
    this.foreclosureReason,
    this.foreclosureDate,
    this.hasGR = false,
    this.previousPONo,
    this.originalPoDate,
    this.isServiceBill = false,
  }) {
    _status = status;
    this.hasAmendments = hasAmendments ?? false;
  }

  PurchaseOrder copyWith({
    String? poNo,
    String? poDate,
    String? supplierName,
    String? transport,
    String? deliveryRequirements,
    List<POItem>? items,
    double? total,
    double? igst,
    double? cgst,
    double? sgst,
    double? grandTotal,
    String? status,
    bool? hasAmendments,
    bool? isForeclosed,
    String? foreclosureReason,
    String? foreclosureDate,
    bool? hasGR,
    String? previousPONo,
    String? originalPoDate,
    bool? isServiceBill,
  }) {
    return PurchaseOrder(
      poNo: poNo ?? this.poNo,
      poDate: poDate ?? this.poDate,
      supplierName: supplierName ?? this.supplierName,
      transport: transport ?? this.transport,
      deliveryRequirements: deliveryRequirements ?? this.deliveryRequirements,
      items: items ?? this.items.map((item) => item.copyWith()).toList(),
      total: total ?? this.total,
      igst: igst ?? this.igst,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? _status,
      hasAmendments: hasAmendments ?? this.hasAmendments,
      isForeclosed: isForeclosed ?? this.isForeclosed,
      foreclosureReason: foreclosureReason ?? this.foreclosureReason,
      foreclosureDate: foreclosureDate ?? this.foreclosureDate,
      hasGR: hasGR ?? this.hasGR,
      previousPONo: previousPONo ?? this.previousPONo,
      originalPoDate: originalPoDate ?? this.originalPoDate,
      isServiceBill: isServiceBill ?? this.isServiceBill,
    );
  }
}
