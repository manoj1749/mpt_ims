// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_issue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialIssueAdapter extends TypeAdapter<MaterialIssue> {
  @override
  final int typeId = 32;

  @override
  MaterialIssue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialIssue(
      issueNo: fields[0] as String,
      issueDate: fields[1] as String,
      issuedTo: fields[2] as String,
      items: (fields[3] as List).cast<MaterialIssueItem>(),
    ).._status = fields[4] as String?;
  }

  @override
  void write(BinaryWriter writer, MaterialIssue obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.issueNo)
      ..writeByte(1)
      ..write(obj.issueDate)
      ..writeByte(2)
      ..write(obj.issuedTo)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj._status);
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
