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
      items: (fields[12] as List).cast<InspectionItem>(),
      status: fields[13] as String,
      prNumbers: (fields[14] as Map?)?.cast<String, String>(),
      jobNumbers: (fields[15] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, QualityInspection obj) {
    writer
      ..writeByte(15)
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
      ..writeByte(12)
      ..write(obj.items)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.prNumbers)
      ..writeByte(15)
      ..write(obj.jobNumbers);
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
      usageDecision: fields[13] as String,
      receivedDate: fields[14] as String,
      expirationDate: fields[15] as String,
      parameters: (fields[16] as List).cast<QualityParameter>(),
      isPartialRecheck: fields[17] as bool?,
      conditionalAcceptanceReason: fields[18] as String?,
      conditionalAcceptanceAction: fields[19] as String?,
      conditionalAcceptanceDeadline: fields[20] as String?,
      poQuantities: (fields[21] as Map?)?.cast<String, InspectionPOQuantity>(),
      grnNo: fields[22] as String?,
      grnDate: fields[23] as String?,
      invoiceNo: fields[24] as String?,
      invoiceDate: fields[25] as String?,
      grnDetails: (fields[26] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, String>())),
      grnQuantities:
          (fields[27] as Map?)?.cast<String, InspectionGRNQuantity>(),
      inspectionRemark: fields[28] as String?,
      recheckType: fields[30] as String?,
      conditionalAcceptance: fields[31] as bool?,
    )..capaRequired = fields[29] as bool;
  }

  @override
  void write(BinaryWriter writer, InspectionItem obj) {
    writer
      ..writeByte(31)
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
      ..writeByte(13)
      ..write(obj.usageDecision)
      ..writeByte(14)
      ..write(obj.receivedDate)
      ..writeByte(15)
      ..write(obj.expirationDate)
      ..writeByte(16)
      ..write(obj.parameters)
      ..writeByte(17)
      ..write(obj.isPartialRecheck)
      ..writeByte(18)
      ..write(obj.conditionalAcceptanceReason)
      ..writeByte(19)
      ..write(obj.conditionalAcceptanceAction)
      ..writeByte(20)
      ..write(obj.conditionalAcceptanceDeadline)
      ..writeByte(21)
      ..write(obj.poQuantities)
      ..writeByte(22)
      ..write(obj.grnNo)
      ..writeByte(23)
      ..write(obj.grnDate)
      ..writeByte(24)
      ..write(obj.invoiceNo)
      ..writeByte(25)
      ..write(obj.invoiceDate)
      ..writeByte(26)
      ..write(obj.grnDetails)
      ..writeByte(27)
      ..write(obj.grnQuantities)
      ..writeByte(28)
      ..write(obj.inspectionRemark)
      ..writeByte(29)
      ..write(obj.capaRequired)
      ..writeByte(30)
      ..write(obj.recheckType)
      ..writeByte(31)
      ..write(obj.conditionalAcceptance);
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

class InspectionPOQuantityAdapter extends TypeAdapter<InspectionPOQuantity> {
  @override
  final int typeId = 20;

  @override
  InspectionPOQuantity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionPOQuantity(
      receivedQty: fields[0] as double,
      acceptedQty: fields[1] as double,
      rejectedQty: fields[2] as double,
      usageDecision: fields[3] as String,
      recheckType: fields[4] as String?,
      conditionalAcceptance: fields[5] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionPOQuantity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.receivedQty)
      ..writeByte(1)
      ..write(obj.acceptedQty)
      ..writeByte(2)
      ..write(obj.rejectedQty)
      ..writeByte(3)
      ..write(obj.usageDecision)
      ..writeByte(4)
      ..write(obj.recheckType)
      ..writeByte(5)
      ..write(obj.conditionalAcceptance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionPOQuantityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InspectionGRNQuantityAdapter extends TypeAdapter<InspectionGRNQuantity> {
  @override
  final int typeId = 21;

  @override
  InspectionGRNQuantity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionGRNQuantity(
      receivedQty: fields[0] as double,
      acceptedQty: fields[1] as double,
      rejectedQty: fields[2] as double,
      usageDecision: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionGRNQuantity obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.receivedQty)
      ..writeByte(1)
      ..write(obj.acceptedQty)
      ..writeByte(2)
      ..write(obj.rejectedQty)
      ..writeByte(3)
      ..write(obj.usageDecision);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionGRNQuantityAdapter &&
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
      isAcceptable: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QualityParameter obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.parameter)
      ..writeByte(1)
      ..write(obj.specification)
      ..writeByte(2)
      ..write(obj.isAcceptable);
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
