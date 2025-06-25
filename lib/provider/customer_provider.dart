// ignore_for_file: cast_from_null_always_fails

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';
import '../services/sync_service.dart';
import 'supplier_provider.dart';  // Import for syncServiceProvider

final customerBoxProvider = Provider<Box<Customer>>((ref) {
  throw UnimplementedError();
});

final customerListProvider =
    StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier(
    ref.read(customerBoxProvider),
    ref.read(syncServiceProvider),
  );
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final Box<Customer> box;
  final SyncService _syncService;

  CustomerNotifier(this.box, this._syncService) : super(box.values.toList());

  Future<void> addCustomer(Customer customer) async {
    await box.add(customer);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> updateCustomer(int index, Customer customer) async {
    await box.putAt(index, customer);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> deleteCustomer(Customer customer) async {
    await customer.delete();
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> refresh() async {
    await _syncFromFirebase();
    state = box.values.toList();
  }

  // Get customer by name
  Customer? getCustomerByName(String name) {
    return state.firstWhere(
      (customer) => customer.name == name,
      orElse: () => null as Customer,
    );
  }

  // Search customers
  List<Customer> searchCustomers(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state.where((customer) {
      return customer.name.toLowerCase().contains(lowercaseQuery) ||
          customer.address1.toLowerCase().contains(lowercaseQuery) ||
          customer.address2.toLowerCase().contains(lowercaseQuery) ||
          customer.address3.toLowerCase().contains(lowercaseQuery) ||
          customer.address4.toLowerCase().contains(lowercaseQuery) ||
          customer.contact.toLowerCase().contains(lowercaseQuery) ||
          customer.phone.toLowerCase().contains(lowercaseQuery) ||
          customer.email.toLowerCase().contains(lowercaseQuery) ||
          customer.customerCode.toLowerCase().contains(lowercaseQuery) ||
          customer.gstNo.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('customers', box);
    } catch (e) {
      print('Error syncing customers to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'customers',
        box,
        _syncService.customerFromMap,
      );
    } catch (e) {
      print('Error syncing customers from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
