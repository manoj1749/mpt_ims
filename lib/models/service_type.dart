import 'package:hive/hive.dart';

@HiveType(typeId: 75)
class ServiceType extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String serviceName;

  ServiceType({
    required this.name,
    required this.serviceName,
  });
}

class ServiceTypeAdapter extends TypeAdapter<ServiceType> {
  @override
  final int typeId = 75;

  @override
  ServiceType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceType(
      name: fields[0] as String? ?? '',
      serviceName: fields[1] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ServiceType obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.serviceName);
  }
}
