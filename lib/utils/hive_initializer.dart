import 'package:hive_flutter/hive_flutter.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/purchase_request.dart';
import '../models/purchase_order.dart';
import '../models/pr_item.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(SupplierAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(PurchaseRequestAdapter());
    Hive.registerAdapter(PurchaseOrderAdapter());
    Hive.registerAdapter(PRItemAdapter());

    // Open boxes
    await Hive.openBox<Supplier>('suppliers');
    await Hive.openBox<Customer>('customers');
    await Hive.openBox<PurchaseRequest>('purchase_requests');
    await Hive.openBox<PurchaseOrder>('purchase_orders');
  }
} 