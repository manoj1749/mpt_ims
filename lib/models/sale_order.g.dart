// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleOrderAdapter extends TypeAdapter<SaleOrder> {
  @override
  final int typeId = 14;

  @override
  SaleOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleOrder(
      orderNo: fields[0] as String,
      orderDate: fields[1] as String,
      customerName: fields[2] as String,
      boardNo: fields[3] as String,
      jobStartDate: fields[4] as String,
      targetDate: fields[5] as String,
      endDate: fields[6] as String?,
      jobNo: fields[7] as String,
      planningStartDate: fields[8] as String?,
      planningEndDate: fields[9] as String?,
      actualStartDate: fields[10] as String?,
      customerRequirementDate: fields[11] as String?,
      customerCommitmentDate: fields[12] as String?,
      actualCustomerDeliveryDate: fields[13] as String?,
      jobStatus: fields[14] as String?,
      jobNotes: fields[15] as String?,
      isCustomerFreeIssueAvailable: fields[16] as bool?,
      customerPoNo: fields[17] as String?,
      customerPoDate: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleOrder obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.orderNo)
      ..writeByte(1)
      ..write(obj.orderDate)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.boardNo)
      ..writeByte(4)
      ..write(obj.jobStartDate)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.jobNo)
      ..writeByte(8)
      ..write(obj.planningStartDate)
      ..writeByte(9)
      ..write(obj.planningEndDate)
      ..writeByte(10)
      ..write(obj.actualStartDate)
      ..writeByte(11)
      ..write(obj.customerRequirementDate)
      ..writeByte(12)
      ..write(obj.customerCommitmentDate)
      ..writeByte(13)
      ..write(obj.actualCustomerDeliveryDate)
      ..writeByte(14)
      ..write(obj.jobStatus)
      ..writeByte(15)
      ..write(obj.jobNotes)
      ..writeByte(16)
      ..write(obj.isCustomerFreeIssueAvailable)
      ..writeByte(17)
      ..write(obj.customerPoNo)
      ..writeByte(18)
      ..write(obj.customerPoDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
