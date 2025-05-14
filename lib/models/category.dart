import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 16)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  Category({required this.name});
}
