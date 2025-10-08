import 'package:hive/hive.dart';
import 'package:mpt_ims/models/increment_history.dart';

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

  @HiveField(22)
  String degreeCourse;

  @HiveField(23)
  String institution;

  @HiveField(24)
  String completionYear;

  @HiveField(25)
  String gradeOrGPA;

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

  @HiveField(11)
  String permanentAddress;

  @HiveField(12)
  String temporaryAddress;

  @HiveField(13)
  String email;

  @HiveField(14)
  String phoneNumber;

  @HiveField(15)
  String dateOfJoining;

  @HiveField(16)
  String lastIncrementDate;

  @HiveField(17)
  String dateOfResignation;

  @HiveField(18)
  String bloodGroup;

  @HiveField(26)
  String emergencyContactName;

  @HiveField(27)
  String emergencyContactPhone;

  @HiveField(28)
  String emergencyContactAddress;

  @HiveField(29)
  String emergencyContactRelation;

  @HiveField(30)
  String rejoinedDate;
  
  @HiveField(31)
  bool isRejoined;

  @HiveField(32)
  String department;

  @HiveField(33)
  String jobRole;

  @HiveField(34)
  List<IncrementHistory> incrementHistory;

  Employee({
    required this.name,
    required this.employeeCode,
    required this.aadhaarNumber,
    required this.esiNumber,
    required this.pfNumber,
    required this.accountNumber,
    this.degreeCourse = '',
    this.institution = '',
    this.completionYear = '',
    this.gradeOrGPA = '',
    required this.ifscCode,
    required this.bankName,
    required this.branch,
    required this.perDaySalary,
    required this.otSalaryPerHour,
    this.permanentAddress = '',
    this.temporaryAddress = '',
    this.email = '',
    this.phoneNumber = '',
    this.dateOfJoining = '',
    this.lastIncrementDate = '',
    this.dateOfResignation = '',
    this.bloodGroup = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactAddress = '',
    this.emergencyContactRelation = '',
    this.rejoinedDate = '',
    this.isRejoined = false,
    this.department = '',
    this.jobRole = '',
    this.incrementHistory = const [],
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
    String? permanentAddress,
    String? temporaryAddress,
    String? email,
  String? phoneNumber,
  String? dateOfJoining,
  String? lastIncrementDate,
  String? dateOfResignation,
  String? bloodGroup,
  String? emergencyContactName,
  String? emergencyContactPhone,
  String? emergencyContactAddress,
  String? emergencyContactRelation,
  String? rejoinedDate,
  bool? isRejoined,
  String? department,
  String? jobRole,
  List<IncrementHistory>? incrementHistory,
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
      permanentAddress: permanentAddress ?? this.permanentAddress,
      temporaryAddress: temporaryAddress ?? this.temporaryAddress,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      lastIncrementDate: lastIncrementDate ?? this.lastIncrementDate,
      dateOfResignation: dateOfResignation ?? this.dateOfResignation,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactAddress: emergencyContactAddress ?? this.emergencyContactAddress,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      rejoinedDate: rejoinedDate ?? this.rejoinedDate,
      isRejoined: isRejoined ?? this.isRejoined,
      department: department ?? this.department,
      jobRole: jobRole ?? this.jobRole,
      incrementHistory: incrementHistory ?? this.incrementHistory,
    );
  }
}
