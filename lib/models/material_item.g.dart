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
      category: fields[4] as String,
      subCategory: fields[5] as String,
      storageLocation: fields[6] as String?,
      rackNumber: fields[7] as String?,
      binNumber: fields[11] as String?,
      hsnCode: fields[12] as String?,
      actualWeight: fields[8] as String?,
      inventoryClassification: fields[13] == null ? '' : fields[13] as String,
      vendorRates: fields[9] == null
          ? []
          : (fields[9] as List?)?.cast<VendorMaterialRate>(),
      saleRate: fields[10] == null ? '0' : fields[10] as String,
      specifications: (fields[14] as Map?)?.cast<String, String>(),
      rawMaterial: fields[15] == null ? '' : fields[15] as String,
      isPlatingRequired: fields[16] == null ? false : fields[16] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialItem obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.slNo)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.partNo)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.subCategory)
      ..writeByte(6)
      ..write(obj.storageLocation)
      ..writeByte(7)
      ..write(obj.rackNumber)
      ..writeByte(8)
      ..write(obj.actualWeight)
      ..writeByte(9)
      ..write(obj.vendorRates)
      ..writeByte(10)
      ..write(obj.saleRate)
      ..writeByte(11)
      ..write(obj.binNumber)
      ..writeByte(12)
      ..write(obj.hsnCode)
      ..writeByte(13)
      ..write(obj.inventoryClassification)
      ..writeByte(14)
      ..write(obj.specifications)
      ..writeByte(15)
      ..write(obj.rawMaterial)
      ..writeByte(16)
      ..write(obj.isPlatingRequired);
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
