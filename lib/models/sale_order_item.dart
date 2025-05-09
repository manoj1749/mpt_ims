import 'package:hive/hive.dart';

part 'sale_order_item.g.dart';

@HiveType(typeId: 17)
class SaleOrderItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double quantity;

  SaleOrderItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
  });

  void updateQuantity(double newQuantity) {
    quantity = newQuantity;
  }
} 