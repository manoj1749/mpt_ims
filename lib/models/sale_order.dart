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

  @HiveField(4)
  String jobStartDate;

  @HiveField(5)
  String targetDate;

  @HiveField(6)
  String? endDate;

  SaleOrder({
    required this.orderNo,
    required this.orderDate,
    required this.customerName,
    required this.boardNo,
    required this.jobStartDate,
    required this.targetDate,
    this.endDate,
  });

  bool get isCompleted => endDate != null;
} 