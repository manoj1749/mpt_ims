import 'package:hive/hive.dart';

part 'customer_scope_material_issue_master.g.dart';

@HiveType(typeId: 35)
class CustomerScopeMaterialIssueMaster extends HiveObject {
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
  String? binNumber;

  @HiveField(9)
  String? hsnCode;

  @HiveField(10)
  String? actualWeight;

  @HiveField(11, defaultValue: '')
  String inventoryClassification;

  CustomerScopeMaterialIssueMaster copy() {
    return CustomerScopeMaterialIssueMaster(
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
      inventoryClassification: inventoryClassification,
    );
  }

  CustomerScopeMaterialIssueMaster({
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
    this.inventoryClassification = '',
  });
}
