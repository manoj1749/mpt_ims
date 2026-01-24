// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gst.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GSTModelAdapter extends TypeAdapter<GSTModel> {
  @override
  final int typeId = 51;

  @override
  GSTModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTModel(
      gstCategory: fields[0] as String,
      gstRate: fields[1] as String,
      cgst: fields[2] as String,
      sgst: fields[3] as String,
      igst: fields[4] as String,
      description: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GSTModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.gstCategory)
      ..writeByte(1)
      ..write(obj.gstRate)
      ..writeByte(2)
      ..write(obj.cgst)
      ..writeByte(3)
      ..write(obj.sgst)
      ..writeByte(4)
      ..write(obj.igst)
      ..writeByte(5)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
