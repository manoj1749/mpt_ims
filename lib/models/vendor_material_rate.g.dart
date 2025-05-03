// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_material_rate.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VendorMaterialRateAdapter extends TypeAdapter<VendorMaterialRate> {
  @override
  final int typeId = 10;

  @override
  VendorMaterialRate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorMaterialRate(
      materialId: fields[0] as String,
      vendorId: fields[1] as String,
      supplierRate: fields[2] as String,
      seiplRate: fields[3] as String,
      saleRate: fields[4] as String,
      lastPurchaseDate: fields[5] as String,
      remarks: fields[6] as String,
      totalReceivedQty: fields[7] as String,
      issuedQty: fields[8] as String,
      receivedQty: fields[9] as String,
      avlStock: fields[10] as String,
      avlStockValue: fields[11] as String,
      billingQtyDiff: fields[12] as String,
      totalReceivedCost: fields[13] as String,
      totalBilledCost: fields[14] as String,
      costDiff: fields[15] as String,
      inspectionStock: fields[16] == null ? '0' : fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VendorMaterialRate obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.materialId)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.supplierRate)
      ..writeByte(3)
      ..write(obj.seiplRate)
      ..writeByte(4)
      ..write(obj.saleRate)
      ..writeByte(5)
      ..write(obj.lastPurchaseDate)
      ..writeByte(6)
      ..write(obj.remarks)
      ..writeByte(7)
      ..write(obj.totalReceivedQty)
      ..writeByte(8)
      ..write(obj.issuedQty)
      ..writeByte(9)
      ..write(obj.receivedQty)
      ..writeByte(10)
      ..write(obj.avlStock)
      ..writeByte(11)
      ..write(obj.avlStockValue)
      ..writeByte(12)
      ..write(obj.billingQtyDiff)
      ..writeByte(13)
      ..write(obj.totalReceivedCost)
      ..writeByte(14)
      ..write(obj.totalBilledCost)
      ..writeByte(15)
      ..write(obj.costDiff)
      ..writeByte(16)
      ..write(obj.inspectionStock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorMaterialRateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
