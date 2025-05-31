import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';
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
  });

  // Helper methods to work with VendorMaterialRateProvider
  String getPreferredVendorName(WidgetRef ref) {
    final rates = getRankedVendors(ref);
    if (rates.isEmpty) return '';
    return rates.first.vendorId;
  }

  String getLowestRate(WidgetRef ref) {
    final rates = getRankedVendors(ref);
    if (rates.isEmpty) return '';
    return rates
        .map((r) => double.tryParse(r.saleRate) ?? double.infinity)
        .reduce(min)
        .toString();
  }

  // Get Sale Rate of the preferred vendor
  String getPreferredVendorSaleRate(WidgetRef ref) {
    final rates = getRankedVendors(ref);
    if (rates.isEmpty) return '';
    return rates.first.saleRate;
  }

  List<VendorMaterialRate> getRankedVendors(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    // Sort by sale rate
    rates.sort((a, b) =>
        (double.parse(a.saleRate)).compareTo(double.parse(b.saleRate)));
    return rates;
  }

  int getVendorCount(WidgetRef ref) {
    return ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo)
        .length;
  }

  // Get total available stock across all vendors
  String getTotalAvailableStock(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(
        0.0, (sum, rate) => sum + (double.tryParse(rate.avlStock) ?? 0));
    return total.toString();
  }

  // Get total stock value across all vendors
  String getTotalStockValue(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(0.0, (sum, rate) => sum + rate.stockValue);
    return total.toString();
  }

  // Get total received quantity across all vendors
  String getTotalReceivedQty(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(0.0,
        (sum, rate) => sum + (double.tryParse(rate.totalReceivedQty) ?? 0));
    return total.toString();
  }

  // Get total issued quantity across all vendors
  String getTotalIssuedQty(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(
        0.0, (sum, rate) => sum + (double.tryParse(rate.issuedQty) ?? 0));
    return total.toString();
  }

  // Get total received cost across all vendors
  String getTotalReceivedCost(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(0.0,
        (sum, rate) => sum + (double.tryParse(rate.totalReceivedCost) ?? 0));
    return total.toString();
  }

  // Get total billed cost across all vendors
  String getTotalBilledCost(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(
        0.0, (sum, rate) => sum + (double.tryParse(rate.totalBilledCost) ?? 0));
    return total.toString();
  }

  // Get total cost difference across all vendors
  String getTotalCostDiff(WidgetRef ref) {
    final rates = ref
        .watch(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(slNo);
    final total = rates.fold(
        0.0, (sum, rate) => sum + (double.tryParse(rate.costDiff) ?? 0));
    return total.toString();
  }
}
