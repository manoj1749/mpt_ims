import 'package:hive/hive.dart';

part 'gst.g.dart';

@HiveType(typeId: 51)
class GSTModel extends HiveObject {
  @HiveField(0)
  String gstCategory;

  @HiveField(1)
  String gstRate;

  @HiveField(2)
  String cgst;

  @HiveField(3)
  String sgst;

  @HiveField(4)
  String igst;

  @HiveField(5)
  String description;

  GSTModel({
    required this.gstCategory,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.description,
  });
}
