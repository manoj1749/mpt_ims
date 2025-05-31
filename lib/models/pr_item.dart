// ignore_for_file: use_build_context_synchronously

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

  @HiveField(5)
  Map<String, double> orderedQuantities =
      {}; // Map of PO number to ordered quantity

  @HiveField(6)
  String prNo; // Reference to parent PR number

  @HiveField(7)
  String? _totalReceivedQuantityStr;

  double get totalReceivedQuantity =>
      double.tryParse(_totalReceivedQuantityStr ?? '0.0') ?? 0.0;

  set totalReceivedQuantity(double value) {
    _totalReceivedQuantityStr = value.toString();
  }

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
    required this.prNo,
    Map<String, double>? orderedQuantities,
    double totalReceivedQuantity = 0.0,
  }) {
    this.orderedQuantities = orderedQuantities ?? {};
    this.totalReceivedQuantity = totalReceivedQuantity;
  }

  PRItem copyWith({
    String? materialCode,
    String? materialDescription,
    String? unit,
    String? quantity,
    String? prNo,
    Map<String, double>? orderedQuantities,
    double? totalReceivedQuantity,
  }) {
    return PRItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      prNo: prNo ?? this.prNo,
      orderedQuantities:
          orderedQuantities ?? Map<String, double>.from(this.orderedQuantities),
      totalReceivedQuantity:
          totalReceivedQuantity ?? this.totalReceivedQuantity,
    );
  }
}
