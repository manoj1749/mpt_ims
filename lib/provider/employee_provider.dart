import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/employee.dart';

final employeeBoxProvider = Provider<Box<Employee>>((ref) {
  throw UnimplementedError();
});

final employeeListProvider =
    StateNotifierProvider<EmployeeNotifier, List<Employee>>((ref) {
  return EmployeeNotifier(ref.read(employeeBoxProvider));
});

class EmployeeNotifier extends StateNotifier<List<Employee>> {
  final Box<Employee> _box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  EmployeeNotifier(this._box) : super([]) {
    // Load employees when initialized
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      print('Loading employees from Firestore...');
      final querySnapshot = await _firestore.collection('employees').get();
      print('Found ${querySnapshot.docs.length} employees in Firestore');

      // Clear existing employees from Hive
      await _box.clear();

      // Add new employees to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final employee = _employeeFromMap(data);
        await _box.add(employee);
      }

      // Update state
      if (mounted) {
        state = _box.values.toList();
      }
      print('Successfully loaded employees');
    } catch (e) {
      print('Error loading employees: $e');
      rethrow;
    }
  }

  Future<void> addEmployee(Employee employee) async {
    try {
      print('Adding employee: ${employee.name}');

      // Add to Firestore first
      final docRef = _firestore.collection('employees').doc();
      final data = _employeeToMap(employee);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await _box.add(employee);

      // Update state
      if (mounted) {
        state = _box.values.toList();
      }
      print('Employee added successfully');
    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  Future<void> updateEmployee(Employee updatedEmployee) async {
    try {
      print('Updating employee: ${updatedEmployee.name}');

      // Find and update in Firestore first
      final querySnapshot = await _firestore
          .collection('employees')
          .where('employeeCode', isEqualTo: updatedEmployee.employeeCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        final data = _employeeToMap(updatedEmployee);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);
      } else {
        // If not found, create new document
        final docRef = _firestore.collection('employees').doc();
        final data = _employeeToMap(updatedEmployee);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.set(data);
      }

      // Find the index of the employee to update
      final index = _box.values.toList().indexWhere(
            (emp) => emp.employeeCode == updatedEmployee.employeeCode,
          );

      if (index != -1) {
        // Get the key at the found index
        final key = _box.keyAt(index);
        // Update the employee at that key
        await _box.put(key, updatedEmployee);
      } else {
        // If not found, add as new
        await _box.add(updatedEmployee);
      }

      // Update state
      if (mounted) {
        state = _box.values.toList();
      }
      print('Employee updated successfully');
    } catch (e) {
      print('Error updating employee: $e');
      rethrow;
    }
  }

  Future<void> deleteEmployee(Employee employee) async {
    try {
      print('Deleting employee: ${employee.name}');

      // Find and delete from Firestore first
      final querySnapshot = await _firestore
          .collection('employees')
          .where('employeeCode', isEqualTo: employee.employeeCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      // Then delete from Hive
      await employee.delete();

      // Update state
      if (mounted) {
        state = _box.values.toList();
      }
      print('Employee deleted successfully');
    } catch (e) {
      print('Error deleting employee: $e');
      rethrow;
    }
  }

  // Public alias for loadEmployees to maintain consistency with other providers
  Future<void> refresh() async {
    await loadEmployees();
  }

  // Helper method to convert Employee to Map
  Map<String, dynamic> _employeeToMap(Employee employee) {
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

  // Helper method to convert Map to Employee
  Employee _employeeFromMap(Map<String, dynamic> map) {
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
}
