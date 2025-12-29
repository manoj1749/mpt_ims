import 'package:hive/hive.dart';

@HiveType(typeId: 73)
class ServiceMaster extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String serviceType;

  ServiceMaster({
    required this.name,
    required this.serviceType,
  });
}

class ServiceMasterAdapter extends TypeAdapter<ServiceMaster> {
  @override
  final int typeId = 73;

  @override
  ServiceMaster read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceMaster(
      name: fields[0] as String? ?? '',
      serviceType: fields[1] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ServiceMaster obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.serviceType);
  }
}
