// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseOrderAdapter extends TypeAdapter<PurchaseOrder> {
  @override
  final int typeId = 4;

  @override
  PurchaseOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseOrder(
      poNo: fields[0] as String,
      poDate: fields[1] as String,
      supplierName: fields[2] as String,
      transport: fields[4] as String,
      deliveryRequirements: fields[5] as String,
      items: (fields[6] as List).cast<POItem>(),
      total: fields[7] as double,
      igst: fields[8] as double,
      cgst: fields[9] as double,
      sgst: fields[10] as double,
      grandTotal: fields[11] as double,
      hasAmendments: fields[13] == null ? false : fields[13] as bool?,
      isForeclosed: fields[14] == null ? false : fields[14] as bool,
      foreclosureReason: fields[15] as String?,
      foreclosureDate: fields[16] as String?,
      hasGR: fields[17] == null ? false : fields[17] as bool,
      previousPONo: fields[18] as String?,
      originalPoDate: fields[19] as String?,
      isServiceBill: fields[20] == null ? false : fields[20] as bool,
    ).._status = fields[12] as String?;
  }

  @override
  void write(BinaryWriter writer, PurchaseOrder obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.poNo)
      ..writeByte(1)
      ..write(obj.poDate)
      ..writeByte(2)
      ..write(obj.supplierName)
      ..writeByte(4)
      ..write(obj.transport)
      ..writeByte(5)
      ..write(obj.deliveryRequirements)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.total)
      ..writeByte(8)
      ..write(obj.igst)
      ..writeByte(9)
      ..write(obj.cgst)
      ..writeByte(10)
      ..write(obj.sgst)
      ..writeByte(11)
      ..write(obj.grandTotal)
      ..writeByte(12)
      ..write(obj._status)
      ..writeByte(13)
      ..write(obj.hasAmendments)
      ..writeByte(14)
      ..write(obj.isForeclosed)
      ..writeByte(15)
      ..write(obj.foreclosureReason)
      ..writeByte(16)
      ..write(obj.foreclosureDate)
      ..writeByte(17)
      ..write(obj.hasGR)
      ..writeByte(18)
      ..write(obj.previousPONo)
      ..writeByte(19)
      ..write(obj.originalPoDate)
      ..writeByte(20)
      ..write(obj.isServiceBill);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
