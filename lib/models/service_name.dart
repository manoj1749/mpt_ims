import 'package:hive/hive.dart';

@HiveType(typeId: 74)
class ServiceName extends HiveObject {
  @HiveField(0)
  String name;

  ServiceName({required this.name});
}

class ServiceNameAdapter extends TypeAdapter<ServiceName> {
  @override
  final int typeId = 74;

  @override
  ServiceName read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceName(
      name: fields[0] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ServiceName obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }
}
