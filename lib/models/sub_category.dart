import 'package:hive/hive.dart';

part 'sub_category.g.dart';

@HiveType(typeId: 17)
class SubCategory extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String categoryName;

  SubCategory({
    required this.name,
    required this.categoryName,
  });
}
