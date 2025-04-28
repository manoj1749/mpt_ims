import 'package:hive/hive.dart';

part 'po_item.g.dart';

@HiveType(typeId: 5)
class POItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  String quantity;

  @HiveField(4)
  String costPerUnit;

  @HiveField(5)
  String totalCost;

  @HiveField(6)
  String seiplRate;

  @HiveField(7)
  String rateDifference;

  @HiveField(8)
  String totalRateDifference;

  @HiveField(9)
  String marginPerUnit;

  @HiveField(10)
  String totalMargin;

  POItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
    required this.seiplRate,
    this.rateDifference = '0.0',
    this.totalRateDifference = '0.0',
    this.marginPerUnit = '0.0',
    this.totalMargin = '0.0',
  });

  void updateQuantity(String newQuantity) {
    quantity = newQuantity;
    final qty = double.parse(newQuantity);
    final cost = double.parse(costPerUnit);
    final margin = double.parse(marginPerUnit);
    totalCost = (qty * cost).toString();
    totalMargin = (qty * margin).toString();
    totalRateDifference = (qty * double.parse(rateDifference)).toString();
  }

  void updateCostPerUnit(String newCostPerUnit) {
    costPerUnit = newCostPerUnit;
    final cost = double.parse(newCostPerUnit);
    final seipl = double.parse(seiplRate);
    final qty = double.parse(quantity);

    totalCost = (qty * cost).toString();
    rateDifference = (seipl - cost).toString();
    totalRateDifference = (qty * (seipl - cost)).toString();
    marginPerUnit = (seipl - cost).toString();
    totalMargin = (qty * (seipl - cost)).toString();
  }
}
