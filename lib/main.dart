import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpt_ims/db/hive_initializer.dart';
import 'package:mpt_ims/layout/app_scaffold.dart';
import 'package:mpt_ims/models/customer.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/purchase_order.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'package:mpt_ims/models/store_inward.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/provider/customer_provider.dart';
import 'package:mpt_ims/provider/employee_provider.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/purchase_order.dart';
import 'package:mpt_ims/provider/purchase_request_provider.dart';
import 'package:mpt_ims/provider/store_inward_provider.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';

import 'firebase_options.dart'; // From Firebase setup
import 'pages/login_page.dart'; // We'll create this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeHive();
  // Hive.registerAdapter(SupplierAdapter());
  final supplierBox = await Hive.openBox<Supplier>('suppliers');
  final materialBox = await Hive.openBox<MaterialItem>('materials');
  final purchaseRequestBox =
      await Hive.openBox<PurchaseRequest>('purchase_requests');
  final purchaseOrderBox =
      await Hive.openBox<PurchaseOrder>('purchase_orders');
  final employeeBox = await Hive.openBox<Employee>('employees');
  final customerBox = await Hive.openBox<Customer>('customers');
  final storeInwardBox = await Hive.openBox<StoreInward>('store_inwards');

  final user = FirebaseAuth.instance.currentUser;

  runApp(ProviderScope(
    overrides: [
      supplierBoxProvider.overrideWithValue(supplierBox),
      materialBoxProvider.overrideWithValue(materialBox),
      purchaseRequestBoxProvider.overrideWithValue(purchaseRequestBox),
      purchaseOrderBoxProvider.overrideWithValue(purchaseOrderBox),
      employeeBoxProvider.overrideWithValue(employeeBox),
      customerBoxProvider.overrideWithValue(customerBox),
      storeInwardBoxProvider.overrideWithValue(storeInwardBox),
    ],
    child: IMSApp(isLoggedIn: user != null),
  ));
}

class IMSApp extends StatelessWidget {
  final bool isLoggedIn;
  const IMSApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMS Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: isLoggedIn ? const AppScaffold() : const LoginPage(),
    );
  }
}

