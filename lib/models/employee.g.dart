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
      degreeCourse: fields[22] as String,
      institution: fields[23] as String,
      completionYear: fields[24] as String,
      gradeOrGPA: fields[25] as String,
      ifscCode: fields[6] as String,
      bankName: fields[7] as String,
      branch: fields[8] as String,
      perDaySalary: fields[9] as String,
      otSalaryPerHour: fields[10] as String,
      permanentAddress: fields[11] as String,
      temporaryAddress: fields[12] as String,
      email: fields[13] as String,
      phoneNumber: fields[14] as String,
      dateOfJoining: fields[15] as String,
      lastIncrementDate: fields[16] as String,
      dateOfResignation: fields[17] as String,
      bloodGroup: fields[18] as String,
      emergencyContactName: fields[26] as String,
      emergencyContactPhone: fields[27] as String,
      emergencyContactAddress: fields[28] as String,
      emergencyContactRelation: fields[29] as String,
      rejoinedDate: fields[30] as String,
      isRejoined: fields[31] as bool,
      department: fields[32] as String,
      jobRole: fields[33] as String,
      incrementHistory: (fields[34] as List).cast<IncrementHistory>(),
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(32)
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
      ..writeByte(22)
      ..write(obj.degreeCourse)
      ..writeByte(23)
      ..write(obj.institution)
      ..writeByte(24)
      ..write(obj.completionYear)
      ..writeByte(25)
      ..write(obj.gradeOrGPA)
      ..writeByte(6)
      ..write(obj.ifscCode)
      ..writeByte(7)
      ..write(obj.bankName)
      ..writeByte(8)
      ..write(obj.branch)
      ..writeByte(9)
      ..write(obj.perDaySalary)
      ..writeByte(10)
      ..write(obj.otSalaryPerHour)
      ..writeByte(11)
      ..write(obj.permanentAddress)
      ..writeByte(12)
      ..write(obj.temporaryAddress)
      ..writeByte(13)
      ..write(obj.email)
      ..writeByte(14)
      ..write(obj.phoneNumber)
      ..writeByte(15)
      ..write(obj.dateOfJoining)
      ..writeByte(16)
      ..write(obj.lastIncrementDate)
      ..writeByte(17)
      ..write(obj.dateOfResignation)
      ..writeByte(18)
      ..write(obj.bloodGroup)
      ..writeByte(26)
      ..write(obj.emergencyContactName)
      ..writeByte(27)
      ..write(obj.emergencyContactPhone)
      ..writeByte(28)
      ..write(obj.emergencyContactAddress)
      ..writeByte(29)
      ..write(obj.emergencyContactRelation)
      ..writeByte(30)
      ..write(obj.rejoinedDate)
      ..writeByte(31)
      ..write(obj.isRejoined)
      ..writeByte(32)
      ..write(obj.department)
      ..writeByte(33)
      ..write(obj.jobRole)
      ..writeByte(34)
      ..write(obj.incrementHistory);
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
