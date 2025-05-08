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
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';
import '../models/vendor_material_rate.dart';
import '../models/quality_inspection.dart';
import '../models/category_parameter_mapping.dart';

// Flag to track if data has been cleared
bool _hasDataBeenCleared = false;

Future<void> clearIncompatibleData() async {
  if (_hasDataBeenCleared) return; // Skip if already cleared once

  try {
    // Delete boxes that need schema updates
    await Hive.deleteBoxFromDisk('quality_inspections');
    // await Hive.deleteBoxFromDisk('purchase_orders');
    // await Hive.deleteBoxFromDisk('quality_inspections');
    
    _hasDataBeenCleared = true;
  } catch (e) {
    print('Error clearing data: $e');
  }
}

Future<void> initializeHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // Clear incompatible data only on first run or when needed
  await clearIncompatibleData();

  // Register adapters in the correct order
  Hive.registerAdapter(MaterialItemAdapter());
  Hive.registerAdapter(SupplierAdapter());
  Hive.registerAdapter(PurchaseRequestAdapter());
  Hive.registerAdapter(PRItemAdapter());
  Hive.registerAdapter(PurchaseOrderAdapter());
  Hive.registerAdapter(POItemAdapter());
  Hive.registerAdapter(VendorMaterialRateAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(StoreInwardAdapter());
  Hive.registerAdapter(InwardItemAdapter());
  Hive.registerAdapter(QualityInspectionAdapter());
  Hive.registerAdapter(InspectionItemAdapter());
  Hive.registerAdapter(QualityParameterAdapter());
  Hive.registerAdapter(CategoryParameterMappingAdapter());

  // Open boxes
  await Hive.openBox<MaterialItem>('materials');
  await Hive.openBox<Supplier>('suppliers');
  await Hive.openBox<PurchaseRequest>('purchase_requests');
  await Hive.openBox<PurchaseOrder>('purchase_orders');
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<StoreInward>('store_inwards');
  await Hive.openBox<VendorMaterialRate>('vendor_material_rates');
  await Hive.openBox<QualityInspection>('quality_inspections');
  await Hive.openBox<CategoryParameterMapping>('category_parameters');
}
