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
      vendorId: fields[1] as String,
      baseRate: fields[4] as String,
      lastPurchaseDate: fields[5] as String,
      remarks: fields[6] as String,
      isPreferred: fields[17] == null ? false : fields[17] as bool,
      purchaseRate: fields[18] == null ? '0' : fields[18] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VendorMaterialRate obj) {
    writer
      ..writeByte(6)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(4)
      ..write(obj.baseRate)
      ..writeByte(5)
      ..write(obj.lastPurchaseDate)
      ..writeByte(6)
      ..write(obj.remarks)
      ..writeByte(17)
      ..write(obj.isPreferred)
      ..writeByte(18)
      ..write(obj.purchaseRate);
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
