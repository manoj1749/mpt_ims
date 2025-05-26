import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 16)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool requiresQualityCheck;

  Category({
    required this.name,
    this.requiresQualityCheck = true, // Default to true for existing data
  });
}
