// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_classification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryClassificationAdapter
    extends TypeAdapter<InventoryClassification> {
  @override
  final int typeId = 72;

  @override
  InventoryClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryClassification(
      name: fields[0] as String,
      requiresQualityCheck: fields[1] as bool,
      sampleSizeLessThan100: fields[2] as int?,
      sampleSize100To500: fields[3] as int?,
      sampleSizeGreaterThan500: fields[4] as int?,
      hasExpiryDate: fields[5] as bool?,
      hasShelfLife: fields[6] as bool?,
      shelfLifeValue: fields[7] as int?,
      shelfLifeUnit: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryClassification obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.requiresQualityCheck)
      ..writeByte(2)
      ..write(obj.sampleSizeLessThan100)
      ..writeByte(3)
      ..write(obj.sampleSize100To500)
      ..writeByte(4)
      ..write(obj.sampleSizeGreaterThan500)
      ..writeByte(5)
      ..write(obj.hasExpiryDate)
      ..writeByte(6)
      ..write(obj.hasShelfLife)
      ..writeByte(7)
      ..write(obj.shelfLifeValue)
      ..writeByte(8)
      ..write(obj.shelfLifeUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
