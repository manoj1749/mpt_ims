// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_parameter_mapping.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryParameterMappingAdapter
    extends TypeAdapter<CategoryParameterMapping> {
  @override
  final int typeId = 15;

  @override
  CategoryParameterMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryParameterMapping(
      category: fields[0] as String,
      parameters: (fields[1] as List).cast<String>(),
      requiresExpiryDate: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryParameterMapping obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.parameters)
      ..writeByte(2)
      ..write(obj.requiresExpiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryParameterMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
