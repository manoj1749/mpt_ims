import 'package:hive/hive.dart';

part 'vendor_material_rate.g.dart';

@HiveType(typeId: 10)
class VendorMaterialRate extends HiveObject {
  @HiveField(1)
  String vendorId; // id/name of the vendor

  @HiveField(4)
  String baseRate; // Base rate from vendor

  @HiveField(5)
  String lastPurchaseDate;

  @HiveField(6)
  String remarks;

  @HiveField(17, defaultValue: false)
  bool isPreferred; // Whether this is the preferred vendor for this material

  @HiveField(18, defaultValue: '0')
  String purchaseRate; // Rate at which it's purchased from vendor

  VendorMaterialRate({
    required this.vendorId,
    required this.baseRate,
    required this.lastPurchaseDate,
    required this.remarks,
    this.isPreferred = false, // Default to false for new records
    required this.purchaseRate, // Default to 0 for new records
  });

  // Create a unique key for this rate (just vendorId since materialId is not stored here anymore)
  String get uniqueKey => vendorId;

  // Helper method to get base rate as double
  double get baseRateAsDouble {
    return double.tryParse(baseRate) ?? 0.0;
  }

  // Helper method to get purchase rate as double
  double get purchaseRateAsDouble {
    return double.tryParse(purchaseRate) ?? 0.0;
  }

  // Create a copy with updated values
  VendorMaterialRate copyWith({
    String? vendorId,
    String? baseRate,
    String? lastPurchaseDate,
    String? remarks,
    bool? isPreferred,
    String? purchaseRate,
  }) {
    return VendorMaterialRate(
      vendorId: vendorId ?? this.vendorId,
      baseRate: baseRate ?? this.baseRate,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      remarks: remarks ?? this.remarks,
      isPreferred: isPreferred ?? this.isPreferred,
      purchaseRate: purchaseRate ?? this.purchaseRate,
    );
  }
}
