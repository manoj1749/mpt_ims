// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_inward.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreInwardAdapter extends TypeAdapter<StoreInward> {
  @override
  final int typeId = 6;

  @override
  StoreInward read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreInward(
      grnNo: fields[0] as String,
      grnDate: fields[1] as String,
      supplierName: fields[2] as String,
      poNo: fields[3] as String,
      poDate: fields[4] as String,
      invoiceNo: fields[5] as String,
      invoiceDate: fields[6] as String,
      invoiceAmount: fields[7] as String,
      receivedBy: fields[8] as String,
      checkedBy: fields[9] as String,
      items: (fields[10] as List).cast<InwardItem>(),
    ).._status = fields[11] as String?;
  }

  @override
  void write(BinaryWriter writer, StoreInward obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.grnNo)
      ..writeByte(1)
      ..write(obj.grnDate)
      ..writeByte(2)
      ..write(obj.supplierName)
      ..writeByte(3)
      ..write(obj.poNo)
      ..writeByte(4)
      ..write(obj.poDate)
      ..writeByte(5)
      ..write(obj.invoiceNo)
      ..writeByte(6)
      ..write(obj.invoiceDate)
      ..writeByte(7)
      ..write(obj.invoiceAmount)
      ..writeByte(8)
      ..write(obj.receivedBy)
      ..writeByte(9)
      ..write(obj.checkedBy)
      ..writeByte(10)
      ..write(obj.items)
      ..writeByte(11)
      ..write(obj._status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreInwardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InwardItemAdapter extends TypeAdapter<InwardItem> {
  @override
  final int typeId = 7;

  @override
  InwardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InwardItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      orderedQty: fields[3] as double,
      receivedQty: fields[4] as double,
      acceptedQty: fields[5] as double,
      rejectedQty: fields[6] as double,
      costPerUnit: fields[7] as String,
      prQuantities: (fields[8] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, double>())),
      inspectionStatus:
          (fields[9] as Map?)?.cast<String, InspectionQuantityStatus>(),
      prJobNumbers: (fields[10] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, String>())),
    );
  }

  @override
  void write(BinaryWriter writer, InwardItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.orderedQty)
      ..writeByte(4)
      ..write(obj.receivedQty)
      ..writeByte(5)
      ..write(obj.acceptedQty)
      ..writeByte(6)
      ..write(obj.rejectedQty)
      ..writeByte(7)
      ..write(obj.costPerUnit)
      ..writeByte(8)
      ..write(obj.prQuantities)
      ..writeByte(9)
      ..write(obj.inspectionStatus)
      ..writeByte(10)
      ..write(obj.prJobNumbers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InwardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InspectionQuantityStatusAdapter
    extends TypeAdapter<InspectionQuantityStatus> {
  @override
  final int typeId = 23;

  @override
  InspectionQuantityStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionQuantityStatus(
      inspectedQty: fields[0] as double,
      acceptedQty: fields[1] as double,
      rejectedQty: fields[2] as double,
      status: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionQuantityStatus obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.inspectedQty)
      ..writeByte(1)
      ..write(obj.acceptedQty)
      ..writeByte(2)
      ..write(obj.rejectedQty)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionQuantityStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
