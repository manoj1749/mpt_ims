import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/supplier.dart';
import 'base_provider.dart';

final supplierBoxProvider = Provider<Box<Supplier>>((ref) {
  throw UnimplementedError();
});

final supplierListProvider =
    StateNotifierProvider<SupplierNotifier, List<Supplier>>(
  (ref) => SupplierNotifier(ref.read(supplierBoxProvider)),
);

class SupplierNotifier extends BaseProvider<Supplier> {
  SupplierNotifier(Box<Supplier> box) : super(box, 'suppliers');

  @override
  Map<String, dynamic> modelToMap(Supplier supplier) {
    return {
      'name': supplier.name,
      'contact': supplier.contact,
      'phone': supplier.phone,
      'email': supplier.email,
      'vendorCode': supplier.vendorCode,
      'address1': supplier.address1,
      'address2': supplier.address2,
      'address3': supplier.address3,
      'address4': supplier.address4,
      'state': supplier.state,
      'stateCode': supplier.stateCode,
      'paymentTerms': supplier.paymentTerms,
      'pan': supplier.pan,
      'gstNo': supplier.gstNo,
      'igst': supplier.igst,
      'cgst': supplier.cgst,
      'sgst': supplier.sgst,
      'totalGst': supplier.totalGst,
      'bank': supplier.bank,
      'branch': supplier.branch,
      'account': supplier.account,
      'ifsc': supplier.ifsc,
      'email1': supplier.email1,
      'attachments': supplier.attachments,
    };
  }

  @override
  Supplier mapToModel(Map<String, dynamic> map) {
    return Supplier(
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      vendorCode: map['vendorCode'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'] ?? '',
      address3: map['address3'] ?? '',
      address4: map['address4'] ?? '',
      state: map['state'] ?? '',
      stateCode: map['stateCode'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      pan: map['pan'] ?? '',
      gstNo: map['gstNo'] ?? '',
      igst: map['igst'] ?? '',
      cgst: map['cgst'] ?? '',
      sgst: map['sgst'] ?? '',
      totalGst: map['totalGst'] ?? '',
      bank: map['bank'] ?? '',
      branch: map['branch'] ?? '',
      account: map['account'] ?? '',
      ifsc: map['ifsc'] ?? '',
      email1: map['email1'] ?? '',
      attachments: (map['attachments'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  String getModelId(Supplier supplier) => supplier.vendorCode;

  // Map old method names to new base provider methods
  Future<void> loadSuppliers() => loadData();
  Future<void> addSupplier(Supplier supplier) => add(supplier);
  Future<void> updateSupplier(int key, Supplier supplier) async {
    // Use the base provider's update method which uses the unique identifier
    // This is more reliable than index-based lookup which can become stale
    await update(supplier);
  }

  Future<void> deleteSupplier(Supplier supplier) => delete(supplier);

  // Generate next sequential supplier code
  String generateNextSupplierCode() {
    final suppliers = state;
    int maxNumber = 0;

    // Find the highest existing number in MPTSM-xxxxx format
    for (var supplier in suppliers) {
      final code = supplier.vendorCode;
      if (code.startsWith('MPTSM-') && code.length >= 11) {
        final numberPart = code.substring(6); // Remove "MPTSM-" prefix
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    // Generate next sequential number with leading zeros
    final nextNumber = maxNumber + 1;
    return 'MPTSM-${nextNumber.toString().padLeft(5, '0')}';
  }

  // Helper methods
  Supplier? getSupplierByCode(String code) {
    try {
      return state.firstWhere((supplier) => supplier.vendorCode == code);
    } catch (_) {
      return null;
    }
  }

  List<Supplier> searchSuppliers(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((supplier) =>
            supplier.name.toLowerCase().contains(lowercaseQuery) ||
            supplier.vendorCode.toLowerCase().contains(lowercaseQuery) ||
            supplier.contact.toLowerCase().contains(lowercaseQuery) ||
            supplier.phone.toLowerCase().contains(lowercaseQuery) ||
            supplier.email.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}
