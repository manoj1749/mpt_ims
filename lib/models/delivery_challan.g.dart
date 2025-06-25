// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_challan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryChallanItemAdapter extends TypeAdapter<DeliveryChallanItem> {
  @override
  final int typeId = 40;

  @override
  DeliveryChallanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryChallanItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as double,
      jobNo: fields[4] as String?,
      prNo: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryChallanItem obj) {
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
      ..write(obj.jobNo)
      ..writeByte(5)
      ..write(obj.prNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryChallanItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeliveryChallanAdapter extends TypeAdapter<DeliveryChallan> {
  @override
  final int typeId = 41;

  @override
  DeliveryChallan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryChallan(
      dcNo: fields[0] as String,
      dcDate: fields[1] as String,
      vendorName: fields[2] as String,
      vendorEmail: fields[3] as String?,
      vendorGstin: fields[4] as String?,
      items: (fields[5] as List).cast<DeliveryChallanItem>(),
      isReturnable: fields[6] as bool,
      note: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryChallan obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.dcNo)
      ..writeByte(1)
      ..write(obj.dcDate)
      ..writeByte(2)
      ..write(obj.vendorName)
      ..writeByte(3)
      ..write(obj.vendorEmail)
      ..writeByte(4)
      ..write(obj.vendorGstin)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.isReturnable)
      ..writeByte(7)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryChallanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
