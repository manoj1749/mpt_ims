// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'po_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class POItemAdapter extends TypeAdapter<POItem> {
  @override
  final int typeId = 5;

  @override
  POItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return POItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      costPerUnit: fields[4] as String,
      totalCost: fields[5] as String,
      seiplRate: fields[6] as String,
      rateDifference: fields[7] as String,
      totalRateDifference: fields[8] as String,
      marginPerUnit: fields[9] as String,
      totalMargin: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, POItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.costPerUnit)
      ..writeByte(5)
      ..write(obj.totalCost)
      ..writeByte(6)
      ..write(obj.seiplRate)
      ..writeByte(7)
      ..write(obj.rateDifference)
      ..writeByte(8)
      ..write(obj.totalRateDifference)
      ..writeByte(9)
      ..write(obj.marginPerUnit)
      ..writeByte(10)
      ..write(obj.totalMargin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is POItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
