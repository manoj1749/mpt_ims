// ignore_for_file: cast_from_null_always_fails

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/customer.dart';
import 'base_provider.dart';

final customerBoxProvider = Provider<Box<Customer>>((ref) {
  throw UnimplementedError();
});

final customerListProvider =
    StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier(ref.read(customerBoxProvider));
});

class CustomerNotifier extends BaseProvider<Customer> {
  CustomerNotifier(Box<Customer> box) : super(box, 'customers');

  @override
  Map<String, dynamic> modelToMap(Customer customer) {
    return {
      'name': customer.name,
      'customerCode': customer.customerCode,
      'address1': customer.address1,
      'address2': customer.address2,
      'address3': customer.address3,
      'address4': customer.address4,
      'state': customer.state,
      'stateCode': customer.stateCode,
      'pan': customer.pan,
      'gstNo': customer.gstNo,
      'igst': customer.igst,
      'cgst': customer.cgst,
      'sgst': customer.sgst,
      'totalGst': customer.totalGst,
      'contact': customer.contact,
      'phone': customer.phone,
      'email': customer.email,
      'email1': customer.email1,
      'bank': customer.bank,
      'branch': customer.branch,
      'account': customer.account,
      'ifsc': customer.ifsc,
      'paymentTerms': customer.paymentTerms,
      'attachments': customer.attachments,
    };
  }

  @override
  Customer mapToModel(Map<String, dynamic> map) {
    return Customer(
      name: map['name'] ?? '',
      customerCode: map['customerCode'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'] ?? '',
      address3: map['address3'] ?? '',
      address4: map['address4'] ?? '',
      state: map['state'] ?? '',
      stateCode: map['stateCode'] ?? '',
      pan: map['pan'] ?? '',
      gstNo: map['gstNo'] ?? '',
      igst: map['igst'] ?? '',
      cgst: map['cgst'] ?? '',
      sgst: map['sgst'] ?? '',
      totalGst: map['totalGst'] ?? '',
      contact: map['contact'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      email1: map['email1'] ?? '',
      bank: map['bank'] ?? '',
      branch: map['branch'] ?? '',
      account: map['account'] ?? '',
      ifsc: map['ifsc'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      attachments: (map['attachments'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  String getModelId(Customer customer) => customer.customerCode;

  // Get customer by name
  Customer? getCustomerByName(String name) {
    return state.firstWhere(
      (customer) => customer.name == name,
      orElse: () => null as Customer,
    );
  }

  // Generate next sequential customer code
  String generateNextCustomerCode() {
    final customers = state;
    int maxNumber = 0;

    // Find the highest existing number in MPTCM-xxxxx format
    for (var customer in customers) {
      final code = customer.customerCode;
      if (code.startsWith('MPTCM-') && code.length >= 11) {
        final numberPart = code.substring(6); // Remove "MPTCM-" prefix
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    // Generate next sequential number with leading zeros
    final nextNumber = maxNumber + 1;
    return 'MPTCM-${nextNumber.toString().padLeft(5, '0')}';
  }

  // Search customers with custom matcher
  List<Customer> searchCustomers(String query) {
    return search(query, (customer, query) {
      return customer.name.toLowerCase().contains(query) ||
          customer.address1.toLowerCase().contains(query) ||
          customer.address2.toLowerCase().contains(query) ||
          customer.address3.toLowerCase().contains(query) ||
          customer.address4.toLowerCase().contains(query) ||
          customer.contact.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.customerCode.toLowerCase().contains(query) ||
          customer.gstNo.toLowerCase().contains(query);
    });
  }
}
