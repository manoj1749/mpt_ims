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

Future<void> clearIncompatibleData() async {
  try {
    // Delete the materials box completely to avoid type casting issues
    await Hive.deleteBoxFromDisk('materials');
    // Delete the purchase_orders box due to POItem type changes
    await Hive.deleteBoxFromDisk('purchase_orders');
  } catch (e) {
    print('Error clearing data: $e');
  }
}

Future<void> initializeHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // Clear incompatible data first
  // await clearIncompatibleData();

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

  // Open boxes
  await Hive.openBox<MaterialItem>('materials');
  await Hive.openBox<Supplier>('suppliers');
  await Hive.openBox<PurchaseRequest>('purchase_requests');
  await Hive.openBox<PurchaseOrder>('purchase_orders');
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<StoreInward>('store_inwards');
  await Hive.openBox<VendorMaterialRate>('vendor_material_rates');
}
