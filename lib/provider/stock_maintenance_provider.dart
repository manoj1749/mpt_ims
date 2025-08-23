// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;
import '../models/stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/quality_inspection.dart';
import '../models/material_item.dart';
import 'base_provider.dart';

final stockMaintenanceBoxProvider = Provider<Box<StockMaintenance>>((ref) {
  throw UnimplementedError();
});

final stockMaintenanceProvider =
    StateNotifierProvider<StockMaintenanceNotifier, List<StockMaintenance>>(
  (ref) => StockMaintenanceNotifier(
    ref.watch(stockMaintenanceBoxProvider),
    ref,
  ),
);

class StockMaintenanceNotifier extends BaseProvider<StockMaintenance> {
  StockMaintenanceNotifier(Box<StockMaintenance> stockBox, Ref ref) 
      : super(stockBox, 'stockMaintenance');

  @override
  Map<String, dynamic> modelToMap(StockMaintenance stock) {
    return {
      'materialCode': stock.materialCode,
      'materialDescription': stock.materialDescription,
      'unit': stock.unit,
      'storageLocation': stock.storageLocation,
      'rackNumber': stock.rackNumber,
      'currentStock': stock.currentStock,
      'stockUnderInspection': stock.stockUnderInspection,
      'totalStockValue': stock.totalStockValue,
      'grnDetails': stock.grnDetails.map((key, value) => MapEntry(key, {
        'grnNo': value.grnNo,
        'grnDate': value.grnDate,
        'receivedQuantity': value.receivedQuantity,
        'acceptedQuantity': value.acceptedQuantity,
        'rejectedQuantity': value.rejectedQuantity,
        'vendorId': value.vendorId,
        'rate': value.rate,
        'issuedQuantity': value.issuedQuantity,
        'issuedQuantities': value.issuedQuantities,
      })),
      'poDetails': stock.poDetails.map((key, value) => MapEntry(key, {
        'poNo': value.poNo,
        'poDate': value.poDate,
        'orderedQuantity': value.orderedQuantity,
        'receivedQuantity': value.receivedQuantity,
        'vendorId': value.vendorId,
        'rate': value.rate,
        'receivedQuantities': value.receivedQuantities,
      })),
             'prDetails': stock.prDetails.map((key, value) => MapEntry(key, {
         'prNo': value.prNo,
         'prDate': value.prDate,
         'requestedQuantity': value.requestedQuantity,
         'orderedQuantity': value.orderedQuantity,
         'receivedQuantity': value.receivedQuantity,
         'issuedQuantity': value.issuedQuantity,
         'jobNo': value.jobNo,
       })),
      'jobDetails': stock.jobDetails.map((key, value) => MapEntry(key, {
        'jobNo': value.jobNo,
        'allocatedQuantity': value.allocatedQuantity,
        'consumedQuantity': value.consumedQuantity,
        'pendingDeliveryQuantity': value.pendingDeliveryQuantity,
      })),
             'vendorDetails': stock.vendorDetails.map((key, value) => MapEntry(key, {
         'vendorId': value.vendorId,
         'vendorName': value.vendorName,
         'quantity': value.quantity,
         'rate': value.rate,
         'lastPurchaseDate': value.lastPurchaseDate,
       })),
    };
  }

  @override
  StockMaintenance mapToModel(Map<String, dynamic> map) {
        final stock = StockMaintenance(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      storageLocation: map['storageLocation'] ?? '',
      rackNumber: map['rackNumber'] ?? '',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      stockUnderInspection: (map['stockUnderInspection'] as num?)?.toDouble() ?? 0.0,
      totalStockValue: (map['totalStockValue'] as num?)?.toDouble() ?? 0.0,
        );

        // Load GRN details
    if (map['grnDetails'] != null) {
      (map['grnDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.grnDetails[key] = StockGRNDetails(
              grnNo: value['grnNo'] ?? '',
              grnDate: value['grnDate'] ?? '',
              receivedQuantity: (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
              acceptedQuantity: (value['acceptedQuantity'] as num?)?.toDouble() ?? 0.0,
              rejectedQuantity: (value['rejectedQuantity'] as num?)?.toDouble() ?? 0.0,
              vendorId: value['vendorId'] ?? '',
              rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              issuedQuantity: (value['issuedQuantity'] as num?)?.toDouble() ?? 0.0,
              issuedQuantities: (value['issuedQuantities'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ) ?? {},
            );
          });
        }

        // Load PO details
    if (map['poDetails'] != null) {
      (map['poDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.poDetails[key] = StockPODetails(
              poNo: value['poNo'] ?? '',
              poDate: value['poDate'] ?? '',
              orderedQuantity: (value['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
              receivedQuantity: (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
              vendorId: value['vendorId'] ?? '',
              rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              receivedQuantities: (value['receivedQuantities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Map<String, double>.from(value as Map)),
              ) ?? {},
            );
          });
        }

        // Load PR details
     if (map['prDetails'] != null) {
       (map['prDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.prDetails[key] = StockPRDetails(
              prNo: value['prNo'] ?? '',
              prDate: value['prDate'] ?? '',
              requestedQuantity: (value['requestedQuantity'] as num?)?.toDouble() ?? 0.0,
              orderedQuantity: (value['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
              receivedQuantity: (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
              issuedQuantity: (value['issuedQuantity'] as num?)?.toDouble() ?? 0.0,
              jobNo: value['jobNo'] ?? '',
            );
          });
        }

    // Load Job details
    if (map['jobDetails'] != null) {
      (map['jobDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.jobDetails[key] = StockJobDetails(
              jobNo: value['jobNo'] ?? '',
              allocatedQuantity: (value['allocatedQuantity'] as num?)?.toDouble() ?? 0.0,
              consumedQuantity: (value['consumedQuantity'] as num?)?.toDouble() ?? 0.0,
          pendingDeliveryQuantity: (value['pendingDeliveryQuantity'] as num?)?.toDouble() ?? 0.0,
          prNo: value['prNo'] ?? 'General',
            );
          });
        }

         // Load Vendor details
     if (map['vendorDetails'] != null) {
       (map['vendorDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.vendorDetails[key] = StockVendorDetails(
              vendorId: value['vendorId'] ?? '',
              vendorName: value['vendorName'] ?? '',
              quantity: (value['quantity'] as num?)?.toDouble() ?? 0.0,
              rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              lastPurchaseDate: value['lastPurchaseDate'] ?? '',
            );
          });
        }

    return stock;
  }

  @override
  String getModelId(StockMaintenance stock) => stock.materialCode;

  // Backward compatibility methods
  Future<void> loadStock() => loadData();

  @override
  Future<void> loadData() async {
    print('\n=== Debug: Stock Maintenance LoadData ===');
    print('Collection Name: $collectionName');
    
    // Call parent loadData method
    await super.loadData();
    
    print('Stock Maintenance State after load: ${state.length} items');
    for (var stock in state) {
      print('Stock: ${stock.materialCode} - Current: ${stock.currentStock} - Under Inspection: ${stock.stockUnderInspection}');
    }
    print('=== End Stock Maintenance LoadData ===\n');
  }

  // All existing functionality preserved below:

  Future<void> initializeStock(MaterialItem material) async {
    try {
      print('\n=== Initializing Stock for Material ${material.slNo} ===');
      
      // Check if stock already exists
      final existingStock = state.where((stock) => stock.materialCode == material.slNo).firstOrNull;
      if (existingStock != null) {
        print('Stock already exists for material ${material.slNo}');
        return;
      }

      // Create new stock entry
      final newStock = StockMaintenance(
        materialCode: material.slNo,
        materialDescription: material.description,
        unit: material.unit,
        storageLocation: material.storageLocation ?? '',
        rackNumber: material.rackNumber ?? '',
        currentStock: 0.0,
        stockUnderInspection: 0.0,
        totalStockValue: 0.0,
      );

      await add(newStock);
      print('Stock initialized for material ${material.slNo}');
    } catch (e) {
      print('Error initializing stock: $e');
      rethrow;
    }
  }

  Future<void> updateStockFromGRN(StoreInward grn) async {
    print('\n=== Debug: Starting Stock Update from GRN ${grn.grnNo} ===');
    print('GRN Number: ${grn.grnNo}');

    try {
      // Process each item in the GRN
      for (var grnItem in grn.items) {
        print('\n--- Processing item: ${grnItem.materialCode} ---');

        // Get or create stock record for this material
        var stock = state.firstWhere(
          (s) => s.materialCode == grnItem.materialCode,
          orElse: () {
            print('Creating new stock record for ${grnItem.materialCode}');
            return StockMaintenance(
              materialCode: grnItem.materialCode,
              materialDescription: grnItem.materialDescription,
              unit: grnItem.unit,
            storageLocation: '',
            rackNumber: '',
            );
          },
        );

        // Check if this is a new stock record (not in state yet)
        bool isNewStock = !state.any((s) => s.materialCode == grnItem.materialCode);

        // Update GRN details
        stock.grnDetails[grn.grnNo] = StockGRNDetails(
          grnNo: grn.grnNo,
          grnDate: grn.grnDate,
          receivedQuantity: grnItem.receivedQty,
          acceptedQuantity: grnItem.acceptedQty,
          rejectedQuantity: grnItem.rejectedQty,
          vendorId: grn.supplierName,
          rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
          issuedQuantity: 0.0,
          issuedQuantities: {},
        );

        // Update PR and PO details
        _updatePRDetailsFromGRN(stock, grnItem, grn.grnNo, grn);

        // Calculate total stock quantities
        double totalCurrentStock = 0.0;
        double totalUnderInspection = 0.0;

        for (var grnDetail in stock.grnDetails.values) {
          totalCurrentStock += grnDetail.acceptedQuantity;
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
      print('Error updating stock from GRN: $e');
      rethrow;
    }
  }

  void _updatePRDetailsFromGRN(StockMaintenance stock, InwardItem grnItem, String grnNo, StoreInward grn) {
    print('\nUpdating PR details for ${grnItem.materialCode}');
    
    // Process each PO and its PR quantities
    for (var poEntry in grnItem.prQuantities.entries) {
      final poNo = poEntry.key;
      final prMap = poEntry.value;
      if (prMap.isEmpty) continue;

      print('Processing PO: $poNo');
      
      // Create or update PO details
      stock.poDetails[poNo] ??= StockPODetails(
        poNo: poNo,
        poDate: '',  // This will be updated when we have PO date
        orderedQuantity: grnItem.orderedQty,
        receivedQuantity: 0.0,
        vendorId: grn.supplierName,
        rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
        receivedQuantities: {},
        issuedQuantities: {},
      );

      // Process each PR in this PO
      for (var prEntry in prMap.entries) {
        final prNo = prEntry.key;
        final prQty = prEntry.value;
        final jobNo = grnItem.prJobNumbers[poNo]?[prNo] ?? 'General';

        print('Processing PR: $prNo, Job: $jobNo, Quantity: $prQty');

        // Create or update PR details
        stock.prDetails[prNo] ??= StockPRDetails(
          prNo: prNo,
          prDate: '',  // This will be updated when we have PR date
          requestedQuantity: prQty,
          orderedQuantity: prQty,
          receivedQuantity: 0.0,
          issuedQuantity: 0.0,
          jobNo: jobNo,
        );

        // Update job details if it's not a general PR
        if (jobNo != 'General') {
          print('Updating job details for job: $jobNo');
          stock.jobDetails[jobNo] ??= StockJobDetails(
            jobNo: jobNo,
            allocatedQuantity: prQty,
            consumedQuantity: 0.0,
            pendingDeliveryQuantity: 0.0,
            prNo: prNo,
          );
        }

        // Update PO received quantities
        stock.poDetails[poNo]!.addReceivedQuantity(grnNo, prNo, prQty);

        // Update PR received quantity immediately for accepted quantities
        if (grnItem.acceptedQty > 0) {
          final acceptanceRatio = grnItem.acceptedQty / grnItem.receivedQty;
          final acceptedQty = prQty * acceptanceRatio;
          stock.prDetails[prNo]!.receivedQuantity += acceptedQty;
          print('Updated PR $prNo received quantity to: ${stock.prDetails[prNo]!.receivedQuantity}');
        }
      }

      // Update total received quantity for PO
      stock.poDetails[poNo]!.receivedQuantity = stock.poDetails[poNo]!.receivedQuantities.values
          .expand((map) => map.values)
          .fold(0.0, (sum, qty) => sum + qty);
    }

    // Update vendor details (simplified based on actual model)
    _updateVendorDetails(stock, grn.supplierName, grnItem);
  }

  void _updateVendorDetails(StockMaintenance stock, String vendorId, InwardItem grnItem) {
    // Create or update vendor details using the actual model fields
    if (stock.vendorDetails.containsKey(vendorId)) {
      final vendorDetails = stock.vendorDetails[vendorId]!;
      vendorDetails.quantity += grnItem.receivedQty;
      
      // Calculate new average rate
      final totalValue = (vendorDetails.rate * (vendorDetails.quantity - grnItem.receivedQty)) + 
                        (double.tryParse(grnItem.costPerUnit) ?? 0.0) * grnItem.receivedQty;
      vendorDetails.rate = totalValue / vendorDetails.quantity;
      vendorDetails.lastPurchaseDate = DateTime.now().toIso8601String();
    } else {
      stock.vendorDetails[vendorId] = StockVendorDetails(
        vendorId: vendorId,
        vendorName: vendorId, // Using vendorId as name for now
        quantity: grnItem.receivedQty,
        rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
        lastPurchaseDate: DateTime.now().toIso8601String(),
      );
    }
  }

  void _updatePRReceivedQuantitiesFromInspection(StockMaintenance stock, String grnNo, InspectionGRNQuantity grnQty) {
    print('\n=== Updating PR Received Quantities from Inspection ===');
    print('GRN: $grnNo, Accepted: ${grnQty.acceptedQty}, Rejected: ${grnQty.rejectedQty}');
    
    // Find the GRN details to get the original PR mapping
    final grnDetails = stock.grnDetails[grnNo];
    if (grnDetails == null) {
      print('GRN details not found for $grnNo');
      return;
    }
    
    // Calculate acceptance ratio
    final totalReceived = grnDetails.receivedQuantity;
    final totalAccepted = grnQty.acceptedQty;
    final acceptanceRatio = totalReceived > 0 ? totalAccepted / totalReceived : 0.0;
    
    print('Acceptance Ratio: $acceptanceRatio');
    
    // Update PR received quantities based on acceptance ratio
    for (var poEntry in stock.poDetails.entries) {
      final poNo = poEntry.key;
      final poDetails = poEntry.value;
      
      // Check if this PO has received quantities for this GRN
      if (poDetails.receivedQuantities.containsKey(grnNo)) {
        final prQuantities = poDetails.receivedQuantities[grnNo]!;
        
        for (var prEntry in prQuantities.entries) {
          final prNo = prEntry.key;
          final originalQty = prEntry.value;
          final acceptedQty = originalQty * acceptanceRatio;
          
          print('PR: $prNo, Original: $originalQty, Accepted: $acceptedQty');
          
          // Update PR received quantity
          if (stock.prDetails.containsKey(prNo)) {
            // Reset the received quantity for this PR and add the accepted quantity
            stock.prDetails[prNo]!.receivedQuantity = acceptedQty;
            print('Updated PR $prNo received quantity to: $acceptedQty');
          }
        }
      }
    }
  }

  Future<void> updateStockFromInspection(QualityInspection inspection) async {
    try {
      print('\n=== Updating Stock from Inspection ${inspection.inspectionNo} ===');
      
      for (var inspectionItem in inspection.items) {
        print('\nProcessing inspection item: ${inspectionItem.materialCode}');
        
        // Find stock for this material
        final stock = state.where((s) => s.materialCode == inspectionItem.materialCode).firstOrNull;
        
        if (stock != null) {
          // Update GRN details with inspection results
          for (var grnEntry in inspectionItem.grnQuantities.entries) {
            final grnNo = grnEntry.key;
            final grnQty = grnEntry.value;
            
            if (stock.grnDetails.containsKey(grnNo) && (grnQty.isSelected ?? false)) {
              stock.grnDetails[grnNo]!.acceptedQuantity = grnQty.acceptedQty;
              stock.grnDetails[grnNo]!.rejectedQuantity = grnQty.rejectedQty;
              
              // Update PR received quantities based on acceptance ratio
              _updatePRReceivedQuantitiesFromInspection(stock, grnNo, grnQty);
            }
          }
          
          // Recalculate stock quantities
          double totalCurrentStock = 0.0;
          double totalUnderInspection = 0.0;

          for (var grnDetail in stock.grnDetails.values) {
            totalCurrentStock += grnDetail.acceptedQuantity;
            totalUnderInspection += grnDetail.receivedQuantity -
                (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
          }

          print('New Current Stock: $totalCurrentStock');
          print('New Under Inspection: $totalUnderInspection');

          // Update stock quantities
          stock.updateCurrentStock(totalCurrentStock);
          stock.updateStockUnderInspection(totalUnderInspection);

          // Use BaseProvider's update method to ensure proper persistence
          await update(stock);
        } else {
          print('Stock not found for material: ${inspectionItem.materialCode}');
          // This should not happen if stock was created during GRN
          print('Warning: Stock should have been created during GRN process');
        }
      }
    } catch (e) {
      print('Error updating stock from inspection: $e');
      rethrow;
    }
  }

  Future<void> updateStockLocation(String materialCode, String newLocation, String newRack) async {
    try {
      var stock = state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        stock.storageLocation = newLocation;
        stock.rackNumber = newRack;
        await update(stock);
        print('Updated location for material $materialCode');
      }
    } catch (e) {
      print('Error updating stock location: $e');
      rethrow;
    }
  }

  Future<void> cancelPendingDelivery(String materialCode, String jobNo, double quantity) async {
    try {
      var stock = state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        final jobDetails = stock.jobDetails[jobNo];
        if (jobDetails != null) {
          jobDetails.pendingDeliveryQuantity = math.max(0, jobDetails.pendingDeliveryQuantity - quantity);
          jobDetails.allocatedQuantity = math.max(0, jobDetails.allocatedQuantity - quantity);
          stock.currentStock += quantity; // Return to available stock
          await update(stock);
        }
      }
    } catch (e) {
      print('Error canceling pending delivery: $e');
      rethrow;
    }
  }

  Future<void> updatePendingDeliveryQuantity(String materialCode, String jobNo, double newQuantity) async {
    try {
      var stock = state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        final jobDetails = stock.jobDetails[jobNo];
        if (jobDetails != null) {
          final oldQuantity = jobDetails.pendingDeliveryQuantity;
          jobDetails.pendingDeliveryQuantity = newQuantity;
          
          // Adjust allocated quantity accordingly
          final difference = newQuantity - oldQuantity;
          jobDetails.allocatedQuantity += difference;
          stock.currentStock -= difference;
          
          await update(stock);
        }
      }
    } catch (e) {
      print('Error updating pending delivery quantity: $e');
      rethrow;
    }
  }

  Future<void> consumeStockForJob(String materialCode, String jobNo, double quantity) async {
    try {
      var stock = state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        final jobDetails = stock.jobDetails[jobNo];
        if (jobDetails != null) {
          jobDetails.consumedQuantity += quantity;
          jobDetails.pendingDeliveryQuantity = math.max(0, jobDetails.pendingDeliveryQuantity - quantity);
          await update(stock);
        }
      }
    } catch (e) {
      print('Error consuming stock for job: $e');
      rethrow;
    }
  }



  // Search and filter methods
  List<StockMaintenance> searchStock(String query) {
    return search(query, (stock, query) =>
        stock.materialCode.toLowerCase().contains(query) ||
        stock.materialDescription.toLowerCase().contains(query));
  }

  List<StockMaintenance> getLowStockItems({double threshold = 10.0}) {
    return state.where((stock) => stock.currentStock <= threshold).toList();
  }

  List<StockMaintenance> getZeroStockItems() {
    return state.where((stock) => stock.currentStock == 0).toList();
  }

  List<StockMaintenance> getStockUnderInspection() {
    return state.where((stock) => stock.stockUnderInspection > 0).toList();
  }

  StockMaintenance? getStockByMaterialCode(String materialCode) {
    return state.where((stock) => stock.materialCode == materialCode).firstOrNull;
  }

  // Alias for backward compatibility
  StockMaintenance? getStockForMaterial(String materialCode) {
    return getStockByMaterialCode(materialCode);
  }

  double getTotalStockValue() {
    return state.fold(0.0, (sum, stock) => sum + stock.totalStockValue);
  }

  Map<String, double> getVendorWiseStockValue() {
    final vendorValues = <String, double>{};
    for (var stock in state) {
      for (var vendor in stock.vendorDetails.values) {
        vendorValues[vendor.vendorId] = (vendorValues[vendor.vendorId] ?? 0.0) + 
            (vendor.quantity * vendor.rate);
      }
    }
    return vendorValues;
  }
}
