import 'package:hive/hive.dart';

part 'vendor_material_rate.g.dart';

@HiveType(typeId: 10)
class VendorMaterialRate extends HiveObject {
  @HiveField(0)
  String materialId; // slNo of the material

  @HiveField(1)
  String vendorId; // id/name of the vendor

  @HiveField(4)
  String saleRate; // Rate at which it's sold

  @HiveField(5)
  String lastPurchaseDate;

  @HiveField(6)
  String remarks;

  @HiveField(7)
  String totalReceivedQty;

  @HiveField(8)
  String issuedQty;

  @HiveField(9)
  String receivedQty;

  @HiveField(10)
  String avlStock;

  @HiveField(11)
  String avlStockValue;

  @HiveField(12)
  String billingQtyDiff; // Difference in billing quantity

  @HiveField(13)
  String totalReceivedCost;

  @HiveField(14)
  String totalBilledCost;

  @HiveField(15)
  String costDiff;

  @HiveField(16, defaultValue: '0')
  String inspectionStock; // Stock under inspection/quality check

  @HiveField(17, defaultValue: false)
  bool isPreferred; // Whether this is the preferred vendor for this material

  VendorMaterialRate({
    required this.materialId,
    required this.vendorId,
    required this.saleRate,
    required this.lastPurchaseDate,
    required this.remarks,
    required this.totalReceivedQty,
    required this.issuedQty,
    required this.receivedQty,
    required this.avlStock,
    required this.avlStockValue,
    required this.billingQtyDiff,
    required this.totalReceivedCost,
    required this.totalBilledCost,
    required this.costDiff,
    this.inspectionStock = '0', // Default to 0 for new records
    this.isPreferred = false, // Default to false for new records
  });

  // Create a unique key for this rate
  String get uniqueKey => "$materialId-$vendorId";

  // Helper methods to calculate values
  double get stockValue {
    final stock = double.tryParse(avlStock) ?? 0;
    final rate = double.tryParse(saleRate) ?? 0;
    return stock * rate;
  }

  double get receivedValue {
    final qty = double.tryParse(totalReceivedQty) ?? 0;
    final rate = double.tryParse(saleRate) ?? 0;
    return qty * rate;
  }

  double get billedValue {
    final qty = double.tryParse(totalReceivedQty) ?? 0;
    final rate = double.tryParse(saleRate) ?? 0;
    return qty * rate;
  }

  // Get inspection stock value
  double get inspectionStockValue {
    final stock = double.tryParse(inspectionStock) ?? 0;
    final rate = double.tryParse(saleRate) ?? 0;
    return stock * rate;
  }

  // Get total stock (available + inspection)
  double get totalStock {
    final available = double.tryParse(avlStock) ?? 0;
    final inspection = double.tryParse(inspectionStock) ?? 0;
    return available + inspection;
  }

  // Create a copy with updated values
  VendorMaterialRate copyWith({
    String? materialId,
    String? vendorId,
    String? saleRate,
    String? lastPurchaseDate,
    String? remarks,
    String? totalReceivedQty,
    String? issuedQty,
    String? receivedQty,
    String? avlStock,
    String? avlStockValue,
    String? billingQtyDiff,
    String? totalReceivedCost,
    String? totalBilledCost,
    String? costDiff,
    String? inspectionStock,
    bool? isPreferred,
  }) {
    return VendorMaterialRate(
      materialId: materialId ?? this.materialId,
      vendorId: vendorId ?? this.vendorId,
      saleRate: saleRate ?? this.saleRate,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      remarks: remarks ?? this.remarks,
      totalReceivedQty: totalReceivedQty ?? this.totalReceivedQty,
      issuedQty: issuedQty ?? this.issuedQty,
      receivedQty: receivedQty ?? this.receivedQty,
      avlStock: avlStock ?? this.avlStock,
      avlStockValue: avlStockValue ?? this.avlStockValue,
      billingQtyDiff: billingQtyDiff ?? this.billingQtyDiff,
      totalReceivedCost: totalReceivedCost ?? this.totalReceivedCost,
      totalBilledCost: totalBilledCost ?? this.totalBilledCost,
      costDiff: costDiff ?? this.costDiff,
      inspectionStock: inspectionStock ?? this.inspectionStock,
      isPreferred: isPreferred ?? this.isPreferred,
    );
  }
}
