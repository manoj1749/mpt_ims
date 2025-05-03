import 'package:hive/hive.dart';

part 'store_inward.g.dart';

@HiveType(typeId: 6)
class StoreInward extends HiveObject {
  @HiveField(0)
  String grnNo;

  @HiveField(1)
  String grnDate;

  @HiveField(2)
  String supplierName;

  @HiveField(3)
  String poNo;

  @HiveField(4)
  String poDate;

  @HiveField(5)
  String invoiceNo;

  @HiveField(6)
  String invoiceDate;

  @HiveField(7)
  String invoiceAmount;

  @HiveField(8)
  String receivedBy;

  @HiveField(9)
  String checkedBy;

  @HiveField(10)
  List<InwardItem> items;

  StoreInward({
    required this.grnNo,
    required this.grnDate,
    required this.supplierName,
    required this.poNo,
    required this.poDate,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.invoiceAmount,
    required this.receivedBy,
    required this.checkedBy,
    required this.items,
  });
}

@HiveType(typeId: 7)
class InwardItem {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double orderedQty;

  @HiveField(4)
  double receivedQty;

  @HiveField(5)
  double acceptedQty;

  @HiveField(6)
  double rejectedQty;

  @HiveField(7)
  String costPerUnit;

  InwardItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.orderedQty,
    required this.receivedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.costPerUnit,
  });
}
