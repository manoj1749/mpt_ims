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
  });
}
