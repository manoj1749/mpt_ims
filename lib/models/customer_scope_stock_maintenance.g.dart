// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_scope_stock_maintenance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerScopeStockMaintenanceAdapter
    extends TypeAdapter<CustomerScopeStockMaintenance> {
  @override
  final int typeId = 36;

  @override
  CustomerScopeStockMaintenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerScopeStockMaintenance(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      storageLocation: fields[3] as String,
      rackNumber: fields[4] as String,
      customerName: fields[9] as String,
      customerId: fields[10] as String,
      currentStock: fields[5] as double,
      stockUnderInspection: fields[6] as double,
      grnDetails: (fields[7] as Map?)?.cast<String, CustomerScopeGRNDetails>(),
      jobDetails: (fields[8] as Map?)?.cast<String, CustomerScopeJobDetails>(),
      totalStockValue: fields[11] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerScopeStockMaintenance obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.storageLocation)
      ..writeByte(4)
      ..write(obj.rackNumber)
      ..writeByte(5)
      ..write(obj.currentStock)
      ..writeByte(6)
      ..write(obj.stockUnderInspection)
      ..writeByte(7)
      ..write(obj.grnDetails)
      ..writeByte(8)
      ..write(obj.jobDetails)
      ..writeByte(9)
      ..write(obj.customerName)
      ..writeByte(10)
      ..write(obj.customerId)
      ..writeByte(11)
      ..write(obj.totalStockValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerScopeStockMaintenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomerScopeGRNDetailsAdapter
    extends TypeAdapter<CustomerScopeGRNDetails> {
  @override
  final int typeId = 37;

  @override
  CustomerScopeGRNDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerScopeGRNDetails(
      grnNo: fields[0] as String,
      grnDate: fields[1] as String,
      receivedQuantity: fields[2] as double,
      acceptedQuantity: fields[3] as double,
      rejectedQuantity: fields[4] as double,
      rate: fields[5] as double,
      issuedQuantity: fields[6] as double,
      issuedQuantities: (fields[7] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, CustomerScopeGRNDetails obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.grnNo)
      ..writeByte(1)
      ..write(obj.grnDate)
      ..writeByte(2)
      ..write(obj.receivedQuantity)
      ..writeByte(3)
      ..write(obj.acceptedQuantity)
      ..writeByte(4)
      ..write(obj.rejectedQuantity)
      ..writeByte(5)
      ..write(obj.rate)
      ..writeByte(6)
      ..write(obj.issuedQuantity)
      ..writeByte(7)
      ..write(obj.issuedQuantities);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerScopeGRNDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomerScopeJobDetailsAdapter
    extends TypeAdapter<CustomerScopeJobDetails> {
  @override
  final int typeId = 38;

  @override
  CustomerScopeJobDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerScopeJobDetails(
      jobNo: fields[0] as String,
      allocatedQuantity: fields[1] as double,
      consumedQuantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerScopeJobDetails obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.jobNo)
      ..writeByte(1)
      ..write(obj.allocatedQuantity)
      ..writeByte(2)
      ..write(obj.consumedQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerScopeJobDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
