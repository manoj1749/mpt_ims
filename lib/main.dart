// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:mpt_ims/provider/material_request_provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'db/hive_initializer.dart';
import 'layout/app_scaffold.dart';
import 'models/supplier.dart';
import 'models/material_item.dart';
import 'models/customer.dart';
import 'models/purchase_order.dart';
import 'models/store_inward.dart';
import 'models/purchase_request.dart';
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
import 'provider/quality_inspection_provider.dart';
import 'provider/category_parameter_provider.dart';
import 'provider/category_provider.dart';
import 'provider/sub_category_provider.dart';
import 'provider/quality_provider.dart';
import 'provider/employee_provider.dart';
import 'provider/sale_order_provider.dart';
import 'provider/stock_maintenance_provider.dart';
import 'provider/universal_parameter_provider.dart';
import 'provider/material_issue_provider.dart';
import 'provider/state_provider.dart';
import 'provider/gst_provider.dart';
import 'provider/inventory_classification_provider.dart';
import 'provider/customer_scope_material_issue_master_provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'models/material_request.dart';
import 'models/material_issue.dart';
import 'models/delivery_challan.dart';
import 'models/state.dart';
import 'models/gst.dart';
import 'models/inventory_classification.dart';
import 'models/customer_scope_material_issue_master.dart';
import 'models/customer_scope_stock_maintenance.dart';
import 'models/payment_terms.dart';
import 'provider/customer_scope_stock_maintenance_provider.dart';
import 'provider/payment_terms_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/material_rating_rule.dart';
import 'provider/material_rating_rule_provider.dart';
import 'models/service_master.dart';
import 'provider/service_master_provider.dart';
import 'models/service_name.dart';
import 'models/service_type.dart';
import 'provider/service_name_provider.dart';
import 'provider/service_type_provider.dart';
import 'provider/service_supplier_provider.dart';
import 'models/bill_of_preparation.dart';
import 'provider/bill_of_preparation_provider.dart';

Future<void> _setupHiveDirectory() async {
  try {
    // Get the application documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    
    // Create MPT_IMS/Database folder structure
    final mptImsDirectory = Directory('${appDocDir.path}/MPT_IMS');
    final databaseDirectory = Directory('${mptImsDirectory.path}/Database');
    
    // Create directories if they don't exist
    if (!await mptImsDirectory.exists()) {
      await mptImsDirectory.create(recursive: true);
    }
    if (!await databaseDirectory.exists()) {
      await databaseDirectory.create(recursive: true);
    }
    
    // Initialize Hive with custom path
    await Hive.initFlutter(databaseDirectory.path);
    print('Hive initialized at: ${databaseDirectory.path}');
  } catch (e) {
    print('Error setting up Hive directory: $e');
    // Fallback to default initialization
    await Hive.initFlutter();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
    await Hive.initFlutter();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up custom Hive directory structure
    await _setupHiveDirectory();
  }

  // Initialize Hive first
  // await Hive.initFlutter();

  // Then clear incompatible data
  await clearIncompatibleData();

  // Finally initialize adapters and boxes
  await initializeHive();

  // Get references to boxes for providers
  final supplierBox = Hive.box<Supplier>('suppliers');
  final serviceSupplierBox = Hive.box<Supplier>('service_suppliers');
  final materialBox = Hive.box<MaterialItem>('materials');
  final purchaseRequestBox = Hive.box<PurchaseRequest>('purchaseRequests');
  final purchaseOrderBox = Hive.box<PurchaseOrder>('purchaseOrders');
  final employeeBox = Hive.box<Employee>('employees');
  final customerBox = Hive.box<Customer>('customers');
  final storeInwardBox = Hive.box<StoreInward>('store_inwards');
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
  final stockMaintenanceBox = Hive.box<StockMaintenance>('stock_maintenance');
  final materialRequestBox = Hive.box<MaterialRequest>('material_requests');
  final materialIssueBox = Hive.box<MaterialIssue>('material_issues');
  final stateBox = Hive.box<StateModel>('states');
  final gstBox = Hive.box<GSTModel>('gst');
  final inventoryClassificationBox = Hive.box<InventoryClassification>('inventory_classifications');
  final customerScopeMaterialIssueMasterBox = Hive.box<CustomerScopeMaterialIssueMaster>('customer_scope_material_issue_masters');
  final customerScopeStockMaintenanceBox = Hive.box<CustomerScopeStockMaintenance>('customer_scope_stock_maintenance');
  final paymentTermsBox = Hive.box<PaymentTerms>('paymentTerms');
  final materialRatingRuleBox = Hive.box<MaterialRatingRule>('materialRatingRules');
  final serviceMasterBox = Hive.box<ServiceMaster>('serviceMasters');
  final serviceNameBox = Hive.box<ServiceName>('serviceNames');
  final serviceTypeBox = Hive.box<ServiceType>('serviceTypes');
  final billOfPreparationBox = Hive.box<BillOfPreparation>('billOfPreparations');

  final user = FirebaseAuth.instance.currentUser;

  runApp(
    ProviderScope(
      overrides: [
        supplierBoxProvider.overrideWithValue(supplierBox),
        serviceSupplierBoxProvider.overrideWithValue(serviceSupplierBox),
        materialBoxProvider.overrideWithValue(materialBox),
        customerBoxProvider.overrideWithValue(customerBox),
        purchaseOrderBoxProvider.overrideWithValue(purchaseOrderBox),
        purchaseRequestBoxProvider.overrideWithValue(purchaseRequestBox),
        prPurchaseOrderBoxProvider.overrideWithValue(purchaseOrderBox),
        storeInwardBoxProvider.overrideWithValue(storeInwardBox),
        storeInwardMaterialBoxProvider.overrideWithValue(materialBox),
        qualityInspectionBoxProvider.overrideWithValue(qualityInspectionBox),
        saleOrderBoxProvider.overrideWithValue(saleOrderBox),
        categoryParameterBoxProvider.overrideWithValue(categoryParameterBox),
        categoryBoxProvider.overrideWithValue(categoryBox),
        subCategoryBoxProvider.overrideWithValue(subCategoryBox),
        qualityBoxProvider.overrideWithValue(qualityBox),
        universalParameterBoxProvider.overrideWithValue(universalParameterBox),
        employeeBoxProvider.overrideWithValue(employeeBox),
        stockMaintenanceBoxProvider.overrideWithValue(stockMaintenanceBox),
        materialRequestBoxProvider.overrideWithValue(materialRequestBox),
        materialIssueBoxProvider.overrideWithValue(materialIssueBox),
        stateBoxProvider.overrideWithValue(stateBox),
        gstBoxProvider.overrideWithValue(gstBox),
        inventoryClassificationBoxProvider.overrideWithValue(inventoryClassificationBox),
        customerScopeMaterialIssueMasterBoxProvider.overrideWithValue(customerScopeMaterialIssueMasterBox),
        customerScopeStockMaintenanceBoxProvider.overrideWithValue(customerScopeStockMaintenanceBox),
        paymentTermsBoxProvider.overrideWithValue(paymentTermsBox),
        materialRatingRuleBoxProvider.overrideWithValue(materialRatingRuleBox),
        serviceMasterBoxProvider.overrideWithValue(serviceMasterBox),
        serviceNameBoxProvider.overrideWithValue(serviceNameBox),
        serviceTypeBoxProvider.overrideWithValue(serviceTypeBox),
        billOfPreparationBoxProvider.overrideWithValue(billOfPreparationBox),
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
          builder: (context, child) {
            return _GlobalZoomWrapper(child: child ?? const SizedBox.shrink());
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(75, 85, 115, 1),
              brightness: Brightness.dark,
            ),
            textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Color(0xFF9E9E9E),
              selectionHandleColor: Color(0xFFBDBDBD),
              cursorColor: Color(0xFFE0E0E0),
            ),
            scaffoldBackgroundColor: const Color.fromRGBO(75, 85, 115, 1),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(75, 85, 115, 1),
              foregroundColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: isLoggedIn ? const AppScaffold() : const LoginPage(),
        );
      },
    );
  }
}

class _GlobalZoomWrapper extends StatefulWidget {
  final Widget child;
  const _GlobalZoomWrapper({required this.child});

  @override
  State<_GlobalZoomWrapper> createState() => _GlobalZoomWrapperState();
}

class _GlobalZoomWrapperState extends State<_GlobalZoomWrapper> {
  static const _boxName = 'ui_settings';
  static const _zoomKey = 'app_zoom';

  // Excel-ish ranges
  static const double _minZoom = 1.0;
  static const double _maxZoom = 1.75;

  late final Box _box;
  double _zoom = 1.0;
  final ScrollController _hScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _box = Hive.box(_boxName);
    final saved = _box.get(_zoomKey);
    final parsed = saved is num ? saved.toDouble() : 1.0;
    _zoom = parsed.clamp(_minZoom, _maxZoom);
    if (_zoom != parsed) {
      _box.put(_zoomKey, _zoom);
    }
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  void _setZoom(double value) {
    final next = value.clamp(_minZoom, _maxZoom);
    if (next == _zoom) return;
    setState(() => _zoom = next);
    _box.put(_zoomKey, _zoom);
  }

  bool _isCtrlPressed() {
    final keys = RawKeyboard.instance.keysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_isCtrlPressed()) return;

    // On most mice: scroll up => dy < 0
    final dy = event.scrollDelta.dy;
    final step = 0.05;
    if (dy < 0) {
      _setZoom(_zoom + step);
    } else if (dy > 0) {
      _setZoom(_zoom - step);
    }
  }

  @override
  Widget build(BuildContext context) {
    // When zoomed in, the app becomes larger than the viewport.
    // Wrap in 2D scroll views so users can pan (incl. left/right) without clipping.
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final baseW = constraints.maxWidth;
          final baseH = constraints.maxHeight;
          final contentW = baseW * _zoom;

          // Put horizontal scrollbar at the top of the viewport (window frame area)
          // so it doesn't require scrolling to the bottom to access.
          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _hScroll,
                  thumbVisibility: _zoom > 1.0,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentW,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Transform.scale(
                          alignment: Alignment.topLeft,
                          scale: _zoom,
                          child: SizedBox(
                            width: baseW,
                            height: baseH,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
