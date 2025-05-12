import 'package:hive/hive.dart';

part 'sale_order.g.dart';

@HiveType(typeId: 14)
class SaleOrder extends HiveObject {
  @HiveField(0)
  String orderNo;

  @HiveField(1)
  String orderDate;

  @HiveField(2)
  String customerName;

  @HiveField(3)
  String boardNo;

  @HiveField(10)
  String status; // Draft, Confirmed, Delivered, Cancelled

  SaleOrder({
    required this.orderNo,
    required this.orderDate,
    required this.customerName,
    required this.boardNo,
    this.status = 'Draft',
  });
} 