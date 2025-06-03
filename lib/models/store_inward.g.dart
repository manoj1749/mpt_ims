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

    // Handle old format where prQuantities was stored as double
    final oldPrQuantity = fields[8];
    Map<String, Map<String, double>>? prQuantities;

    if (oldPrQuantity == null) {
      prQuantities = {};
    } else if (oldPrQuantity is double) {
      prQuantities = {};
    } else if (oldPrQuantity is Map) {
      try {
        prQuantities = oldPrQuantity.map((dynamic k, dynamic v) =>
            MapEntry(k as String, (v as Map).cast<String, double>()));
      } catch (e) {
        prQuantities = {};
      }
    } else {
      prQuantities = {};
    }

    // Handle old format where inspectedQuantities was stored as double
    final oldInspectedQty = fields[9];
    Map<String, double>? inspectedQuantities;

    if (oldInspectedQty == null) {
      inspectedQuantities = {};
    } else if (oldInspectedQty is double) {
      inspectedQuantities = {};
    } else if (oldInspectedQty is Map) {
      try {
        inspectedQuantities = oldInspectedQty.cast<String, double>();
      } catch (e) {
        inspectedQuantities = {};
      }
    } else {
      inspectedQuantities = {};
    }

    // Handle old format where prJobNumbers was stored as double
    final oldPrJobNumbers = fields[10];
    Map<String, Map<String, String>>? prJobNumbers;

    if (oldPrJobNumbers == null) {
      prJobNumbers = {};
    } else if (oldPrJobNumbers is double) {
      prJobNumbers = {};
    } else if (oldPrJobNumbers is Map) {
      try {
        prJobNumbers = oldPrJobNumbers.map((dynamic k, dynamic v) =>
            MapEntry(k as String, (v as Map).cast<String, String>()));
      } catch (e) {
        prJobNumbers = {};
      }
    } else {
      prJobNumbers = {};
    }

    return InwardItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      orderedQty: fields[3] as double,
      receivedQty: fields[4] as double,
      acceptedQty: fields[5] as double,
      rejectedQty: fields[6] as double,
      costPerUnit: fields[7] as String,
      prQuantities: prQuantities,
      inspectedQuantities: inspectedQuantities,
      prJobNumbers: prJobNumbers,
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
      ..write(obj.inspectedQuantities)
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
