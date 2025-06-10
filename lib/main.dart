import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:mpt_ims/db/hive_initializer.dart';
import 'package:mpt_ims/layout/app_scaffold.dart';
import 'package:mpt_ims/models/customer.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/purchase_order.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'package:mpt_ims/models/store_inward.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/models/quality_inspection.dart';
import 'package:mpt_ims/models/category_parameter_mapping.dart';
import 'package:mpt_ims/provider/customer_provider.dart';
import 'package:mpt_ims/provider/employee_provider.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/purchase_order.dart';
import 'package:mpt_ims/provider/purchase_request_provider.dart';
import 'package:mpt_ims/provider/store_inward_provider.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/provider/quality_inspection_provider.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';
import 'package:mpt_ims/provider/category_parameter_provider.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/models/category.dart';
import 'package:mpt_ims/models/sub_category.dart';
import 'package:mpt_ims/models/quality.dart';
import 'package:mpt_ims/provider/category_provider.dart';
import 'package:mpt_ims/provider/sub_category_provider.dart';
import 'package:mpt_ims/provider/quality_provider.dart';
import 'package:mpt_ims/provider/universal_parameter_provider.dart';
import 'firebase_options.dart'; // From Firebase setup
import 'pages/login_page.dart'; // We'll create this
import 'package:mpt_ims/models/sale_order.dart';
import 'package:mpt_ims/provider/sale_order_provider.dart';
import 'package:mpt_ims/models/universal_parameter.dart';

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
  final storeInwardBox = Hive.box<StoreInward>('storeInwards');
  final vendorMaterialRateBox =
      Hive.box<VendorMaterialRate>('vendorMaterialRates');
  final qualityInspectionBox =
      Hive.box<QualityInspection>('qualityInspections');
  final saleOrderBox = Hive.box<SaleOrder>('saleOrders');
  final categoryParameterBox =
      Hive.box<CategoryParameterMapping>('categoryParameterMappings');
  final categoryBox = Hive.box<Category>('categories');
  final subCategoryBox = Hive.box<SubCategory>('subCategories');
  final qualityBox = Hive.box<Quality>('qualities');
  final universalParameterBox =
      Hive.box<UniversalParameter>('universalParameters');

  final user = FirebaseAuth.instance.currentUser;

  runApp(
    ProviderScope(
      overrides: [
        supplierBoxProvider.overrideWithValue(supplierBox),
        materialBoxProvider.overrideWithValue(materialBox),
        purchaseRequestBoxProvider.overrideWithValue(purchaseRequestBox),
        purchaseOrderBoxProvider.overrideWithValue(purchaseOrderBox),
        employeeBoxProvider.overrideWithValue(employeeBox),
        customerBoxProvider.overrideWithValue(customerBox),
        storeInwardBoxProvider.overrideWithValue(storeInwardBox),
        vendorMaterialRateBoxProvider.overrideWithValue(vendorMaterialRateBox),
        qualityInspectionBoxProvider.overrideWithValue(qualityInspectionBox),
        saleOrderBoxProvider.overrideWithValue(saleOrderBox),
        categoryParameterBoxProvider.overrideWithValue(categoryParameterBox),
        categoryBoxProvider.overrideWithValue(categoryBox),
        subCategoryBoxProvider.overrideWithValue(subCategoryBox),
        qualityBoxProvider.overrideWithValue(qualityBox),
        universalParameterBoxProvider.overrideWithValue(universalParameterBox),
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
