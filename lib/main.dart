import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'db/hive_initializer.dart';
import 'layout/app_scaffold.dart';
import 'models/supplier.dart';
import 'models/material_item.dart';
import 'models/customer.dart';
import 'models/purchase_order.dart';
import 'models/store_inward.dart';
import 'models/purchase_request.dart';
import 'models/vendor_material_rate.dart';
import 'models/quality_inspection.dart';
import 'models/category_parameter_mapping.dart';
import 'models/category.dart';
import 'models/sub_category.dart';
import 'models/quality.dart';
import 'models/employee.dart';
import 'models/sale_order.dart';
import 'models/universal_parameter.dart';
import 'models/stock_maintenance.dart';
import 'provider/supplier_provider.dart';
import 'provider/material_provider.dart';
import 'provider/customer_provider.dart';
import 'provider/purchase_order.dart';
import 'provider/store_inward_provider.dart';
import 'provider/purchase_request_provider.dart';
import 'provider/vendor_material_rate_provider.dart';
import 'provider/quality_inspection_provider.dart';
import 'provider/category_parameter_provider.dart';
import 'provider/category_provider.dart';
import 'provider/sub_category_provider.dart';
import 'provider/quality_provider.dart';
import 'provider/employee_provider.dart';
import 'provider/sale_order_provider.dart';
import 'provider/stock_maintenance_provider.dart';
import 'provider/universal_parameter_provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive first
  await Hive.initFlutter();

  // Then clear incompatible data
  // await clearIncompatibleData();

  // Finally initialize adapters and boxes
  await initializeHive();

  // Get references to boxes for providers
  final supplierBox = Hive.box<Supplier>('suppliers');
  final materialBox = Hive.box<MaterialItem>('materials');
  final purchaseRequestBox = Hive.box<PurchaseRequest>('purchaseRequests');
  final purchaseOrderBox = Hive.box<PurchaseOrder>('purchaseOrders');
  final employeeBox = Hive.box<Employee>('employees');
  final customerBox = Hive.box<Customer>('customers');
  final storeInwardBox = Hive.box<StoreInward>('store_inward');
  final vendorMaterialRateBox = Hive.box<VendorMaterialRate>('vendorMaterialRates');
  final qualityInspectionBox = Hive.box<QualityInspection>('qualityInspections');
  final saleOrderBox = Hive.box<SaleOrder>('saleOrders');
  final categoryParameterBox = Hive.box<CategoryParameterMapping>('categoryParameterMappings');
  final categoryBox = Hive.box<Category>('categories');
  final subCategoryBox = Hive.box<SubCategory>('subCategories');
  final qualityBox = Hive.box<Quality>('qualities');
  final universalParameterBox = Hive.box<UniversalParameter>('universalParameters');
  final stockMaintenanceBox = Hive.box<StockMaintenance>('stock_maintenance');

  final user = FirebaseAuth.instance.currentUser;

  runApp(
    ProviderScope(
      overrides: [
        supplierBoxProvider.overrideWithValue(supplierBox),
        materialBoxProvider.overrideWithValue(materialBox),
        customerBoxProvider.overrideWithValue(customerBox),
        purchaseOrderBoxProvider.overrideWithValue(purchaseOrderBox),
        purchaseRequestBoxProvider.overrideWithValue(purchaseRequestBox),
        prPurchaseOrderBoxProvider.overrideWithValue(purchaseOrderBox),
        storeInwardBoxProvider.overrideWithValue(storeInwardBox),
        vendorMaterialRateBoxProvider.overrideWithValue(vendorMaterialRateBox),
        qualityInspectionBoxProvider.overrideWithValue(qualityInspectionBox),
        saleOrderBoxProvider.overrideWithValue(saleOrderBox),
        categoryParameterBoxProvider.overrideWithValue(categoryParameterBox),
        categoryBoxProvider.overrideWithValue(categoryBox),
        subCategoryBoxProvider.overrideWithValue(subCategoryBox),
        qualityBoxProvider.overrideWithValue(qualityBox),
        universalParameterBoxProvider.overrideWithValue(universalParameterBox),
        employeeBoxProvider.overrideWithValue(employeeBox),
        stockMaintenanceBoxProvider.overrideWithValue(stockMaintenanceBox),
      ],
      child: IMSApp(isLoggedIn: user != null),
    ),
  );
}

class IMSApp extends StatelessWidget {
  final bool isLoggedIn;
  const IMSApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'MPT IMS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: isLoggedIn ? const AppScaffold() : const LoginPage(),
        );
      },
    );
  }
}
