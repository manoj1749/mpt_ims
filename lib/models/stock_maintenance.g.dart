// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_maintenance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMaintenanceAdapter extends TypeAdapter<StockMaintenance> {
  @override
  final int typeId = 22;

  @override
  StockMaintenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockMaintenance(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      storageLocation: fields[3] as String,
      rackNumber: fields[4] as String,
      currentStock: fields[5] as double,
      stockUnderInspection: fields[6] as double,
      grnDetails: (fields[7] as Map?)?.cast<String, StockGRNDetails>(),
      poDetails: (fields[8] as Map?)?.cast<String, StockPODetails>(),
      prDetails: (fields[9] as Map?)?.cast<String, StockPRDetails>(),
      jobDetails: (fields[10] as Map?)?.cast<String, StockJobDetails>(),
      vendorDetails: (fields[11] as Map?)?.cast<String, StockVendorDetails>(),
      totalStockValue: fields[12] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StockMaintenance obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.poDetails)
      ..writeByte(9)
      ..write(obj.prDetails)
      ..writeByte(10)
      ..write(obj.jobDetails)
      ..writeByte(11)
      ..write(obj.vendorDetails)
      ..writeByte(12)
      ..write(obj.totalStockValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMaintenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockGRNDetailsAdapter extends TypeAdapter<StockGRNDetails> {
  @override
  final int typeId = 25;

  @override
  StockGRNDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockGRNDetails(
      grnNo: fields[0] as String,
      grnDate: fields[1] as String,
      receivedQuantity: fields[2] as double,
      acceptedQuantity: fields[3] as double,
      rejectedQuantity: fields[4] as double,
      vendorId: fields[5] as String,
      rate: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StockGRNDetails obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.vendorId)
      ..writeByte(6)
      ..write(obj.rate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockGRNDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockPODetailsAdapter extends TypeAdapter<StockPODetails> {
  @override
  final int typeId = 26;

  @override
  StockPODetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockPODetails(
      poNo: fields[0] as String,
      poDate: fields[1] as String,
      orderedQuantity: fields[2] as double,
      receivedQuantity: fields[3] as double,
      vendorId: fields[4] as String,
      rate: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StockPODetails obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.poNo)
      ..writeByte(1)
      ..write(obj.poDate)
      ..writeByte(2)
      ..write(obj.orderedQuantity)
      ..writeByte(3)
      ..write(obj.receivedQuantity)
      ..writeByte(4)
      ..write(obj.vendorId)
      ..writeByte(5)
      ..write(obj.rate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockPODetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockPRDetailsAdapter extends TypeAdapter<StockPRDetails> {
  @override
  final int typeId = 27;

  @override
  StockPRDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockPRDetails(
      prNo: fields[0] as String,
      prDate: fields[1] as String,
      requestedQuantity: fields[2] as double,
      orderedQuantity: fields[3] as double,
      receivedQuantity: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StockPRDetails obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.prNo)
      ..writeByte(1)
      ..write(obj.prDate)
      ..writeByte(2)
      ..write(obj.requestedQuantity)
      ..writeByte(3)
      ..write(obj.orderedQuantity)
      ..writeByte(4)
      ..write(obj.receivedQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockPRDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockJobDetailsAdapter extends TypeAdapter<StockJobDetails> {
  @override
  final int typeId = 28;

  @override
  StockJobDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockJobDetails(
      jobNo: fields[0] as String,
      allocatedQuantity: fields[1] as double,
      consumedQuantity: fields[2] as double,
      prNo: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StockJobDetails obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.jobNo)
      ..writeByte(1)
      ..write(obj.allocatedQuantity)
      ..writeByte(2)
      ..write(obj.consumedQuantity)
      ..writeByte(3)
      ..write(obj.prNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockJobDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockVendorDetailsAdapter extends TypeAdapter<StockVendorDetails> {
  @override
  final int typeId = 29;

  @override
  StockVendorDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockVendorDetails(
      vendorId: fields[0] as String,
      vendorName: fields[1] as String,
      quantity: fields[2] as double,
      rate: fields[3] as double,
      lastPurchaseDate: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StockVendorDetails obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.vendorId)
      ..writeByte(1)
      ..write(obj.vendorName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.rate)
      ..writeByte(4)
      ..write(obj.lastPurchaseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockVendorDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
