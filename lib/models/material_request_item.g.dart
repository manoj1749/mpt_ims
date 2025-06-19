// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_request_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialRequestItemAdapter extends TypeAdapter<MaterialRequestItem> {
  @override
  final int typeId = 31;

  @override
  MaterialRequestItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialRequestItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      issueNo: fields[4] as String,
      issuedQuantities: (fields[5] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialRequestItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.issueNo)
      ..writeByte(5)
      ..write(obj.issuedQuantities);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialRequestItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
