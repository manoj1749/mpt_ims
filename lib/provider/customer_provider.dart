// ignore_for_file: cast_from_null_always_fails

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CustomerNotifier(this.box) : super(box.values.toList()) {
    // Initialize with current values
    state = box.values.toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadCustomers() async {
    try {
      print('Loading customers from Firestore...');
      final querySnapshot = await _firestore.collection('customers').get();
      print('Found ${querySnapshot.docs.length} customers in Firestore');

      // Clear existing customers from Hive
      await box.clear();

      // Add new customers to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final customer = _customerFromMap(data);
        await box.add(customer);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded customers');
    } catch (e) {
      print('Error loading customers: $e');
      rethrow;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      print('Adding customer: ${customer.name}');
      
      // Add to Firestore first
      final docRef = _firestore.collection('customers').doc();
      final data = _customerToMap(customer);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(customer);
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Customer added successfully');
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(int index, Customer customer) async {
    try {
      print('Updating customer: ${customer.name}');

      // Update in Firestore first
      final querySnapshot = await _firestore
          .collection('customers')
          .where('customerCode', isEqualTo: customer.customerCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        final data = _customerToMap(customer);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);
      }

      // Then update in Hive
      await box.putAt(index, customer);
      if (mounted) {
        state = box.values.toList();
      }
      print('Customer updated successfully');
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(Customer customer) async {
    try {
      print('Deleting customer: ${customer.name}');

      // Delete from Firestore first
      final querySnapshot = await _firestore
          .collection('customers')
          .where('customerCode', isEqualTo: customer.customerCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      // Then delete from Hive
      await customer.delete();
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Customer deleted successfully');
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Public alias for loadCustomers to maintain consistency with other providers
  Future<void> refresh() async {
    await loadCustomers();
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

  // Helper method to convert Customer to Map
  Map<String, dynamic> _customerToMap(Customer customer) {
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
    };
  }

  // Helper method to convert Map to Customer
  Customer _customerFromMap(Map<String, dynamic> map) {
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
    );
  }
}
