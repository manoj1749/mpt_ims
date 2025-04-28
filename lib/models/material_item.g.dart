// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialItemAdapter extends TypeAdapter<MaterialItem> {
  @override
  final int typeId = 1;

  @override
  MaterialItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialItem(
      slNo: fields[0] as String,
      description: fields[1] as String,
      partNo: fields[2] as String,
      unit: fields[3] as String,
      seiplRate: fields[4] as String,
      category: fields[5] as String,
      subCategory: fields[6] as String,
      saleRate: fields[7] as String,
      totalReceivedQty: fields[8] as String,
      vendorIssuedQty: fields[9] as String,
      vendorReceivedQty: fields[10] as String,
      boardIssueQty: fields[11] as String,
      avlStock: fields[12] as String,
      avlStockValue: fields[13] as String,
      billingQtyDiff: fields[14] as String,
      totalReceivedCost: fields[15] as String,
      totalBilledCost: fields[16] as String,
      costDiff: fields[17] as String,
      vendorRates: (fields[18] as Map?)?.cast<String, VendorRate>(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialItem obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.slNo)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.partNo)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.seiplRate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.subCategory)
      ..writeByte(7)
      ..write(obj.saleRate)
      ..writeByte(8)
      ..write(obj.totalReceivedQty)
      ..writeByte(9)
      ..write(obj.vendorIssuedQty)
      ..writeByte(10)
      ..write(obj.vendorReceivedQty)
      ..writeByte(11)
      ..write(obj.boardIssueQty)
      ..writeByte(12)
      ..write(obj.avlStock)
      ..writeByte(13)
      ..write(obj.avlStockValue)
      ..writeByte(14)
      ..write(obj.billingQtyDiff)
      ..writeByte(15)
      ..write(obj.totalReceivedCost)
      ..writeByte(16)
      ..write(obj.totalBilledCost)
      ..writeByte(17)
      ..write(obj.costDiff)
      ..writeByte(18)
      ..write(obj.vendorRates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VendorRateAdapter extends TypeAdapter<VendorRate> {
  @override
  final int typeId = 11;

  @override
  VendorRate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorRate(
      rate: fields[0] as String,
      lastPurchaseDate: fields[1] as String,
      remarks: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VendorRate obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.rate)
      ..writeByte(1)
      ..write(obj.lastPurchaseDate)
      ..writeByte(2)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorRateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
