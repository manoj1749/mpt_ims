import 'package:hive/hive.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'dart:math';

part 'material_item.g.dart';

@HiveType(typeId: 1)
class MaterialItem extends HiveObject {
  @HiveField(0)
  String slNo;

  @HiveField(1)
  String description;

  @HiveField(2)
  String partNo;

  @HiveField(3)
  String unit;

  @HiveField(4)
  String category;

  @HiveField(5)
  String subCategory;

  @HiveField(6)
  String? storageLocation;

  @HiveField(7)
  String? rackNumber;

  @HiveField(8)
  String? actualWeight;

  @HiveField(9, defaultValue: <VendorMaterialRate>[])
  List<VendorMaterialRate> vendorRates;

  @HiveField(10, defaultValue: '0')
  String saleRate; // Material's own sale rate

  @HiveField(11)
  String? binNumber; // Storage bin number

  @HiveField(12)
  String? hsnCode; // HSN code for GST

  MaterialItem copy() {
    return MaterialItem(
      slNo: slNo,
      description: description,
      partNo: partNo,
      unit: unit,
      category: category,
      subCategory: subCategory,
      storageLocation: storageLocation ?? '',
      rackNumber: rackNumber ?? '',
      binNumber: binNumber ?? '',
      hsnCode: hsnCode ?? '',
      actualWeight: actualWeight ?? '',
      vendorRates: List<VendorMaterialRate>.from(vendorRates),
      saleRate: saleRate,
    );
  }

  MaterialItem({
    required this.slNo,
    required this.description,
    required this.partNo,
    required this.unit,
    required this.category,
    required this.subCategory,
    this.storageLocation = '',
    this.rackNumber = '',
    this.binNumber = '',
    this.hsnCode = '',
    this.actualWeight = '',
    List<VendorMaterialRate>? vendorRates,
    this.saleRate = '0',
  }) : vendorRates = vendorRates ?? <VendorMaterialRate>[];

  // Helper methods to manage vendor rates
  String getPreferredVendorName() {
    // First check for explicitly set preferred vendor
    final preferredRate = vendorRates.firstWhere(
      (rate) => rate.isPreferred,
      orElse: () => vendorRates.isEmpty
          ? VendorMaterialRate(
              vendorId: '',
              baseRate: '',
              purchaseRate: '',
              lastPurchaseDate: '',
              remarks: '',
            )
          : vendorRates.reduce((a, b) =>
              double.parse(a.purchaseRate.isEmpty ? '999999' : a.purchaseRate) <=
                      double.parse(b.purchaseRate.isEmpty ? '999999' : b.purchaseRate)
                  ? a
                  : b),
    );

    return preferredRate.vendorId;
  }

  String getLowestBaseRate() {
    final rates = getRankedVendors();
    if (rates.isEmpty) return '';
    return rates
        .map((r) => double.tryParse(r.baseRate) ?? double.infinity)
        .reduce(min)
        .toString();
  }

  String getLowestPurchaseRate() {
    final rates = getRankedVendors();
    if (rates.isEmpty) return '';
    return rates
        .map((r) => double.tryParse(r.purchaseRate) ?? double.infinity)
        .reduce(min)
        .toString();
  }

  // Get Base Rate of the preferred vendor
  String getPreferredVendorBaseRate() {
    final rates = getRankedVendors();
    if (rates.isEmpty) return '';
    return rates.first.baseRate;
  }

  // Get Purchase Rate of the preferred vendor
  String getPreferredVendorPurchaseRate() {
    final rates = getRankedVendors();
    if (rates.isEmpty) return '';
    return rates.first.purchaseRate;
  }

  List<VendorMaterialRate> getRankedVendors() {
    final rates = List<VendorMaterialRate>.from(vendorRates);
    // Sort by base rate
    rates.sort((a, b) =>
        (double.tryParse(a.purchaseRate) ?? double.infinity)
            .compareTo(double.tryParse(b.purchaseRate) ?? double.infinity));
    return rates;
  }

  // Helper method to get material's own sale rate as double
  double get saleRateAsDouble {
    return double.tryParse(saleRate) ?? 0.0;
  }

  int getVendorCount() {
    return vendorRates.length;
  }

  // Add a new vendor rate
  void addVendorRate(VendorMaterialRate rate) {
    // Remove existing rate for the same vendor if any
    vendorRates.removeWhere((r) => r.vendorId == rate.vendorId);
    vendorRates.add(rate);
  }

  // Update an existing vendor rate
  void updateVendorRate(VendorMaterialRate updatedRate) {
    final index = vendorRates.indexWhere((r) => r.vendorId == updatedRate.vendorId);
    if (index != -1) {
      vendorRates[index] = updatedRate;
    }
  }

  // Remove a vendor rate
  void removeVendorRate(String vendorId) {
    vendorRates.removeWhere((r) => r.vendorId == vendorId);
  }

  // Get rate for a specific vendor
  VendorMaterialRate? getRateForVendor(String vendorId) {
    try {
      return vendorRates.firstWhere((r) => r.vendorId == vendorId);
    } catch (e) {
      return null;
    }
  }

  // Set preferred vendor
  void setPreferredVendor(String vendorId) {
    for (var rate in vendorRates) {
      rate.isPreferred = (rate.vendorId == vendorId);
    }
  }
}
