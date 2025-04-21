import 'package:hive/hive.dart';

part 'employee.g.dart';

@HiveType(typeId: 3) // Make sure this ID is unique and not used by other models
class Employee extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String employeeCode;

  @HiveField(2)
  String aadhaarNumber;

  @HiveField(3)
  String esiNumber;

  @HiveField(4)
  String pfNumber;

  @HiveField(5)
  String accountNumber;

  @HiveField(6)
  String ifscCode;

  @HiveField(7)
  String bankName;

  @HiveField(8)
  String branch;

  @HiveField(9)
  String perDaySalary;

  @HiveField(10)
  String otSalaryPerHour;

  Employee({
    required this.name,
    required this.employeeCode,
    required this.aadhaarNumber,
    required this.esiNumber,
    required this.pfNumber,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.branch,
    required this.perDaySalary,
    required this.otSalaryPerHour,
  });

  Employee copyWith({
    String? name,
    String? employeeCode,
    String? aadhaarNumber,
    String? esiNumber,
    String? pfNumber,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? branch,
    String? perDaySalary,
    String? otSalaryPerHour,
  }) {
    return Employee(
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      esiNumber: esiNumber ?? this.esiNumber,
      pfNumber: pfNumber ?? this.pfNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      branch: branch ?? this.branch,
      perDaySalary: perDaySalary ?? this.perDaySalary,
      otSalaryPerHour: otSalaryPerHour ?? this.otSalaryPerHour,
    );
  }
} 