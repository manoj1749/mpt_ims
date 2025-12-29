// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_terms.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentTermsAdapter extends TypeAdapter<PaymentTerms> {
  @override
  final int typeId = 52;

  @override
  PaymentTerms read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentTerms(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentTerms obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTermsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
