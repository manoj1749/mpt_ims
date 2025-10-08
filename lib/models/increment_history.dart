import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class IncrementHistory {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double previousSalary;

  @HiveField(2)
  final double newSalary;

  @HiveField(3)
  final String? notes;

  const IncrementHistory({
    required this.date,
    required this.previousSalary,
    required this.newSalary,
    this.notes,
  });
}

class IncrementHistoryAdapter extends TypeAdapter<IncrementHistory> {
  @override
  final int typeId = 10;

  @override
  IncrementHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return IncrementHistory(
      date: fields[0] as DateTime,
      previousSalary: (fields[1] as num).toDouble(),
      newSalary: (fields[2] as num).toDouble(),
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, IncrementHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.previousSalary)
      ..writeByte(2)
      ..write(obj.newSalary)
      ..writeByte(3)
      ..write(obj.notes);
  }
}
