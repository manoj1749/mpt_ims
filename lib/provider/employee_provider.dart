import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpt_ims/models/employee.dart';

final employeeBoxProvider = Provider<Box<Employee>>((ref) {
  throw UnimplementedError();
});

final employeeListProvider =
    StateNotifierProvider<EmployeeNotifier, List<Employee>>((ref) {
  return EmployeeNotifier(ref.read(employeeBoxProvider));
});

class EmployeeNotifier extends StateNotifier<List<Employee>> {
  final Box<Employee> _box;

  EmployeeNotifier(this._box) : super(_box.values.toList());

  void addEmployee(Employee employee) {
    _box.add(employee);
    state = _box.values.toList();
  }

  void updateEmployee(Employee updatedEmployee) {
    // Find the index of the employee to update
    final index = _box.values.toList().indexWhere(
          (emp) => emp.employeeCode == updatedEmployee.employeeCode,
        );

    if (index != -1) {
      // Get the key at the found index
      final key = _box.keyAt(index);
      // Update the employee at that key
      _box.put(key, updatedEmployee);
      state = _box.values.toList();
    }
  }

  void deleteEmployee(Employee employee) {
    employee.delete();
    state = _box.values.toList();
  }
}
