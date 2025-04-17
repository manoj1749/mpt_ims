// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseRequestAdapter extends TypeAdapter<PurchaseRequest> {
  @override
  final int typeId = 2;

  @override
  PurchaseRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseRequest(
      prNo: fields[0] as String,
      date: fields[1] as String,
      materialCode: fields[2] as String,
      materialDescription: fields[3] as String,
      unit: fields[4] as String,
      quantity: fields[5] as String,
      requiredBy: fields[6] as String,
      remarks: fields[7] as String,
    ).._status = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, PurchaseRequest obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.prNo)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.materialCode)
      ..writeByte(3)
      ..write(obj.materialDescription)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.requiredBy)
      ..writeByte(7)
      ..write(obj.remarks)
      ..writeByte(8)
      ..write(obj._status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
