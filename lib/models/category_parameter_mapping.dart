import 'package:hive/hive.dart';

part 'category_parameter_mapping.g.dart';

@HiveType(typeId: 15)
class CategoryParameterMapping extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  List<String> parameters;

  @HiveField(2)
  bool requiresExpiryDate;

  CategoryParameterMapping({
    required this.category,
    required this.parameters,
    required this.requiresExpiryDate,
  });
}
