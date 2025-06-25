import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/supplier_provider.dart';
import '../provider/customer_provider.dart';
import '../provider/category_provider.dart';
import '../provider/sub_category_provider.dart';
import '../provider/category_parameter_provider.dart';
import '../provider/material_provider.dart';
import '../provider/purchase_request_provider.dart';
import '../provider/purchase_order.dart';
import '../provider/store_inward_provider.dart';
import '../provider/quality_inspection_provider.dart';
import '../provider/material_request_provider.dart';
import '../provider/material_issue_provider.dart';
import '../provider/delivery_challan_provider.dart';

class InitialSyncService {
  final ProviderContainer container;

  InitialSyncService(this.container);

  Future<void> syncAllData() async {
    try {
      // Basic entities
      await _syncBasicEntities();
      
      // Business documents
      await _syncBusinessDocuments();
      
      print('Successfully synced all data from Firebase');
    } catch (e) {
      print('Error during initial sync: $e');
      rethrow;
    }
  }

  Future<void> _syncBasicEntities() async {
    // Sync basic entities first as they are dependencies for other entities
    await container.read(supplierListProvider.notifier).refresh();
    await container.read(customerListProvider.notifier).refresh();
    await container.read(categoryListProvider.notifier).refresh();
    await container.read(subCategoryListProvider.notifier).refresh();
    await container.read(categoryParameterProvider.notifier).refresh();
  }

  Future<void> _syncBusinessDocuments() async {
    // Sync business documents
    await container.read(materialListProvider.notifier).refresh();
    await container.read(saleOrderListProvider.notifier).refresh();
    await container.read(purchaseRequestListProvider.notifier).refresh();
    await container.read(purchaseOrderListProvider.notifier).refresh();
    await container.read(storeInwardListProvider.notifier).refresh();
    await container.read(qualityInspectionListProvider.notifier).refresh();
    await container.read(materialRequestListProvider.notifier).refresh();
    await container.read(materialIssueListProvider.notifier).refresh();
    await container.read(deliveryChallanListProvider.notifier).refresh();
  }
} 