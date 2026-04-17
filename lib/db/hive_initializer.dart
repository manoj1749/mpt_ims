// ignore_for_file: avoid_print

import 'package:hive/hive.dart';
import 'package:mpt_ims/models/material_request.dart';
import 'package:mpt_ims/models/material_request_item.dart';
import '../models/supplier.dart';
import '../models/material_item.dart';
import '../models/customer.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';
import '../models/store_inward.dart';
import '../models/purchase_request.dart';
import '../models/pr_item.dart';
import '../models/vendor_material_rate.dart';
import '../models/quality_inspection.dart';
import '../models/category_parameter_mapping.dart';
import '../models/sale_order.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/quality.dart';
import '../models/universal_parameter.dart';
import '../models/employee.dart';
import '../models/stock_maintenance.dart';
import '../models/material_issue.dart';
import '../models/material_issue_item.dart';
import '../models/delivery_challan.dart';
import '../models/state.dart';
import '../models/gst.dart';
import '../models/inventory_classification.dart';
import '../models/customer_scope_material_issue_master.dart';
import '../models/customer_scope_stock_maintenance.dart';
import '../models/payment_terms.dart';
import '../models/material_rating_rule.dart';
import '../models/service_master.dart';
import '../models/service_name.dart';
import '../models/service_type.dart';
import '../models/bill_of_preparation.dart';

bool _adaptersRegistered = false;

Future<void> initializeHive() async {
  // Register adapters only once to prevent duplicate registration errors
  if (!_adaptersRegistered) {
    Hive.registerAdapter(SupplierAdapter());
    Hive.registerAdapter(MaterialItemAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(PurchaseOrderAdapter());
    Hive.registerAdapter(POItemAdapter());
    Hive.registerAdapter(AmendmentEntryAdapter());
    Hive.registerAdapter(StoreInwardAdapter());
    Hive.registerAdapter(InwardItemAdapter());
    Hive.registerAdapter(PurchaseRequestAdapter());
    Hive.registerAdapter(PRItemAdapter());
    Hive.registerAdapter(VendorMaterialRateAdapter());
    Hive.registerAdapter(QualityInspectionAdapter());
    Hive.registerAdapter(InspectionItemAdapter());
    Hive.registerAdapter(QualityParameterAdapter());
    Hive.registerAdapter(InspectionPOQuantityAdapter());
    Hive.registerAdapter(InspectionGRNQuantityAdapter());
    Hive.registerAdapter(CategoryParameterMappingAdapter());
    Hive.registerAdapter(SaleOrderAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(SubCategoryAdapter());
    Hive.registerAdapter(QualityAdapter());
    Hive.registerAdapter(UniversalParameterAdapter());
    Hive.registerAdapter(EmployeeAdapter());
    Hive.registerAdapter(InspectionQuantityStatusAdapter());
    Hive.registerAdapter(ItemPRDetailsAdapter());

    // Register stock maintenance adapters
    Hive.registerAdapter(StockMaintenanceAdapter());
    Hive.registerAdapter(StockGRNDetailsAdapter());
    Hive.registerAdapter(StockPODetailsAdapter());
    Hive.registerAdapter(StockPRDetailsAdapter());
    Hive.registerAdapter(StockJobDetailsAdapter());
    Hive.registerAdapter(StockVendorDetailsAdapter());
    Hive.registerAdapter(StockTransferHistoryEntryAdapter());
    Hive.registerAdapter(MaterialRequestAdapter());
    Hive.registerAdapter(MaterialRequestItemAdapter());
    Hive.registerAdapter(MaterialIssueAdapter());
    Hive.registerAdapter(MaterialIssueItemAdapter());
    Hive.registerAdapter(ItemMRDetailsAdapter());

    // Register delivery challan adapters
    Hive.registerAdapter(DeliveryChallanAdapter());
    Hive.registerAdapter(DeliveryChallanItemAdapter());

    // Register state and GST adapters
    Hive.registerAdapter(StateModelAdapter());
    Hive.registerAdapter(GSTModelAdapter());
    Hive.registerAdapter(InventoryClassificationAdapter());
    Hive.registerAdapter(CustomerScopeMaterialIssueMasterAdapter());

    // Register customer scope stock maintenance adapters
    Hive.registerAdapter(CustomerScopeStockMaintenanceAdapter());
    Hive.registerAdapter(CustomerScopeGRNDetailsAdapter());
    Hive.registerAdapter(CustomerScopeJobDetailsAdapter());
    
    // Register payment terms adapter
    Hive.registerAdapter(PaymentTermsAdapter());
    Hive.registerAdapter(RatingRangeAdapter());
    Hive.registerAdapter(MaterialRatingRuleAdapter());

    Hive.registerAdapter(ServiceMasterAdapter());
    Hive.registerAdapter(ServiceNameAdapter());
    Hive.registerAdapter(ServiceTypeAdapter());
    
    // Register Bill of Preparation adapters
    Hive.registerAdapter(BillOfPreparationAdapter());
    Hive.registerAdapter(CktTypeAdapter());
    Hive.registerAdapter(MaterialCktTypeAdapter());
    Hive.registerAdapter(BopMaterialAdapter());
    
    _adaptersRegistered = true;
  }

  // Then open boxes
  await Future.wait([
    Hive.openBox<Supplier>('suppliers'),
    Hive.openBox<Supplier>('service_suppliers'),
    Hive.openBox<MaterialItem>('materials'),
    Hive.openBox<Customer>('customers'),
    Hive.openBox<PurchaseOrder>('purchaseOrders'),
    Hive.openBox<StoreInward>('store_inwards'),
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
    Hive.openBox<StockMaintenance>('stock_maintenance'),
    Hive.openBox<MaterialRequest>('material_requests'),
    Hive.openBox<MaterialIssue>('material_issues'),
    Hive.openBox<DeliveryChallan>('delivery_challans'),
    Hive.openBox<StateModel>('states'),
    Hive.openBox<GSTModel>('gst'),
    Hive.openBox<InventoryClassification>('inventory_classifications'),
    Hive.openBox<CustomerScopeMaterialIssueMaster>('customer_scope_material_issue_masters'),
    Hive.openBox<CustomerScopeStockMaintenance>('customer_scope_stock_maintenance'),
    Hive.openBox<PaymentTerms>('paymentTerms'),
    Hive.openBox<MaterialRatingRule>('materialRatingRules'),
    Hive.openBox<ServiceMaster>('serviceMasters'),
    Hive.openBox<ServiceName>('serviceNames'),
    Hive.openBox<ServiceType>('serviceTypes'),
    Hive.openBox<BillOfPreparation>('billOfPreparations'),
    Hive.openBox('ui_settings'),
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
      Hive.deleteBoxFromDisk('store_inwards'),
      Hive.deleteBoxFromDisk('suppliers'),
      Hive.deleteBoxFromDisk('service_suppliers'),
      Hive.deleteBoxFromDisk('vendorMaterialRates'),
      Hive.deleteBoxFromDisk('qualityInspections'),
      Hive.deleteBoxFromDisk('categoryParameterMappings'),
      Hive.deleteBoxFromDisk('saleOrders'),
      Hive.deleteBoxFromDisk('categories'),
      Hive.deleteBoxFromDisk('subCategories'),
      Hive.deleteBoxFromDisk('qualities'),
      Hive.deleteBoxFromDisk('universal_parameters'),
      Hive.deleteBoxFromDisk('schemaVersion'),
      Hive.deleteBoxFromDisk('stock_maintenance'),
      Hive.deleteBoxFromDisk('material_requests'),
      Hive.deleteBoxFromDisk('material_issues'),
      Hive.deleteBoxFromDisk('delivery_challans'),
      Hive.deleteBoxFromDisk('states'),
      Hive.deleteBoxFromDisk('gst'),
      Hive.deleteBoxFromDisk('inventory_classifications'),
      Hive.deleteBoxFromDisk('customer_scope_stock_maintenance'),
      Hive.deleteBoxFromDisk('serviceMasters'),
      Hive.deleteBoxFromDisk('serviceNames'),
      Hive.deleteBoxFromDisk('serviceTypes'),
      Hive.deleteBoxFromDisk('billOfPreparations'),
      // Intentionally do NOT delete 'ui_settings' so UI preferences persist
    ]);

    // Create and initialize schema version box
    final box = await Hive.openBox('schemaVersion');
    await box.put('version', 13);
  } catch (e) {
    print('Error clearing incompatible data: $e');
    try {
      await Future.wait([
        Hive.deleteBoxFromDisk('customers'),
        Hive.deleteBoxFromDisk('employees'),
        Hive.deleteBoxFromDisk('materials'),
        Hive.deleteBoxFromDisk('purchaseOrders'),
        Hive.deleteBoxFromDisk('purchaseRequests'),
        Hive.deleteBoxFromDisk('store_inwards'),
        Hive.deleteBoxFromDisk('suppliers'),
        Hive.deleteBoxFromDisk('service_suppliers'),
        Hive.deleteBoxFromDisk('vendorMaterialRates'),
        Hive.deleteBoxFromDisk('qualityInspections'),
        Hive.deleteBoxFromDisk('categoryParameterMappings'),
        Hive.deleteBoxFromDisk('saleOrders'),
        Hive.deleteBoxFromDisk('categories'),
        Hive.deleteBoxFromDisk('subCategories'),
        Hive.deleteBoxFromDisk('qualities'),
        Hive.deleteBoxFromDisk('universal_parameters'),
        Hive.deleteBoxFromDisk('schemaVersion'),
        Hive.deleteBoxFromDisk('stock_maintenance'),
        Hive.deleteBoxFromDisk('material_requests'),
        Hive.deleteBoxFromDisk('material_issues'),
        Hive.deleteBoxFromDisk('delivery_challans'),
        Hive.deleteBoxFromDisk('states'),
        Hive.deleteBoxFromDisk('gst'),
        Hive.deleteBoxFromDisk('inventory_classifications'),
        Hive.deleteBoxFromDisk('customer_scope_stock_maintenance'),
      ]);
    } catch (e) {
      print('Error deleting boxes: $e');
    }
  }
}
