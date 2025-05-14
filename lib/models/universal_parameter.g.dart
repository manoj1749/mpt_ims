// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'universal_parameter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UniversalParameterAdapter extends TypeAdapter<UniversalParameter> {
  @override
  final int typeId = 19;

  @override
  UniversalParameter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UniversalParameter(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UniversalParameter obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalParameterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
