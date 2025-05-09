import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';

final customerBoxProvider = Provider<Box<Customer>>((ref) {
  throw UnimplementedError();
});

final customerListProvider =
    StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier(ref.read(customerBoxProvider));
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final Box<Customer> box;

  CustomerNotifier(this.box) : super(box.values.toList());

  void addCustomer(Customer customer) async {
    await box.add(customer);
    state = box.values.toList();
  }

  void updateCustomer(int index, Customer customer) async {
    await box.putAt(index, customer);
    state = box.values.toList();
  }

  void deleteCustomer(Customer customer) {
    customer.delete();
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
}
