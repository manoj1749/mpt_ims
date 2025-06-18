// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_issue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialIssueItemAdapter extends TypeAdapter<MaterialIssueItem> {
  @override
  final int typeId = 31;

  @override
  MaterialIssueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialIssueItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      issueNo: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialIssueItem obj) {
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
      other is MaterialIssueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialIssueAdapter extends TypeAdapter<MaterialIssue> {
  @override
  final int typeId = 30;

  @override
  MaterialIssue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialIssue(
      issueNo: fields[0] as String,
      date: fields[1] as String,
      issuedBy: fields[2] as String,
      items: (fields[4] as List?)?.cast<MaterialIssueItem>(),
      jobNo: fields[5] as String?,
    ).._status = fields[3] as String?;
  }

  @override
  void write(BinaryWriter writer, MaterialIssue obj) {
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
      other is MaterialIssueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
