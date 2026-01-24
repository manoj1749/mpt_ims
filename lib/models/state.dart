import 'package:hive/hive.dart';

part 'state.g.dart';

@HiveType(typeId: 50)
class StateModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String stateCode;

  StateModel({
    required this.name,
    required this.stateCode,
  });
}
