// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quality.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QualityAdapter extends TypeAdapter<Quality> {
  @override
  final int typeId = 18;

  @override
  Quality read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quality(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Quality obj) {
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
      other is QualityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
