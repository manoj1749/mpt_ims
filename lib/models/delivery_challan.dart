import 'package:hive/hive.dart';

part 'delivery_challan.g.dart';

@HiveType(typeId: 40)
class DeliveryChallanItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  String? jobNo; // Optional job number, if not provided uses general stock

  @HiveField(5)
  String? prNo; // Optional PR number if issuing from specific PR

  DeliveryChallanItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    this.jobNo,
    this.prNo,
  });

  DeliveryChallanItem copyWith({
    String? materialCode,
    String? materialDescription,
    String? unit,
    double? quantity,
    String? jobNo,
    String? prNo,
  }) {
    return DeliveryChallanItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      jobNo: jobNo ?? this.jobNo,
      prNo: prNo ?? this.prNo,
    );
  }
}

@HiveType(typeId: 41)
class DeliveryChallan extends HiveObject {
  @HiveField(0)
  String dcNo; // Delivery Challan number

  @HiveField(1)
  String dcDate;

  @HiveField(2)
  String vendorName;

  @HiveField(3)
  String? vendorEmail;

  @HiveField(4)
  String? vendorGstin;

  @HiveField(5)
  List<DeliveryChallanItem> items;

  @HiveField(6)
  bool isReturnable;

  @HiveField(7)
  String? note;

  DeliveryChallan({
    required this.dcNo,
    required this.dcDate,
    required this.vendorName,
    this.vendorEmail,
    this.vendorGstin,
    required this.items,
    required this.isReturnable,
    this.note,
  });

  DeliveryChallan copyWith({
    String? dcNo,
    String? dcDate,
    String? vendorName,
    String? vendorEmail,
    String? vendorGstin,
    List<DeliveryChallanItem>? items,
    bool? isReturnable,
    String? note,
  }) {
    return DeliveryChallan(
      dcNo: dcNo ?? this.dcNo,
      dcDate: dcDate ?? this.dcDate,
      vendorName: vendorName ?? this.vendorName,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorGstin: vendorGstin ?? this.vendorGstin,
      items: items ?? List.from(this.items),
      isReturnable: isReturnable ?? this.isReturnable,
      note: note ?? this.note,
    );
  }
}
