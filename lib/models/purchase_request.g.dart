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
      requiredBy: fields[2] as String,
      supplierName: fields[4] as String,
      items: (fields[5] as List?)?.cast<PRItem>(),
      jobNo: fields[6] as String?,
    ).._status = fields[3] as String?;
  }

  @override
  void write(BinaryWriter writer, PurchaseRequest obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.prNo)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.requiredBy)
      ..writeByte(3)
      ..write(obj._status)
      ..writeByte(4)
      ..write(obj.supplierName)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.jobNo);
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
