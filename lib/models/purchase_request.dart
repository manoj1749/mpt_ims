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

  String get status => _status ?? 'Draft';

  set status(String value) {
    _status = value;
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
  }) {
    _status = status;
  }
}
