import 'package:hive/hive.dart';

part 'material_request.g.dart';

@HiveType(typeId: 31)
class MaterialRequestItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  String quantity;

  @HiveField(4)
  String issueNo;

  MaterialRequestItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.issueNo,
  });
}

@HiveType(typeId: 30)
class MaterialRequest extends HiveObject {
  @HiveField(0)
  String issueNo;

  @HiveField(1)
  String date;

  @HiveField(2)
  String issuedBy;

  @HiveField(3)
  String? _status;

  @HiveField(4)
  List<MaterialRequestItem> items = [];

  @HiveField(5)
  String? jobNo;

  String get status => _status ?? 'Draft';
  set status(String value) => _status = value;

  MaterialRequest({
    required this.issueNo,
    required this.date,
    required this.issuedBy,
    String? status,
    List<MaterialRequestItem>? items,
    this.jobNo,
  }) {
    _status = status;
    if (items != null) {
      this.items = items;
    }
  }
}
