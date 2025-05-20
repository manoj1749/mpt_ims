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

  @HiveField(3)
  String boardNo;

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

  String get status => _status ?? 'Draft';

  set status(String value) {
    _status = value;
  }

  bool get isFullyReceived => items.every((item) => item.isFullyReceived);

  void updateStatus() {
    if (isFullyReceived) {
      status = 'Completed';
    } else if (items.any((item) => item.totalReceivedQuantity > 0)) {
      status = 'Partially Received';
    } else {
      status = 'Draft';
    }
  }

  PurchaseOrder({
    required this.poNo,
    required this.poDate,
    required this.supplierName,
    required this.boardNo,
    required this.transport,
    required this.deliveryRequirements,
    required this.items,
    required this.total,
    required this.igst,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    String? status,
  }) {
    _status = status;
  }

  PurchaseOrder copyWith({
    String? poNo,
    String? poDate,
    String? supplierName,
    String? boardNo,
    String? transport,
    String? deliveryRequirements,
    List<POItem>? items,
    double? total,
    double? igst,
    double? cgst,
    double? sgst,
    double? grandTotal,
    String? status,
  }) {
    return PurchaseOrder(
      poNo: poNo ?? this.poNo,
      poDate: poDate ?? this.poDate,
      supplierName: supplierName ?? this.supplierName,
      boardNo: boardNo ?? this.boardNo,
      transport: transport ?? this.transport,
      deliveryRequirements: deliveryRequirements ?? this.deliveryRequirements,
      items: items ?? this.items.map((item) => item.copyWith()).toList(),
      total: total ?? this.total,
      igst: igst ?? this.igst,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? _status,
    );
  }
}
