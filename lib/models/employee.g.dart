// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 3;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Employee(
      name: fields[0] as String,
      employeeCode: fields[1] as String,
      aadhaarNumber: fields[2] as String,
      esiNumber: fields[3] as String,
      pfNumber: fields[4] as String,
      accountNumber: fields[5] as String,
      ifscCode: fields[6] as String,
      bankName: fields[7] as String,
      branch: fields[8] as String,
      perDaySalary: fields[9] as String,
      otSalaryPerHour: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.employeeCode)
      ..writeByte(2)
      ..write(obj.aadhaarNumber)
      ..writeByte(3)
      ..write(obj.esiNumber)
      ..writeByte(4)
      ..write(obj.pfNumber)
      ..writeByte(5)
      ..write(obj.accountNumber)
      ..writeByte(6)
      ..write(obj.ifscCode)
      ..writeByte(7)
      ..write(obj.bankName)
      ..writeByte(8)
      ..write(obj.branch)
      ..writeByte(9)
      ..write(obj.perDaySalary)
      ..writeByte(10)
      ..write(obj.otSalaryPerHour);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
