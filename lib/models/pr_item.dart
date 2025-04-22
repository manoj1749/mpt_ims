import 'package:hive/hive.dart';

part 'pr_item.g.dart';

@HiveType(typeId: 8)
class PRItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  String quantity;

  @HiveField(4)
  String remarks;

  @HiveField(5)
  Map<String, double> orderedQuantities = {}; // Map of PO number to ordered quantity

  double get totalOrderedQuantity => 
    orderedQuantities.values.fold(0.0, (sum, qty) => sum + qty);

  double get remainingQuantity {
    final totalRequired = double.tryParse(quantity) ?? 0.0;
    return totalRequired - totalOrderedQuantity;
  }

  bool get isFullyOrdered => remainingQuantity <= 0;

  void addOrderedQuantity(String poNo, double quantity) {
    orderedQuantities[poNo] = quantity;
  }

  PRItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.remarks,
    Map<String, double>? orderedQuantities,
  }) {
    this.orderedQuantities = orderedQuantities ?? {};
  }
} 