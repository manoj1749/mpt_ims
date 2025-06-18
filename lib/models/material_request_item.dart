import 'package:hive/hive.dart';

part 'material_request_item.g.dart';

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