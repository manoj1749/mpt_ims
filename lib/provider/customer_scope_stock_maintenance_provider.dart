// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/customer_scope_stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/quality_inspection.dart';
import '../models/customer_scope_material_issue_master.dart';
import 'base_provider.dart';

final customerScopeStockMaintenanceBoxProvider = Provider<Box<CustomerScopeStockMaintenance>>((ref) {
  throw UnimplementedError();
});

final customerScopeStockMaintenanceProvider =
    StateNotifierProvider<CustomerScopeStockMaintenanceNotifier, List<CustomerScopeStockMaintenance>>(
  (ref) => CustomerScopeStockMaintenanceNotifier(
    ref.watch(customerScopeStockMaintenanceBoxProvider),
    ref,
  ),
);

class CustomerScopeStockMaintenanceNotifier extends BaseProvider<CustomerScopeStockMaintenance> {
  CustomerScopeStockMaintenanceNotifier(Box<CustomerScopeStockMaintenance> stockBox, Ref ref)
      : super(stockBox, 'customerScopeStockMaintenance');

  @override
  Map<String, dynamic> modelToMap(CustomerScopeStockMaintenance stock) {
    return {
      'materialCode': stock.materialCode,
      'materialDescription': stock.materialDescription,
      'unit': stock.unit,
      'storageLocation': stock.storageLocation,
      'rackNumber': stock.rackNumber,
      'currentStock': stock.currentStock,
      'stockUnderInspection': stock.stockUnderInspection,
      'customerName': stock.customerName,
      'customerId': stock.customerId,
      'totalStockValue': stock.totalStockValue,
      'grnDetails': stock.grnDetails.map((key, value) => MapEntry(key, {
            'grnNo': value.grnNo,
            'grnDate': value.grnDate,
            'receivedQuantity': value.receivedQuantity,
            'acceptedQuantity': value.acceptedQuantity,
            'rejectedQuantity': value.rejectedQuantity,
            'rate': value.rate,
            'issuedQuantity': value.issuedQuantity,
            'issuedQuantities': value.issuedQuantities,
          })),
      'jobDetails': stock.jobDetails.map((key, value) => MapEntry(key, {
            'jobNo': value.jobNo,
            'allocatedQuantity': value.allocatedQuantity,
            'consumedQuantity': value.consumedQuantity,
          })),
    };
  }

  @override
  CustomerScopeStockMaintenance mapToModel(Map<String, dynamic> map) {
    final stock = CustomerScopeStockMaintenance(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      storageLocation: map['storageLocation'] ?? '',
      rackNumber: map['rackNumber'] ?? '',
      customerName: map['customerName'] ?? '',
      customerId: map['customerId'] ?? '',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      stockUnderInspection:
          (map['stockUnderInspection'] as num?)?.toDouble() ?? 0.0,
      totalStockValue: (map['totalStockValue'] as num?)?.toDouble() ?? 0.0,
    );

    // Load GRN details
    if (map['grnDetails'] != null) {
      (map['grnDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.grnDetails[key] = CustomerScopeGRNDetails(
          grnNo: value['grnNo'] ?? '',
          grnDate: value['grnDate'] ?? '',
          receivedQuantity:
              (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
          acceptedQuantity:
              (value['acceptedQuantity'] as num?)?.toDouble() ?? 0.0,
          rejectedQuantity:
              (value['rejectedQuantity'] as num?)?.toDouble() ?? 0.0,
          rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
          issuedQuantity: (value['issuedQuantity'] as num?)?.toDouble() ?? 0.0,
          issuedQuantities:
              (value['issuedQuantities'] as Map<String, dynamic>?)?.map(
                    (key, value) => MapEntry(key, (value as num).toDouble()),
                  ) ??
                  {},
        );
      });
    }

    // Load Job details
    if (map['jobDetails'] != null) {
      (map['jobDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.jobDetails[key] = CustomerScopeJobDetails(
          jobNo: value['jobNo'] ?? '',
          allocatedQuantity:
              (value['allocatedQuantity'] as num?)?.toDouble() ?? 0.0,
          consumedQuantity:
              (value['consumedQuantity'] as num?)?.toDouble() ?? 0.0,
        );
      });
    }

    return stock;
  }

  @override
  String getModelId(CustomerScopeStockMaintenance stock) => '${stock.customerId}_${stock.materialCode}';

  // Backward compatibility methods
  Future<void> loadStock() => loadData();

  @override
  Future<void> loadData() async {
    print('\n=== Debug: Customer Scope Stock Maintenance LoadData ===');
    print('Collection Name: $collectionName');

    // Call parent loadData method
    await super.loadData();

    print('Customer Scope Stock Maintenance State after load: ${state.length} items');
    for (var stock in state) {
      print(
          'Stock: ${stock.materialCode} (Customer: ${stock.customerName}) - Current: ${stock.currentStock} - Under Inspection: ${stock.stockUnderInspection}');
    }
    print('=== End Customer Scope Stock Maintenance LoadData ===\n');
  }

  // Initialize stock for customer scope material
  Future<void> initializeStock(CustomerScopeMaterialIssueMaster material, String customerId, String customerName) async {
    try {
      print('\n=== Initializing Customer Scope Stock for Material ${material.slNo} ===');

      // Check if stock already exists for this customer and material
      final existingStock = state
          .where((stock) => stock.materialCode == material.slNo && stock.customerId == customerId)
          .firstOrNull;
      if (existingStock != null) {
        print('Stock already exists for material ${material.slNo} and customer $customerId');
        return;
      }

      // Create new stock entry
      final newStock = CustomerScopeStockMaintenance(
        materialCode: material.slNo,
        materialDescription: material.description,
        unit: material.unit,
        storageLocation: material.storageLocation ?? '',
        rackNumber: material.rackNumber ?? '',
        customerName: customerName,
        customerId: customerId,
        currentStock: 0.0,
        stockUnderInspection: 0.0,
        totalStockValue: 0.0,
      );

      await add(newStock);
      print('Customer Scope Stock initialized for material ${material.slNo}');
    } catch (e) {
      print('Error initializing customer scope stock: $e');
      rethrow;
    }
  }

  // Update stock from Customer Scope GRN
  Future<void> updateStockFromGRN(StoreInward grn, String customerId, String customerName) async {
    print('\n=== Debug: Starting Customer Scope Stock Update from GRN ${grn.grnNo} ===');
    print('GRN Number: ${grn.grnNo}');
    print('Customer: $customerName ($customerId)');

    try {
      // Process each item in the GRN
      for (var grnItem in grn.items) {
        print('\n--- Processing item: ${grnItem.materialCode} ---');

        // Get or create stock record for this material and customer
        var stock = state.firstWhere(
          (s) => s.materialCode == grnItem.materialCode && s.customerId == customerId,
          orElse: () {
            print('Creating new customer scope stock record for ${grnItem.materialCode}');
            return CustomerScopeStockMaintenance(
              materialCode: grnItem.materialCode,
              materialDescription: grnItem.materialDescription,
              unit: grnItem.unit,
              storageLocation: '',
              rackNumber: '',
              customerName: customerName,
              customerId: customerId,
            );
          },
        );

        // Check if this is a new stock record (not in state yet)
        bool isNewStock =
            !state.any((s) => s.materialCode == grnItem.materialCode && s.customerId == customerId);

        // Update GRN details
        stock.grnDetails[grn.grnNo] = CustomerScopeGRNDetails(
          grnNo: grn.grnNo,
          grnDate: grn.grnDate,
          receivedQuantity: grnItem.receivedQty,
          acceptedQuantity: grnItem.acceptedQty,
          rejectedQuantity: grnItem.rejectedQty,
          rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
          issuedQuantity: 0.0,
          issuedQuantities: {},
        );

        // Calculate total stock quantities
        double totalCurrentStock = 0.0;
        double totalUnderInspection = 0.0;

        for (var grnDetail in stock.grnDetails.values) {
          totalCurrentStock += grnDetail.acceptedQuantity - grnDetail.issuedQuantity;
          totalUnderInspection += grnDetail.receivedQuantity -
              (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
        }

        print('New Current Stock: $totalCurrentStock');
        print('New Under Inspection: $totalUnderInspection');

        // Update stock quantities
        stock.updateCurrentStock(totalCurrentStock);
        stock.updateStockUnderInspection(totalUnderInspection);

        // Use BaseProvider's add method for new stock, update method for existing stock
        if (isNewStock) {
          await add(stock);
        } else {
          await update(stock);
        }
      }
    } catch (e) {
      print('Error updating customer scope stock from GRN: $e');
      rethrow;
    }
  }

  // Update stock from incoming inspection
  Future<void> updateStockFromInspection(QualityInspection inspection, String customerId) async {
    try {
      print(
          '\n=== Updating Customer Scope Stock from Inspection ${inspection.inspectionNo} ===');

      for (var inspectionItem in inspection.items) {
        print('\nProcessing inspection item: ${inspectionItem.materialCode}');

        // Find stock for this material and customer
        final stock = state
            .where((s) => s.materialCode == inspectionItem.materialCode && s.customerId == customerId)
            .firstOrNull;

        if (stock != null) {
          print('Found customer scope stock record for ${inspectionItem.materialCode}');
          bool stockUpdated = false;
          
          // Update GRN details with inspection results
          for (var grnEntry in inspectionItem.grnQuantities.entries) {
            final grnNo = grnEntry.key;
            final grnQty = grnEntry.value;

            print('Processing GRN: $grnNo, Selected: ${grnQty.isSelected}');
            print('Accepted: ${grnQty.acceptedQty}, Rejected: ${grnQty.rejectedQty}');

            if (stock.grnDetails.containsKey(grnNo) &&
                (grnQty.isSelected ?? false)) {
              print('Updating GRN details for $grnNo');
              
              final grnDetail = stock.grnDetails[grnNo];
              if (grnDetail == null) {
                print('Error: GRN detail is null for $grnNo');
                continue;
              }
              
              final oldAccepted = grnDetail.acceptedQuantity;
              final oldRejected = grnDetail.rejectedQuantity;
              
              grnDetail.acceptedQuantity = grnQty.acceptedQty;
              grnDetail.rejectedQuantity = grnQty.rejectedQty;
              
              print('Updated GRN $grnNo: Accepted $oldAccepted -> ${grnQty.acceptedQty}, Rejected $oldRejected -> ${grnQty.rejectedQty}');
              stockUpdated = true;
            }
          }

          if (stockUpdated) {
            // Recalculate stock quantities
            double totalCurrentStock = 0.0;
            double totalUnderInspection = 0.0;

            for (var grnDetail in stock.grnDetails.values) {
              totalCurrentStock += grnDetail.acceptedQuantity - grnDetail.issuedQuantity;
              totalUnderInspection += grnDetail.receivedQuantity -
                  (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
            }

            print('Recalculated - Current Stock: $totalCurrentStock, Under Inspection: $totalUnderInspection');

            // Update stock quantities
            stock.updateCurrentStock(totalCurrentStock);
            stock.updateStockUnderInspection(totalUnderInspection);

            // Use BaseProvider's update method to ensure proper persistence
            await update(stock);
            print('Customer Scope Stock successfully updated and persisted for ${inspectionItem.materialCode}');
          } else {
            print('No stock updates needed for ${inspectionItem.materialCode}');
          }
        } else {
          print('Customer Scope Stock not found for material: ${inspectionItem.materialCode}');
        }
      }
      
      print('=== Completed Customer Scope Stock Update from Inspection ===');
    } catch (e) {
      print('Error updating customer scope stock from inspection: $e');
      rethrow;
    }
  }

  // Update stock location
  Future<void> updateStockLocation(
      String materialCode, String customerId, String newLocation, String newRack) async {
    try {
      var stock = state
          .where((s) => s.materialCode == materialCode && s.customerId == customerId)
          .firstOrNull;
      if (stock != null) {
        stock.storageLocation = newLocation;
        stock.rackNumber = newRack;
        await update(stock);
        print('Updated location for customer scope material $materialCode');
      }
    } catch (e) {
      print('Error updating customer scope stock location: $e');
      rethrow;
    }
  }

  // Search and filter methods
  List<CustomerScopeStockMaintenance> searchStock(String query) {
    return search(
        query,
        (stock, query) =>
            stock.materialCode.toLowerCase().contains(query) ||
            stock.materialDescription.toLowerCase().contains(query) ||
            stock.customerName.toLowerCase().contains(query));
  }

  List<CustomerScopeStockMaintenance> getStockByCustomer(String customerId) {
    return state.where((stock) => stock.customerId == customerId).toList();
  }

  List<CustomerScopeStockMaintenance> getLowStockItems({double threshold = 10.0}) {
    return state.where((stock) => stock.currentStock <= threshold).toList();
  }

  List<CustomerScopeStockMaintenance> getZeroStockItems() {
    return state.where((stock) => stock.currentStock == 0).toList();
  }

  List<CustomerScopeStockMaintenance> getStockUnderInspection() {
    return state.where((stock) => stock.stockUnderInspection > 0).toList();
  }

  CustomerScopeStockMaintenance? getStockByMaterialAndCustomer(String materialCode, String customerId) {
    return state
        .where((stock) => stock.materialCode == materialCode && stock.customerId == customerId)
        .firstOrNull;
  }

  double getTotalStockValue() {
    return state.fold(0.0, (sum, stock) => sum + stock.totalStockValue);
  }

  Map<String, double> getCustomerWiseStockValue() {
    final customerValues = <String, double>{};
    for (var stock in state) {
      customerValues[stock.customerId] = (customerValues[stock.customerId] ?? 0.0) +
          stock.totalStockValue;
    }
    return customerValues;
  }
}
