// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_order_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobOrderRequestAdapter extends TypeAdapter<JobOrderRequest> {
  @override
  final int typeId = 120;

  @override
  JobOrderRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobOrderRequest(
      requestNo: fields[0] as String,
      requestDate: fields[1] as String,
      selectedJobs: (fields[2] as List).cast<String>(),
      materialsByRawMaterial: (fields[3] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      createdDate: fields[4] as DateTime,
      notes: fields[5] as String?,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, JobOrderRequest obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.requestNo)
      ..writeByte(1)
      ..write(obj.requestDate)
      ..writeByte(2)
      ..write(obj.selectedJobs)
      ..writeByte(3)
      ..write(obj.materialsByRawMaterial)
      ..writeByte(4)
      ..write(obj.createdDate)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobOrderRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
