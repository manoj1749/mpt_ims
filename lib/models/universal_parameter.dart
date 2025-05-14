import 'package:hive/hive.dart';

part 'universal_parameter.g.dart';

@HiveType(typeId: 19)
class UniversalParameter extends HiveObject {
  @HiveField(0)
  String name;

  UniversalParameter({required this.name});
} 