import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/employee.dart';
import 'base_provider.dart';

final employeeBoxProvider = Provider<Box<Employee>>((ref) {
  throw UnimplementedError();
});

final employeeListProvider =
    StateNotifierProvider<EmployeeNotifier, List<Employee>>(
  (ref) => EmployeeNotifier(ref.read(employeeBoxProvider)),
);

class EmployeeNotifier extends BaseProvider<Employee> {
  EmployeeNotifier(Box<Employee> box) : super(box, 'employees');

  @override
  Map<String, dynamic> modelToMap(Employee employee) {
    return {
      'name': employee.name,
      'employeeCode': employee.employeeCode,
      'aadhaarNumber': employee.aadhaarNumber,
      'esiNumber': employee.esiNumber,
      'pfNumber': employee.pfNumber,
      'accountNumber': employee.accountNumber,
      'ifscCode': employee.ifscCode,
      'bankName': employee.bankName,
      'branch': employee.branch,
      'perDaySalary': employee.perDaySalary,
      'otSalaryPerHour': employee.otSalaryPerHour,
    };
  }

  @override
  Employee mapToModel(Map<String, dynamic> map) {
    return Employee(
      name: map['name'] ?? '',
      employeeCode: map['employeeCode'] ?? '',
      aadhaarNumber: map['aadhaarNumber'] ?? '',
      esiNumber: map['esiNumber'] ?? '',
      pfNumber: map['pfNumber'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      ifscCode: map['ifscCode'] ?? '',
      bankName: map['bankName'] ?? '',
      branch: map['branch'] ?? '',
      perDaySalary: map['perDaySalary'] ?? '',
      otSalaryPerHour: map['otSalaryPerHour'] ?? '',
    );
  }

  @override
  String getModelId(Employee employee) => employee.employeeCode;

  // Map old method names to new base provider methods
  Future<void> loadEmployees() => loadData();
  Future<void> addEmployee(Employee employee) => add(employee);
  Future<void> updateEmployee(Employee employee) => update(employee);
  Future<void> deleteEmployee(Employee employee) => delete(employee);

  // Helper methods
  Employee? getEmployeeByCode(String code) {
    try {
      return state.firstWhere((employee) => employee.employeeCode == code);
    } catch (_) {
      return null;
    }
  }

  Employee? getEmployeeByAadhaar(String aadhaarNumber) {
    try {
      return state
          .firstWhere((employee) => employee.aadhaarNumber == aadhaarNumber);
    } catch (_) {
      return null;
    }
  }

  List<Employee> searchEmployees(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((employee) =>
            employee.name.toLowerCase().contains(lowercaseQuery) ||
            employee.employeeCode.toLowerCase().contains(lowercaseQuery) ||
            employee.aadhaarNumber.toLowerCase().contains(lowercaseQuery) ||
            employee.esiNumber.toLowerCase().contains(lowercaseQuery) ||
            employee.pfNumber.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  double getTotalDailySalary() {
    return state.fold(
        0.0,
        (sum, employee) =>
            sum + (double.tryParse(employee.perDaySalary) ?? 0.0));
  }
}
