// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleOrderAdapter extends TypeAdapter<SaleOrder> {
  @override
  final int typeId = 14;

  @override
  SaleOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleOrder(
      orderNo: fields[0] as String,
      orderDate: fields[1] as String,
      customerName: fields[2] as String,
      boardNo: fields[3] as String,
      jobStartDate: fields[4] as String,
      targetDate: fields[5] as String,
      endDate: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleOrder obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.orderNo)
      ..writeByte(1)
      ..write(obj.orderDate)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.boardNo)
      ..writeByte(4)
      ..write(obj.jobStartDate)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
