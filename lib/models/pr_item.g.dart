// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pr_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PRItemAdapter extends TypeAdapter<PRItem> {
  @override
  final int typeId = 8;

  @override
  PRItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PRItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      prNo: fields[6] as String,
      orderedQuantities: (fields[5] as Map?)?.cast<String, double>(),
    ).._totalReceivedQuantityStr = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, PRItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.orderedQuantities)
      ..writeByte(6)
      ..write(obj.prNo)
      ..writeByte(7)
      ..write(obj._totalReceivedQuantityStr);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PRItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
