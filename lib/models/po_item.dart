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
  String saleRate;

  @HiveField(7)
  String marginPerUnit;

  @HiveField(8)
  String totalMargin;

  @HiveField(9)
  Map<String, double> prQuantities =
      {}; // Store PR-wise quantities: PR No -> Quantity

  @HiveField(10)
  Map<String, double> receivedQuantities = {}; // Map of GRN number to received quantity

  double get totalReceivedQuantity =>
      receivedQuantities.values.fold(0.0, (sum, qty) => sum + qty);

  bool get isFullyReceived {
    final totalQty = double.tryParse(quantity) ?? 0.0;
    return totalReceivedQuantity >= totalQty;
  }

  void addReceivedQuantity(String grnNo, double quantity) {
    receivedQuantities[grnNo] = quantity;
  }

  POItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
    required this.saleRate,
    required this.marginPerUnit,
    required this.totalMargin,
    Map<String, double>? prQuantities,
    Map<String, double>? receivedQuantities,
  }) {
    this.prQuantities = prQuantities ?? {};
    this.receivedQuantities = receivedQuantities ?? {};
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
    final sale = double.parse(saleRate);
    final qty = double.parse(quantity);

    totalCost = (qty * cost).toString();
    marginPerUnit = (sale - cost).toString();
    totalMargin = (qty * (sale - cost)).toString();
  }

  // Calculate total rate difference as a number
  double get totalRateDifferenceValue {
    final qty = double.parse(quantity);
    final cost = double.parse(costPerUnit);
    final sale = double.parse(saleRate);
    return (sale - cost) * qty;
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
    String? saleRate,
    String? marginPerUnit,
    String? totalMargin,
    Map<String, double>? prQuantities,
    Map<String, double>? receivedQuantities,
  }) {
    return POItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      totalCost: totalCost ?? this.totalCost,
      saleRate: saleRate ?? this.saleRate,
      marginPerUnit: marginPerUnit ?? this.marginPerUnit,
      totalMargin: totalMargin ?? this.totalMargin,
      prQuantities: prQuantities ?? Map<String, double>.from(this.prQuantities),
      receivedQuantities: receivedQuantities ?? Map<String, double>.from(this.receivedQuantities),
    );
  }
}
