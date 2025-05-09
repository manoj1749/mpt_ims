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
import '../models/sale_order.dart';
import '../models/sale_order_item.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(MaterialItemAdapter());
  Hive.registerAdapter(POItemAdapter());
  Hive.registerAdapter(PurchaseOrderAdapter());
  Hive.registerAdapter(PurchaseRequestAdapter());
  Hive.registerAdapter(PRItemAdapter());
  Hive.registerAdapter(StoreInwardAdapter());
  Hive.registerAdapter(InwardItemAdapter());
  Hive.registerAdapter(SupplierAdapter());
  Hive.registerAdapter(VendorMaterialRateAdapter());
  Hive.registerAdapter(QualityInspectionAdapter());
  Hive.registerAdapter(CategoryParameterMappingAdapter());
  Hive.registerAdapter(SaleOrderAdapter());
  Hive.registerAdapter(SaleOrderItemAdapter());
}

Future<void> clearIncompatibleData() async {
  try {
    // Get the schema version
    final box = await Hive.openBox('schemaVersion');
    final currentVersion = box.get('version') ?? 0;

    // If schema version is less than required, clear data
    if (currentVersion < 2) {
      // Clear all boxes except quality inspections
      await Future.wait([
        Hive.deleteBoxFromDisk('customers'),
        Hive.deleteBoxFromDisk('employees'),
        Hive.deleteBoxFromDisk('materials'),
        Hive.deleteBoxFromDisk('purchaseOrders'),
        Hive.deleteBoxFromDisk('purchaseRequests'),
        Hive.deleteBoxFromDisk('storeInwards'),
        Hive.deleteBoxFromDisk('suppliers'),
        Hive.deleteBoxFromDisk('vendorMaterialRates'),
        Hive.deleteBoxFromDisk('categoryParameterMappings'),
        Hive.deleteBoxFromDisk('saleOrders'),
      ]);

      // Update schema version
      await box.put('version', 2);
    }
  } catch (e) {
    print('Error clearing incompatible data: $e');
  }
}
