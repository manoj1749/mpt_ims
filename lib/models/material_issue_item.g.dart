// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_issue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemMRDetailsAdapter extends TypeAdapter<ItemMRDetails> {
  @override
  final int typeId = 33;

  @override
  ItemMRDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemMRDetails(
      mrNo: fields[0] as String,
      jobNo: fields[1] as String,
      quantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ItemMRDetails obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.mrNo)
      ..writeByte(1)
      ..write(obj.jobNo)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemMRDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialIssueItemAdapter extends TypeAdapter<MaterialIssueItem> {
  @override
  final int typeId = 34;

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
      quantity: fields[3] as double,
      mrDetails: (fields[4] as Map?)?.cast<String, ItemMRDetails>(),
      issuedQuantities: (fields[5] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialIssueItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.mrDetails)
      ..writeByte(5)
      ..write(obj.issuedQuantities);
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
