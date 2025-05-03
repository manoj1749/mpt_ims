// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quality_inspection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QualityInspectionAdapter extends TypeAdapter<QualityInspection> {
  @override
  final int typeId = 11;

  @override
  QualityInspection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QualityInspection(
      inspectionNo: fields[0] as String,
      inspectionDate: fields[1] as String,
      grnNo: fields[2] as String,
      supplierName: fields[3] as String,
      poNo: fields[4] as String,
      billNo: fields[5] as String,
      billDate: fields[6] as String,
      receivedDate: fields[7] as String,
      grnDate: fields[8] as String,
      inspectedBy: fields[9] as String,
      approvedBy: fields[10] as String,
      remarks: fields[11] as String,
      items: (fields[12] as List).cast<InspectionItem>(),
      status: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QualityInspection obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.inspectionNo)
      ..writeByte(1)
      ..write(obj.inspectionDate)
      ..writeByte(2)
      ..write(obj.grnNo)
      ..writeByte(3)
      ..write(obj.supplierName)
      ..writeByte(4)
      ..write(obj.poNo)
      ..writeByte(5)
      ..write(obj.billNo)
      ..writeByte(6)
      ..write(obj.billDate)
      ..writeByte(7)
      ..write(obj.receivedDate)
      ..writeByte(8)
      ..write(obj.grnDate)
      ..writeByte(9)
      ..write(obj.inspectedBy)
      ..writeByte(10)
      ..write(obj.approvedBy)
      ..writeByte(11)
      ..write(obj.remarks)
      ..writeByte(12)
      ..write(obj.items)
      ..writeByte(13)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityInspectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InspectionItemAdapter extends TypeAdapter<InspectionItem> {
  @override
  final int typeId = 12;

  @override
  InspectionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      category: fields[3] as String,
      receivedQty: fields[4] as double,
      costPerUnit: fields[5] as double,
      totalCost: fields[6] as double,
      sampleSize: fields[7] as double,
      inspectedQty: fields[8] as double,
      acceptedQty: fields[9] as double,
      rejectedQty: fields[10] as double,
      pendingQty: fields[11] as double,
      remarks: fields[12] as String,
      usageDecision: fields[13] as String,
      manufacturingDate: fields[14] as String,
      expiryDate: fields[15] as String,
      parameters: (fields[16] as List).cast<QualityParameter>(),
    );
  }

  @override
  void write(BinaryWriter writer, InspectionItem obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.receivedQty)
      ..writeByte(5)
      ..write(obj.costPerUnit)
      ..writeByte(6)
      ..write(obj.totalCost)
      ..writeByte(7)
      ..write(obj.sampleSize)
      ..writeByte(8)
      ..write(obj.inspectedQty)
      ..writeByte(9)
      ..write(obj.acceptedQty)
      ..writeByte(10)
      ..write(obj.rejectedQty)
      ..writeByte(11)
      ..write(obj.pendingQty)
      ..writeByte(12)
      ..write(obj.remarks)
      ..writeByte(13)
      ..write(obj.usageDecision)
      ..writeByte(14)
      ..write(obj.manufacturingDate)
      ..writeByte(15)
      ..write(obj.expiryDate)
      ..writeByte(16)
      ..write(obj.parameters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QualityParameterAdapter extends TypeAdapter<QualityParameter> {
  @override
  final int typeId = 13;

  @override
  QualityParameter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QualityParameter(
      parameter: fields[0] as String,
      specification: fields[1] as String,
      observation: fields[2] as String,
      isAcceptable: fields[3] as bool,
      remarks: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QualityParameter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.parameter)
      ..writeByte(1)
      ..write(obj.specification)
      ..writeByte(2)
      ..write(obj.observation)
      ..writeByte(3)
      ..write(obj.isAcceptable)
      ..writeByte(4)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityParameterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
