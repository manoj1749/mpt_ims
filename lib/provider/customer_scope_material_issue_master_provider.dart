import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/customer_scope_material_issue_master.dart';
import 'base_provider.dart';

final customerScopeMaterialIssueMasterBoxProvider = Provider<Box<CustomerScopeMaterialIssueMaster>>((ref) {
  return Hive.box<CustomerScopeMaterialIssueMaster>('customer_scope_material_issue_masters');
});

final customerScopeMaterialIssueMasterListProvider =
    StateNotifierProvider<CustomerScopeMaterialIssueMasterNotifier, List<CustomerScopeMaterialIssueMaster>>(
  (ref) => CustomerScopeMaterialIssueMasterNotifier(ref.read(customerScopeMaterialIssueMasterBoxProvider)),
);

class CustomerScopeMaterialIssueMasterNotifier extends BaseProvider<CustomerScopeMaterialIssueMaster> {
  CustomerScopeMaterialIssueMasterNotifier(Box<CustomerScopeMaterialIssueMaster> box) : super(box, 'customer_scope_material_issue_masters');

  @override
  Map<String, dynamic> modelToMap(CustomerScopeMaterialIssueMaster material) {
    return {
      'slNo': material.slNo,
      'description': material.description,
      'partNo': material.partNo,
      'unit': material.unit,
      'category': material.category,
      'subCategory': material.subCategory,
      'storageLocation': material.storageLocation,
      'rackNumber': material.rackNumber,
      'binNumber': material.binNumber,
      'hsnCode': material.hsnCode,
      'actualWeight': material.actualWeight,
      'inventoryClassification': material.inventoryClassification,
    };
  }

  @override
  CustomerScopeMaterialIssueMaster mapToModel(Map<String, dynamic> map) {
    return CustomerScopeMaterialIssueMaster(
      slNo: map['slNo'] ?? '',
      description: map['description'] ?? '',
      partNo: map['partNo'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      storageLocation: map['storageLocation'],
      rackNumber: map['rackNumber'],
      binNumber: map['binNumber'],
      hsnCode: map['hsnCode'],
      actualWeight: map['actualWeight'],
      inventoryClassification: map['inventoryClassification'] ?? '',
    );
  }

  @override
  String getModelId(CustomerScopeMaterialIssueMaster material) => material.partNo;

  // Map old method names to new base provider methods
  Future<void> loadCustomerScopeMaterialIssueMasters() => loadData();
  Future<void> addCustomerScopeMaterialIssueMaster(CustomerScopeMaterialIssueMaster material) => add(material);
  Future<void> updateCustomerScopeMaterialIssueMaster(int index, CustomerScopeMaterialIssueMaster material) async {
    final existingMaterial = box.getAt(index);
    if (existingMaterial != null) {
      await update(material);
    }
  }

  Future<void> deleteCustomerScopeMaterialIssueMaster(CustomerScopeMaterialIssueMaster material) => delete(material);

  // Helper methods
  List<CustomerScopeMaterialIssueMaster> getCustomerScopeMaterialIssueMastersByCategory(String category) {
    return state.where((material) => material.category == category).toList();
  }

  List<CustomerScopeMaterialIssueMaster> getCustomerScopeMaterialIssueMastersBySubCategory(String subCategory) {
    return state
        .where((material) => material.subCategory == subCategory)
        .toList();
  }

  CustomerScopeMaterialIssueMaster? getCustomerScopeMaterialIssueMasterBySlNo(String slNo) {
    try {
      return state.firstWhere((material) => material.slNo == slNo);
    } catch (_) {
      return null;
    }
  }

  List<CustomerScopeMaterialIssueMaster> searchCustomerScopeMaterialIssueMasters(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((material) =>
            material.description.toLowerCase().contains(lowercaseQuery) ||
            material.partNo.toLowerCase().contains(lowercaseQuery) ||
            material.category.toLowerCase().contains(lowercaseQuery) ||
            material.subCategory.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}
