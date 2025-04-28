import 'package:hive/hive.dart';

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
  String seiplRate;

  @HiveField(5)
  String category;

  @HiveField(6)
  String subCategory;

  @HiveField(7)
  String saleRate;

  @HiveField(8)
  String totalReceivedQty;

  @HiveField(9)
  String vendorIssuedQty;

  @HiveField(10)
  String vendorReceivedQty;

  @HiveField(11)
  String boardIssueQty;

  @HiveField(12)
  String avlStock;

  @HiveField(13)
  String avlStockValue;

  @HiveField(14)
  String billingQtyDiff;

  @HiveField(15)
  String totalReceivedCost;

  @HiveField(16)
  String totalBilledCost;

  @HiveField(17)
  String costDiff;

  @HiveField(18)
  Map<String, VendorRate> vendorRates; // Map of vendor name to their rate info

  // Get the preferred vendor (one with lowest rate)
  String get preferredVendorName {
    if (vendorRates.isEmpty) return '';
    return vendorRates.entries
        .reduce((a, b) => 
          double.parse(a.value.rate) <= double.parse(b.value.rate) ? a : b)
        .key;
  }

  // Get all vendors sorted by rate
  List<MapEntry<String, VendorRate>> get rankedVendors {
    return vendorRates.entries.toList()
      ..sort((a, b) => 
          double.parse(a.value.rate).compareTo(double.parse(b.value.rate)));
  }

  // Get the lowest rate
  String get lowestRate {
    if (vendorRates.isEmpty) return '';
    return rankedVendors.first.value.rate;
  }

  MaterialItem copy() {
    Map<String, VendorRate> copiedRates = {};
    vendorRates.forEach((key, value) {
      copiedRates[key] = VendorRate(
        rate: value.rate,
        lastPurchaseDate: value.lastPurchaseDate,
        remarks: value.remarks,
      );
    });

    return MaterialItem(
      slNo: slNo,
      description: description,
      partNo: partNo,
      unit: unit,
      seiplRate: seiplRate,
      category: category,
      subCategory: subCategory,
      saleRate: saleRate,
      totalReceivedQty: totalReceivedQty,
      vendorIssuedQty: vendorIssuedQty,
      vendorReceivedQty: vendorReceivedQty,
      boardIssueQty: boardIssueQty,
      avlStock: avlStock,
      avlStockValue: avlStockValue,
      billingQtyDiff: billingQtyDiff,
      totalReceivedCost: totalReceivedCost,
      totalBilledCost: totalBilledCost,
      costDiff: costDiff,
      vendorRates: copiedRates,
    );
  }

  MaterialItem({
    required this.slNo,
    required this.description,
    required this.partNo,
    required this.unit,
    required this.seiplRate,
    required this.category,
    required this.subCategory,
    required this.saleRate,
    required this.totalReceivedQty,
    required this.vendorIssuedQty,
    required this.vendorReceivedQty,
    required this.boardIssueQty,
    required this.avlStock,
    required this.avlStockValue,
    required this.billingQtyDiff,
    required this.totalReceivedCost,
    required this.totalBilledCost,
    required this.costDiff,
    Map<String, VendorRate>? vendorRates,
  }) : vendorRates = vendorRates ?? {};
}

@HiveType(typeId: 11)
class VendorRate {
  @HiveField(0)
  String rate;

  @HiveField(1)
  String lastPurchaseDate;

  @HiveField(2)
  String remarks;

  VendorRate({
    required this.rate,
    required this.lastPurchaseDate,
    required this.remarks,
  });
}
