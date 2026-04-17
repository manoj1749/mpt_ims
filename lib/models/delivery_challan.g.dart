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
      price: fields[6] == null ? 0.0 : fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryChallanItem obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.prNo)
      ..writeByte(6)
      ..write(obj.price);
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
      dcType: fields[8] == null ? 'regular' : fields[8] as String,
      invoiceNumber: fields[9] == null ? '' : fields[9] as String?,
      invoiceAmount: fields[10] == null ? 0.0 : fields[10] as double?,
      paymentStatus: fields[11] == null ? '' : fields[11] as String?,
      jobOrderNumber: fields[12] == null ? '' : fields[12] as String?,
      inspectionNumber: fields[13] == null ? '' : fields[13] as String?,
      grnNumber: fields[14] == null ? '' : fields[14] as String?,
      rejectionReason: fields[15] == null ? '' : fields[15] as String?,
      debitNoteNumber: fields[16] == null ? '' : fields[16] as String?,
      fromVendor: fields[17] == null ? '' : fields[17] as String?,
      toVendor: fields[18] == null ? '' : fields[18] as String?,
      siteAddress: fields[19] == null ? '' : fields[19] as String?,
      expectedReturnDate: fields[20] == null ? '' : fields[20] as String?,
      returnStatus: fields[21] == null ? '' : fields[21] as String?,
      internalFlow: fields[22] == null ? 'outward' : fields[22] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryChallan obj) {
    writer
      ..writeByte(23)
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
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.dcType)
      ..writeByte(9)
      ..write(obj.invoiceNumber)
      ..writeByte(10)
      ..write(obj.invoiceAmount)
      ..writeByte(11)
      ..write(obj.paymentStatus)
      ..writeByte(12)
      ..write(obj.jobOrderNumber)
      ..writeByte(13)
      ..write(obj.inspectionNumber)
      ..writeByte(14)
      ..write(obj.grnNumber)
      ..writeByte(15)
      ..write(obj.rejectionReason)
      ..writeByte(16)
      ..write(obj.debitNoteNumber)
      ..writeByte(17)
      ..write(obj.fromVendor)
      ..writeByte(18)
      ..write(obj.toVendor)
      ..writeByte(19)
      ..write(obj.siteAddress)
      ..writeByte(20)
      ..write(obj.expectedReturnDate)
      ..writeByte(21)
      ..write(obj.returnStatus)
      ..writeByte(22)
      ..write(obj.internalFlow);
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
