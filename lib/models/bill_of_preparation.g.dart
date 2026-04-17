// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_of_preparation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillOfPreparationAdapter extends TypeAdapter<BillOfPreparation> {
  @override
  final int typeId = 80;

  @override
  BillOfPreparation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillOfPreparation(
      jobNo: fields[0] as String,
      createdDate: fields[1] as String,
      cktTypes: (fields[2] as List).cast<CktType>(),
      materials: (fields[3] as List).cast<BopMaterial>(),
      finalValue: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BillOfPreparation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.jobNo)
      ..writeByte(1)
      ..write(obj.createdDate)
      ..writeByte(2)
      ..write(obj.cktTypes)
      ..writeByte(3)
      ..write(obj.materials)
      ..writeByte(4)
      ..write(obj.finalValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillOfPreparationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CktTypeAdapter extends TypeAdapter<CktType> {
  @override
  final int typeId = 81;

  @override
  CktType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CktType(
      name: fields[0] as String,
      quantity: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CktType obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CktTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialCktTypeAdapter extends TypeAdapter<MaterialCktType> {
  @override
  final int typeId = 83;

  @override
  MaterialCktType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialCktType(
      cktTypeName: fields[0] as String,
      cktTypeQuantity: fields[1] as double,
      materialQuantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialCktType obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.cktTypeName)
      ..writeByte(1)
      ..write(obj.cktTypeQuantity)
      ..writeByte(2)
      ..write(obj.materialQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialCktTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BopMaterialAdapter extends TypeAdapter<BopMaterial> {
  @override
  final int typeId = 82;

  @override
  BopMaterial read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BopMaterial(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      cktTypes: (fields[2] as List).cast<MaterialCktType>(),
      materialSource:
          fields[3] == null ? 'material_master' : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BopMaterial obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.cktTypes)
      ..writeByte(3)
      ..write(obj.materialSource);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BopMaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
