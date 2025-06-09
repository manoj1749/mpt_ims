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
  // Register adapters first
  Hive.registerAdapter(SupplierAdapter());
  Hive.registerAdapter(MaterialItemAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(PurchaseOrderAdapter());
  Hive.registerAdapter(POItemAdapter());
  Hive.registerAdapter(StoreInwardAdapter());
  Hive.registerAdapter(InwardItemAdapter());
  Hive.registerAdapter(PurchaseRequestAdapter());
  Hive.registerAdapter(PRItemAdapter());
  Hive.registerAdapter(VendorMaterialRateAdapter());
  Hive.registerAdapter(QualityInspectionAdapter());
  Hive.registerAdapter(InspectionItemAdapter());
  Hive.registerAdapter(QualityParameterAdapter());
  Hive.registerAdapter(InspectionPOQuantityAdapter());
  Hive.registerAdapter(CategoryParameterMappingAdapter());
  Hive.registerAdapter(SaleOrderAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SubCategoryAdapter());
  Hive.registerAdapter(QualityAdapter());
  Hive.registerAdapter(UniversalParameterAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(InspectionQuantityStatusAdapter());
  Hive.registerAdapter(ItemPRDetailsAdapter());

  // Then open boxes
  await Future.wait([
    Hive.openBox<Supplier>('suppliers'),
    Hive.openBox<MaterialItem>('materials'),
    Hive.openBox<Customer>('customers'),
    Hive.openBox<PurchaseOrder>('purchaseOrders'),
    Hive.openBox<StoreInward>('storeInwards'),
    Hive.openBox<PurchaseRequest>('purchaseRequests'),
    Hive.openBox<VendorMaterialRate>('vendorMaterialRates'),
    Hive.openBox<QualityInspection>('qualityInspections'),
    Hive.openBox<CategoryParameterMapping>('categoryParameterMappings'),
    Hive.openBox<SaleOrder>('saleOrders'),
    Hive.openBox<Category>('categories'),
    Hive.openBox<SubCategory>('subCategories'),
    Hive.openBox<Quality>('qualities'),
    Hive.openBox<UniversalParameter>('universalParameters'),
    Hive.openBox<Employee>('employees'),
  ]);
}

Future<void> clearIncompatibleData() async {
  try {
    // Delete all boxes
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

    // Create and initialize schema version box
    final box = await Hive.openBox('schemaVersion');
    await box.put('version', 12);
  } catch (e) {
    print('Error clearing incompatible data: $e');
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
