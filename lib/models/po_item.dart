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
  String marginPerUnit;

  @HiveField(8)
  String totalMargin;

  @HiveField(9)
  Map<String, double> prQuantities =
      {}; // Store PR-wise quantities: PR No -> Quantity

  POItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
    required this.seiplRate,
    required this.marginPerUnit,
    required this.totalMargin,
    Map<String, double>? prQuantities,
  }) {
    this.prQuantities = prQuantities ?? {};
  }

  void updateQuantity(String newQuantity) {
    quantity = newQuantity;
    final qty = double.parse(newQuantity);
    final cost = double.parse(costPerUnit);
    final margin = double.parse(marginPerUnit);
    totalCost = (qty * cost).toString();
    totalMargin = (qty * margin).toString();
  }

  void updateCostPerUnit(String newCostPerUnit) {
    costPerUnit = newCostPerUnit;
    final cost = double.parse(newCostPerUnit);
    final seipl = double.parse(seiplRate);
    final qty = double.parse(quantity);

    totalCost = (qty * cost).toString();
    marginPerUnit = (seipl - cost).toString();
    totalMargin = (qty * (seipl - cost)).toString();
  }

  // Calculate total rate difference as a number
  double get totalRateDifferenceValue {
    final qty = double.parse(quantity);
    final cost = double.parse(costPerUnit);
    final seipl = double.parse(seiplRate);
    return (seipl - cost) * qty;
  }

  // Return total rate difference as a formatted string
  String get totalRateDifference {
    return totalRateDifferenceValue.toString();
  }

  POItem copyWith({
    String? materialCode,
    String? materialDescription,
    String? unit,
    String? quantity,
    String? costPerUnit,
    String? totalCost,
    String? seiplRate,
    String? marginPerUnit,
    String? totalMargin,
    Map<String, double>? prQuantities,
  }) {
    return POItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      totalCost: totalCost ?? this.totalCost,
      seiplRate: seiplRate ?? this.seiplRate,
      marginPerUnit: marginPerUnit ?? this.marginPerUnit,
      totalMargin: totalMargin ?? this.totalMargin,
      prQuantities: prQuantities ?? Map<String, double>.from(this.prQuantities),
    );
  }
}
