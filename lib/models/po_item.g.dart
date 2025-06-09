// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: avoid_print

part of 'po_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class POItemAdapter extends TypeAdapter<POItem> {
  @override
  final int typeId = 5;

  @override
  POItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle legacy data formats
    Map<String, ItemPRDetails>? prDetails;
    if (fields[9] is double || fields[9] is String) {
      prDetails = {};
    } else {
      try {
        prDetails = POItem.castPRDetails(fields[9]);
      } catch (e) {
        print('Error casting PR details: $e');
        prDetails = {};
      }
    }

    Map<String, Map<String, double>>? receivedQuantities;
    if (fields[10] is double || fields[10] is String) {
      receivedQuantities = {};
    } else {
      try {
        receivedQuantities = POItem.castReceivedQuantities(fields[10]);
      } catch (e) {
        print('Error casting received quantities: $e');
        receivedQuantities = {};
      }
    }

    return POItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      costPerUnit: fields[4] as String,
      totalCost: fields[5] as String,
      saleRate: fields[6] as String,
      marginPerUnit: fields[7] as String,
      totalMargin: fields[8] as String,
      prDetails: prDetails,
      receivedQuantities: receivedQuantities,
    );
  }

  @override
  void write(BinaryWriter writer, POItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.materialDescription)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.costPerUnit)
      ..writeByte(5)
      ..write(obj.totalCost)
      ..writeByte(6)
      ..write(obj.saleRate)
      ..writeByte(7)
      ..write(obj.marginPerUnit)
      ..writeByte(8)
      ..write(obj.totalMargin)
      ..writeByte(9)
      ..write(obj.prDetails)
      ..writeByte(10)
      ..write(obj.receivedQuantities);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is POItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemPRDetailsAdapter extends TypeAdapter<ItemPRDetails> {
  @override
  final int typeId = 24;

  @override
  ItemPRDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemPRDetails(
      prNo: fields[0] as String,
      jobNo: fields[1] as String,
      quantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ItemPRDetails obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.prNo)
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
      other is ItemPRDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
