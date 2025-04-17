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
      vendorName: fields[1] as String,
      description: fields[2] as String,
      partNo: fields[3] as String,
      unit: fields[4] as String,
      supplierRate: fields[5] as String,
      seiplRate: fields[6] as String,
      category: fields[7] as String,
      subCategory: fields[8] as String,
      saleRate: fields[9] as String,
      totalReceivedQty: fields[10] as String,
      vendorIssuedQty: fields[11] as String,
      vendorReceivedQty: fields[12] as String,
      boardIssueQty: fields[13] as String,
      avlStock: fields[14] as String,
      avlStockValue: fields[15] as String,
      billingQtyDiff: fields[16] as String,
      totalReceivedCost: fields[17] as String,
      totalBilledCost: fields[18] as String,
      costDiff: fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialItem obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.slNo)
      ..writeByte(1)
      ..write(obj.vendorName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.partNo)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.supplierRate)
      ..writeByte(6)
      ..write(obj.seiplRate)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.subCategory)
      ..writeByte(9)
      ..write(obj.saleRate)
      ..writeByte(10)
      ..write(obj.totalReceivedQty)
      ..writeByte(11)
      ..write(obj.vendorIssuedQty)
      ..writeByte(12)
      ..write(obj.vendorReceivedQty)
      ..writeByte(13)
      ..write(obj.boardIssueQty)
      ..writeByte(14)
      ..write(obj.avlStock)
      ..writeByte(15)
      ..write(obj.avlStockValue)
      ..writeByte(16)
      ..write(obj.billingQtyDiff)
      ..writeByte(17)
      ..write(obj.totalReceivedCost)
      ..writeByte(18)
      ..write(obj.totalBilledCost)
      ..writeByte(19)
      ..write(obj.costDiff);
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
