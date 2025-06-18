// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialRequestItemAdapter extends TypeAdapter<MaterialRequestItem> {
  @override
  final int typeId = 31;

  @override
  MaterialRequestItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialRequestItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      issueNo: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialRequestItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.issueNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialRequestItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialRequestAdapter extends TypeAdapter<MaterialRequest> {
  @override
  final int typeId = 30;

  @override
  MaterialRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialRequest(
      issueNo: fields[0] as String,
      date: fields[1] as String,
      issuedBy: fields[2] as String,
      items: (fields[4] as List?)?.cast<MaterialRequestItem>(),
      jobNo: fields[5] as String?,
    ).._status = fields[3] as String?;
  }

  @override
  void write(BinaryWriter writer, MaterialRequest obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.issueNo)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.issuedBy)
      ..writeByte(3)
      ..write(obj._status)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.jobNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
