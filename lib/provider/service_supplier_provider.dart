import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/supplier.dart';
import 'base_provider.dart';

final serviceSupplierBoxProvider = Provider<Box<Supplier>>((ref) {
  throw UnimplementedError();
});

final serviceSupplierListProvider =
    StateNotifierProvider<ServiceSupplierNotifier, List<Supplier>>(
  (ref) => ServiceSupplierNotifier(ref.read(serviceSupplierBoxProvider)),
);

class ServiceSupplierNotifier extends BaseProvider<Supplier> {
  ServiceSupplierNotifier(Box<Supplier> box) : super(box, 'service_suppliers');

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

  Future<void> loadServiceSuppliers() => loadData();
  Future<void> addServiceSupplier(Supplier supplier) => add(supplier);
  Future<void> updateServiceSupplier(int key, Supplier supplier) async {
    await update(supplier);
  }

  Future<void> deleteServiceSupplier(Supplier supplier) => delete(supplier);

  String generateNextServiceSupplierCode() {
    final suppliers = state;
    int maxNumber = 0;

    for (var supplier in suppliers) {
      final code = supplier.vendorCode;
      if ((code.startsWith('AISB-') || code.startsWith('SVS-')) &&
          code.length >= 9) {
        final numberPart = code.substring(5);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'AISB-${nextNumber.toString().padLeft(5, '0')}';
  }

  Supplier? getServiceSupplierByCode(String code) {
    try {
      return state.firstWhere((supplier) => supplier.vendorCode == code);
    } catch (_) {
      return null;
    }
  }

  List<Supplier> searchServiceSuppliers(String query) {
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
