// ignore_for_file: avoid_print

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpt_ims/models/customer.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/po_item.dart';
import 'package:mpt_ims/models/purchase_order.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'package:mpt_ims/models/pr_item.dart';
import 'package:mpt_ims/models/store_inward.dart';
import '../models/supplier.dart';
import '../models/vendor_material_rate.dart';
import '../models/quality_inspection.dart';
import '../models/category_parameter_mapping.dart';
import '../models/sale_order.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/quality.dart';
import '../models/universal_parameter.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter();

  // Register adapters in order of their typeIds
  Hive.registerAdapter(CustomerAdapter()); // typeId: 0
  Hive.registerAdapter(EmployeeAdapter()); // typeId: 1
  Hive.registerAdapter(MaterialItemAdapter()); // typeId: 2
  Hive.registerAdapter(POItemAdapter()); // typeId: 3
  Hive.registerAdapter(PurchaseOrderAdapter()); // typeId: 4
  Hive.registerAdapter(PurchaseRequestAdapter()); // typeId: 5
  Hive.registerAdapter(PRItemAdapter()); // typeId: 6
  Hive.registerAdapter(StoreInwardAdapter()); // typeId: 7
  Hive.registerAdapter(SupplierAdapter()); // typeId: 8
  Hive.registerAdapter(VendorMaterialRateAdapter()); // typeId: 9
  Hive.registerAdapter(QualityInspectionAdapter()); // typeId: 10
  Hive.registerAdapter(CategoryParameterMappingAdapter()); // typeId: 11
  Hive.registerAdapter(SaleOrderAdapter()); // typeId: 12
  Hive.registerAdapter(CategoryAdapter()); // typeId: 13
  Hive.registerAdapter(SubCategoryAdapter()); // typeId: 14
  Hive.registerAdapter(QualityAdapter()); // typeId: 15
  Hive.registerAdapter(UniversalParameterAdapter()); // typeId: 16

  // Handle schema migration
  await clearIncompatibleData();

  // Open boxes
  await Future.wait([
    Hive.openBox<Supplier>('suppliers'),
    Hive.openBox<MaterialItem>('materials'),
    Hive.openBox<PurchaseRequest>('purchaseRequests'),
    Hive.openBox<PurchaseOrder>('purchaseOrders'),
    Hive.openBox<Employee>('employees'),
    Hive.openBox<Customer>('customers'),
    Hive.openBox<StoreInward>('storeInwards'),
    Hive.openBox<VendorMaterialRate>('vendorMaterialRates'),
    Hive.openBox<QualityInspection>('qualityInspections'),
    Hive.openBox<SaleOrder>('saleOrders'),
    Hive.openBox<CategoryParameterMapping>('categoryParameterMappings'),
    Hive.openBox<Category>('categories'),
    Hive.openBox<SubCategory>('subCategories'),
    Hive.openBox<Quality>('qualities'),
    Hive.openBox<UniversalParameter>('universal_parameters'),
  ]);
}

Future<void> clearIncompatibleData() async {
  try {
    // Get the schema version
    final box = await Hive.openBox('schemaVersion');
    final currentVersion = box.get('version') ?? 0;

    // If schema version is less than required, clear data
    if (currentVersion < 8) {
      // Increased version for universal parameters
      // Delete all boxes since we've made significant model changes
      await Future.wait([
        Hive.deleteBoxFromDisk('customers'),
        Hive.deleteBoxFromDisk('employees'),
        Hive.deleteBoxFromDisk('materials'),
        Hive.deleteBoxFromDisk('purchaseOrders'),
        Hive.deleteBoxFromDisk('purchaseRequests'),
        Hive.deleteBoxFromDisk('storeInwards'),
        Hive.deleteBoxFromDisk('suppliers'),
        Hive.deleteBoxFromDisk('vendorMaterialRates'),
        Hive.deleteBoxFromDisk('qualityInspections'),
        Hive.deleteBoxFromDisk('categoryParameterMappings'),
        Hive.deleteBoxFromDisk('saleOrders'),
        Hive.deleteBoxFromDisk('categories'),
        Hive.deleteBoxFromDisk('subCategories'),
        Hive.deleteBoxFromDisk('qualities'),
        Hive.deleteBoxFromDisk('universal_parameters'),
      ]);

      // Update schema version
      await box.put('version', 8);
    }
  } catch (e) {
    print('Error clearing incompatible data: $e');
    // If there's an error, try to delete all boxes
    try {
      await Future.wait([
        Hive.deleteBoxFromDisk('customers'),
        Hive.deleteBoxFromDisk('employees'),
        Hive.deleteBoxFromDisk('materials'),
        Hive.deleteBoxFromDisk('purchaseOrders'),
        Hive.deleteBoxFromDisk('purchaseRequests'),
        Hive.deleteBoxFromDisk('storeInwards'),
        Hive.deleteBoxFromDisk('suppliers'),
        Hive.deleteBoxFromDisk('vendorMaterialRates'),
        Hive.deleteBoxFromDisk('qualityInspections'),
        Hive.deleteBoxFromDisk('categoryParameterMappings'),
        Hive.deleteBoxFromDisk('saleOrders'),
        Hive.deleteBoxFromDisk('categories'),
        Hive.deleteBoxFromDisk('subCategories'),
        Hive.deleteBoxFromDisk('qualities'),
        Hive.deleteBoxFromDisk('universal_parameters'),
        Hive.deleteBoxFromDisk('schemaVersion'),
      ]);
    } catch (e) {
      print('Error deleting boxes: $e');
    }
  }
}
