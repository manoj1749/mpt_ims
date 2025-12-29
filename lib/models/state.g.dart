// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StateModelAdapter extends TypeAdapter<StateModel> {
  @override
  final int typeId = 50;

  @override
  StateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StateModel(
      name: fields[0] as String,
      stateCode: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StateModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.stateCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
