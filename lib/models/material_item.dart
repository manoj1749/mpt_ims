import 'package:hive/hive.dart';

part 'material_item.g.dart';

@HiveType(typeId: 1)
class MaterialItem extends HiveObject {
  @HiveField(0)
  String slNo;

  @HiveField(1)
  String vendorName;

  @HiveField(2)
  String description;

  @HiveField(3)
  String partNo;

  @HiveField(4)
  String unit;

  @HiveField(5)
  String supplierRate;

  @HiveField(6)
  String seiplRate;

  @HiveField(7)
  String category;

  @HiveField(8)
  String subCategory;

  @HiveField(9)
  String saleRate;

  @HiveField(10)
  String totalReceivedQty;

  @HiveField(11)
  String vendorIssuedQty;

  @HiveField(12)
  String vendorReceivedQty;

  @HiveField(13)
  String boardIssueQty;

  @HiveField(14)
  String avlStock;

  @HiveField(15)
  String avlStockValue;

  @HiveField(16)
  String billingQtyDiff;

  @HiveField(17)
  String totalReceivedCost;

  @HiveField(18)
  String totalBilledCost;

  @HiveField(19)
  String costDiff;

  MaterialItem({
    required this.slNo,
    required this.vendorName,
    required this.description,
    required this.partNo,
    required this.unit,
    required this.supplierRate,
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
  });
}