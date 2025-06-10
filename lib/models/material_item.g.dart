// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialItemAdapter extends TypeAdapter<MaterialItem> {
  @override
  final int typeId = 1;

  @override
  MaterialItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialItem(
      slNo: fields[0] as String,
      description: fields[1] as String,
      partNo: fields[2] as String,
      unit: fields[3] as String,
      category: fields[4] as String,
      subCategory: fields[5] as String,
      storageLocation: fields[6] as String?,
      rackNumber: fields[7] as String?,
      actualWeight: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.slNo)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.partNo)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.subCategory)
      ..writeByte(6)
      ..write(obj.storageLocation)
      ..writeByte(7)
      ..write(obj.rackNumber)
      ..writeByte(8)
      ..write(obj.actualWeight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
