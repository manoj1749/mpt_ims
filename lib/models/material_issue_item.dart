import 'package:hive/hive.dart';

part 'material_issue_item.g.dart';

@HiveType(typeId: 31)
class MaterialIssueItem extends HiveObject {
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

  MaterialIssueItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.issueNo,
  });
} 