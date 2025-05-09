// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_order_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleOrderItemAdapter extends TypeAdapter<SaleOrderItem> {
  @override
  final int typeId = 17;

  @override
  SaleOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleOrderItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SaleOrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
