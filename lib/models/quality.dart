import 'package:hive/hive.dart';

part 'quality.g.dart';

@HiveType(typeId: 18)
class Quality extends HiveObject {
  @HiveField(0)
  String name;

  Quality({required this.name});
}
