// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SupplierAdapter extends TypeAdapter<Supplier> {
  @override
  final int typeId = 0;

  @override
  Supplier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Supplier(
      name: fields[0] as String,
      contact: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      vendorCode: fields[4] as String,
      address1: fields[5] as String,
      address2: fields[6] as String,
      address3: fields[7] as String,
      address4: fields[8] as String,
      state: fields[9] as String,
      stateCode: fields[10] as String,
      paymentTerms: fields[11] as String,
      pan: fields[12] as String,
      gstNo: fields[13] as String,
      igst: fields[14] as String,
      cgst: fields[15] as String,
      sgst: fields[16] as String,
      totalGst: fields[17] as String,
      bank: fields[18] as String,
      branch: fields[19] as String,
      account: fields[20] as String,
      ifsc: fields[21] as String,
      email1: fields[22] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Supplier obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.contact)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.vendorCode)
      ..writeByte(5)
      ..write(obj.address1)
      ..writeByte(6)
      ..write(obj.address2)
      ..writeByte(7)
      ..write(obj.address3)
      ..writeByte(8)
      ..write(obj.address4)
      ..writeByte(9)
      ..write(obj.state)
      ..writeByte(10)
      ..write(obj.stateCode)
      ..writeByte(11)
      ..write(obj.paymentTerms)
      ..writeByte(12)
      ..write(obj.pan)
      ..writeByte(13)
      ..write(obj.gstNo)
      ..writeByte(14)
      ..write(obj.igst)
      ..writeByte(15)
      ..write(obj.cgst)
      ..writeByte(16)
      ..write(obj.sgst)
      ..writeByte(17)
      ..write(obj.totalGst)
      ..writeByte(18)
      ..write(obj.bank)
      ..writeByte(19)
      ..write(obj.branch)
      ..writeByte(20)
      ..write(obj.account)
      ..writeByte(21)
      ..write(obj.ifsc)
      ..writeByte(22)
      ..write(obj.email1);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
