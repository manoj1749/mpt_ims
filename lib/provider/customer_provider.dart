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
}
