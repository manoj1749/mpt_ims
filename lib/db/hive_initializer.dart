import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpt_ims/models/customer.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/purchase_order.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'package:mpt_ims/models/pr_item.dart';
import 'package:mpt_ims/models/store_inward.dart';
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';

Future<void> initializeHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  Hive.registerAdapter(SupplierAdapter());
  Hive.registerAdapter(MaterialItemAdapter());
  Hive.registerAdapter(PRItemAdapter());
  Hive.registerAdapter(PurchaseRequestAdapter());
  Hive.registerAdapter(PurchaseOrderAdapter());
  Hive.registerAdapter(POItemAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(StoreInwardAdapter());

  await Hive.openBox<Supplier>('suppliers');
  await Hive.openBox<MaterialItem>('materials');
  await Hive.openBox<PurchaseRequest>('purchase_requests');
  await Hive.openBox<PurchaseOrder>('purchase_orders');
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<StoreInward>('store_inwards');
  // }
}
