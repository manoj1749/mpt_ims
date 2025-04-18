import 'package:hive/hive.dart';

part 'purchase_request.g.dart';

@HiveType(typeId: 2)
class PurchaseRequest extends HiveObject {
  @HiveField(0)
  String prNo;

  @HiveField(1)
  String date;

  @HiveField(2)
  String materialCode;

  @HiveField(3)
  String materialDescription;

  @HiveField(4)
  String unit;

  @HiveField(5)
  String quantity;

  @HiveField(6)
  String requiredBy;

  @HiveField(7)
  String remarks;

  @HiveField(8)
  String? _status;

  @HiveField(9)
  String supplierName;

  @HiveField(10)
  Map<String, double> orderedQuantities = {}; // Map of PO number to ordered quantity

  String get status => _status ?? 'Draft';

  set status(String value) {
    _status = value;
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
    
    final totalRequired = double.tryParse(this.quantity) ?? 0.0;
    final totalOrdered = totalOrderedQuantity;
    final remaining = totalRequired - totalOrdered;
    
    // Update remarks with order information
    String orderInfo = "\nPO: $poNo - Ordered: $quantity ${this.unit}";
    if (remaining > 0) {
      orderInfo += " (Remaining: $remaining ${this.unit})";
    }
    
    // Append to existing remarks or create new
    remarks = remarks.isEmpty ? orderInfo.trim() : "$remarks$orderInfo";
    
    if (isFullyOrdered) {
      status = 'Completed';
    } else if (totalOrderedQuantity > 0) {
      status = 'Partially Ordered';
    }
    save();
  }

  PurchaseRequest({
    required this.prNo,
    required this.date,
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.requiredBy,
    required this.remarks,
    String? status,
    required this.supplierName,
    Map<String, double>? orderedQuantities,
  }) {
    _status = status;
    this.orderedQuantities = orderedQuantities ?? {};
  }
}
