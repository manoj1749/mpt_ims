// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;
import '../models/stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/category.dart';
import '../models/quality_inspection.dart';
import '../models/purchase_order.dart';
import '../models/material_item.dart';
import '../models/po_item.dart';
import '../provider/purchase_order.dart';
import '../provider/material_provider.dart';
import '../provider/category_provider.dart';
import '../provider/quality_inspection_provider.dart';
import '../provider/store_inward_provider.dart';
import '../services/sync_service.dart';

final stockMaintenanceBoxProvider = Provider<Box<StockMaintenance>>((ref) {
  throw UnimplementedError();
});

final stockMaintenanceProvider =
    StateNotifierProvider<StockMaintenanceNotifier, List<StockMaintenance>>(
  (ref) => StockMaintenanceNotifier(
    ref.watch(stockMaintenanceBoxProvider),
    ref.watch(syncServiceProvider),
    ref,
  ),
);

class StockMaintenanceNotifier extends StateNotifier<List<StockMaintenance>> {
  final Box<StockMaintenance> _stockBox;
  final SyncService _syncService;
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StockMaintenanceNotifier(this._stockBox, this._syncService, this._ref) : super([]) {
    // Load stock when initialized
    loadStock();
  }

  Future<void> loadStock() async {
    try {
      print('Loading stock from Firestore...');
      final querySnapshot = await _firestore.collection('stockMaintenance').get();

      // Clear existing stock
      await _stockBox.clear();
      
      // Keep track of all stocks to update state at the end
      final allStocks = <StockMaintenance>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final stock = StockMaintenance(
          materialCode: data['materialCode'] ?? '',
          materialDescription: data['materialDescription'] ?? '',
          unit: data['unit'] ?? '',
          storageLocation: data['storageLocation'] ?? '',
          rackNumber: data['rackNumber'] ?? '',
          currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0.0,
          stockUnderInspection: (data['stockUnderInspection'] as num?)?.toDouble() ?? 0.0,
          totalStockValue: (data['totalStockValue'] as num?)?.toDouble() ?? 0.0,
        );

        // Load GRN details
        if (data['grnDetails'] != null) {
          (data['grnDetails'] as Map<String, dynamic>).forEach((key, value) {
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
        if (data['poDetails'] != null) {
          (data['poDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.poDetails[key] = StockPODetails(
              poNo: value['poNo'] ?? '',
              poDate: value['poDate'] ?? '',
              orderedQuantity: (value['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
              receivedQuantity: (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
              vendorId: value['vendorId'] ?? '',
              rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              receivedQuantities: (value['receivedQuantities'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(
                  key,
                  (value as Map<String, dynamic>).map(
                    (k, v) => MapEntry(k, (v as num).toDouble()),
                  ),
                ),
              ) ?? {},
              issuedQuantity: (value['issuedQuantity'] as num?)?.toDouble() ?? 0.0,
              issuedQuantities: (value['issuedQuantities'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ) ?? {},
            );
          });
        }

        // Load PR details
        if (data['prDetails'] != null) {
          (data['prDetails'] as Map<String, dynamic>).forEach((key, value) {
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

        // Load job details
        if (data['jobDetails'] != null) {
          (data['jobDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.jobDetails[key] = StockJobDetails(
              jobNo: value['jobNo'] ?? '',
              allocatedQuantity: (value['allocatedQuantity'] as num?)?.toDouble() ?? 0.0,
              consumedQuantity: (value['consumedQuantity'] as num?)?.toDouble() ?? 0.0,
              prNo: value['prNo'] ?? '',
            );
          });
        }

        // Load vendor details
        if (data['vendorDetails'] != null) {
          (data['vendorDetails'] as Map<String, dynamic>).forEach((key, value) {
            stock.vendorDetails[key] = StockVendorDetails(
              vendorId: value['vendorId'] ?? '',
              vendorName: value['vendorName'] ?? '',
              quantity: (value['quantity'] as num?)?.toDouble() ?? 0.0,
              rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              lastPurchaseDate: value['lastPurchaseDate'] ?? '',
            );
          });
        }

        // Add to Hive
        await _stockBox.add(stock);
        allStocks.add(stock);
      }

      if (mounted) {
        // Update state with all stocks
        state = [...allStocks];
      }
      print('Stock loaded successfully');
    } catch (e) {
      print('Error loading stock: $e');
      rethrow;
    }
  }

  // Initialize stock for a material
  Future<void> initializeStock(MaterialItem material) async {
    try {
      print('Initializing stock for material: ${material.partNo}');
    final existingStock = _stockBox.values.firstWhere(
      (stock) => stock.materialCode == material.partNo,
      orElse: () => StockMaintenance(
        materialCode: material.partNo,
        materialDescription: material.description,
        unit: material.unit,
        storageLocation: material.storageLocation ?? '',
        rackNumber: material.rackNumber ?? '',
      ),
    );

    if (!_stockBox.values.contains(existingStock)) {
        // Add to Firestore first
        final docRef = _firestore.collection('stockMaintenance').doc();
        final data = _convertToMap(existingStock);
        await docRef.set(data);

        // Then add to Hive
      await _stockBox.add(existingStock);
        
        if (mounted) {
          state = _stockBox.values.toList();
        }
        print('Stock initialized successfully');
      }
    } catch (e) {
      print('Error initializing stock: $e');
      rethrow;
    }
  }

  // Update stock from GRN
  Future<void> updateStockFromGRN(StoreInward grn) async {
    print('\n=== Debug: Starting Stock Update from GRN ${grn.grnNo} ===');
    print('GRN Number: ${grn.grnNo}');

    try {
      // Process each item in the GRN
      for (var grnItem in grn.items) {
        print('\n--- Processing item: ${grnItem.materialCode} ---');

        // Get or create stock record for this material
        var stock = _stockBox.values.firstWhere(
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

        if (!_stockBox.values.contains(stock)) {
          print('Adding new stock for ${grnItem.materialCode}');
          await _stockBox.add(stock);
          stock = _stockBox.values.firstWhere(
            (s) => s.materialCode == grnItem.materialCode,
            orElse: () {
              throw Exception('Failed to add new stock record');
            },
          );
        }

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
        _updatePRDetailsFromGRN(stock, grnItem, grn.grnNo);

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

        // Save to Firestore
        await _saveToFirestore(stock);

        // Save to Hive
        await stock.save();
      }

      if (mounted) {
        state = _stockBox.values.toList();
      }
    } catch (e) {
      print('Error updating stock from GRN: $e');
      rethrow;
    }
  }

  // Helper method to convert StockMaintenance to Map
  Map<String, dynamic> _convertToMap(StockMaintenance stock) {
    return {
      'materialCode': stock.materialCode,
      'materialDescription': stock.materialDescription,
      'unit': stock.unit,
      'currentStock': stock.calculatedCurrentStock,  // Use calculated value
      'stockUnderInspection': stock.calculatedUnderInspection,  // Use calculated value
      'storageLocation': stock.storageLocation,
      'rackNumber': stock.rackNumber,
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
            'issuedQuantities': Map<String, dynamic>.from(value.issuedQuantities),
          })),
      'poDetails': stock.poDetails.map((key, value) => MapEntry(key, {
            'poNo': value.poNo,
            'poDate': value.poDate,
            'orderedQuantity': value.orderedQuantity,
            'receivedQuantity': value.receivedQuantity,
            'vendorId': value.vendorId,
            'rate': value.rate,
            'receivedQuantities': value.receivedQuantities.map(
              (grnNo, prQtys) => MapEntry(
                grnNo,
                Map<String, dynamic>.from(prQtys),
              ),
            ),
            'issuedQuantity': value.issuedQuantity,
            'issuedQuantities': Map<String, dynamic>.from(value.issuedQuantities),
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
            'prNo': value.prNo,
          })),
      'vendorDetails': stock.vendorDetails.map((key, value) => MapEntry(key, {
            'vendorId': value.vendorId,
            'vendorName': value.vendorName,
            'quantity': value.quantity,
            'rate': value.rate,
            'lastPurchaseDate': value.lastPurchaseDate,
          })),
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastUpdatedBy': _auth.currentUser?.email ?? 'unknown',
    };
  }

  Future<void> _saveToFirestore(StockMaintenance stock) async {
    try {
      print('Saving stock to Firestore: ${stock.materialCode}');
      
      // Convert stock to map
      final data = {
        'materialCode': stock.materialCode,
        'materialDescription': stock.materialDescription,
        'unit': stock.unit,
        'currentStock': stock.calculatedCurrentStock,
        'stockUnderInspection': stock.calculatedUnderInspection,
        'storageLocation': stock.storageLocation,
        'rackNumber': stock.rackNumber,
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
              'issuedQuantities': Map<String, dynamic>.from(value.issuedQuantities),
            })),
        'poDetails': stock.poDetails.map((key, value) => MapEntry(key, {
              'poNo': value.poNo,
              'poDate': value.poDate,
              'orderedQuantity': value.orderedQuantity,
              'receivedQuantity': value.receivedQuantity,
              'vendorId': value.vendorId,
              'rate': value.rate,
              'receivedQuantities': value.receivedQuantities.map(
                (grnNo, prQtys) => MapEntry(
                  grnNo,
                  Map<String, dynamic>.from(prQtys),
                ),
              ),
              'issuedQuantity': value.issuedQuantity,
              'issuedQuantities': Map<String, dynamic>.from(value.issuedQuantities),
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
              'prNo': value.prNo,
            })),
        'vendorDetails': stock.vendorDetails.map((key, value) => MapEntry(key, {
              'vendorId': value.vendorId,
              'vendorName': value.vendorName,
              'quantity': value.quantity,
              'rate': value.rate,
              'lastPurchaseDate': value.lastPurchaseDate,
            })),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': _auth.currentUser?.email ?? 'unknown',
      };

      // Find existing document or create new one
      final querySnapshot = await _firestore
          .collection('stockMaintenance')
          .where('materialCode', isEqualTo: stock.materialCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update(data);
      } else {
        await _firestore.collection('stockMaintenance').add(data);
      }

      print('Stock saved successfully to Firestore');
    } catch (e) {
      print('Error saving stock to Firestore: $e');
      rethrow;
    }
  }

  // Update stock based on inspection status change
  Future<void> updateStockFromInspection(QualityInspection inspection) async {
    print('\n=== Debug: Starting Stock Update from Inspection ${inspection.inspectionNo} ===');
    print('GRN Number: ${inspection.grnNo}');

    // Get required boxes from providers
    final inwardBox = _ref.read(storeInwardBoxProvider);

    try {
      // Get the GRN
      print('Looking for GRN in inward box...');
      final grn = inwardBox.values.firstWhere(
        (gr) => gr.grnNo == inspection.grnNo,
        orElse: () {
          print('Available GRNs: ${inwardBox.values.map((g) => g.grnNo).join(", ")}');
          throw Exception('GRN ${inspection.grnNo} not found');
        },
      );
      print('Found GRN: ${grn.grnNo}');

      // Process each inspected item
      for (var inspectionItem in inspection.items) {
        print('\n--- Processing item: ${inspectionItem.materialCode} ---');
        try {
          print('GRN Quantities available: ${inspectionItem.grnQuantities.keys.join(", ")}');
          print('Looking for GRN ${inspection.grnNo} in quantities...');

          // Get or create stock record for this material
          var stock = _stockBox.values.firstWhere(
            (s) => s.materialCode == inspectionItem.materialCode,
            orElse: () {
              print('Creating new stock record for ${inspectionItem.materialCode}');
              return StockMaintenance(
                materialCode: inspectionItem.materialCode,
                materialDescription: inspectionItem.materialDescription,
                unit: inspectionItem.unit,
                storageLocation: '',
                rackNumber: '',
              );
            },
          );

          if (!_stockBox.values.contains(stock)) {
            print('Adding new stock for ${inspectionItem.materialCode}');
            await _stockBox.add(stock);
            stock = _stockBox.values.firstWhere(
              (s) => s.materialCode == inspectionItem.materialCode,
              orElse: () {
                throw Exception('Failed to add new stock record');
              },
            );
          }

          // Get the selected GRN's quantities
          final selectedGRN = inspectionItem.grnQuantities.entries.firstWhere(
            (entry) => entry.key == inspection.grnNo,
            orElse: () {
              print('Available GRN entries: ${inspectionItem.grnQuantities.keys.join(", ")}');
              throw Exception('GRN ${inspection.grnNo} not found in quantities');
            },
          );
          final grnNo = selectedGRN.key;
          final grnQty = selectedGRN.value;

          print('Found GRN entry:');
          print('GRN No: $grnNo');
          print('Accepted Qty: ${grnQty.acceptedQty}');
          print('Rejected Qty: ${grnQty.rejectedQty}');
          print('Received Qty: ${grnQty.receivedQty}');

          // Get the GRN item
          final grnItem = grn.items.firstWhere(
            (item) => item.materialCode == inspectionItem.materialCode,
            orElse: () => throw Exception('Material not found in GRN'),
          );

          // Update GRN details in stock
          if (!stock.grnDetails.containsKey(grnNo)) {
            stock.grnDetails[grnNo] = StockGRNDetails(
              grnNo: grnNo,
              grnDate: grn.grnDate,
              receivedQuantity: grnQty.receivedQty,
              acceptedQuantity: grnQty.acceptedQty,
              rejectedQuantity: grnQty.rejectedQty,
              vendorId: grn.supplierName,
              rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
              issuedQuantity: 0.0,
              issuedQuantities: {},
            );
          } else {
            // Update existing GRN details
            final grnDetail = stock.grnDetails[grnNo]!;
            grnDetail.receivedQuantity = grnQty.receivedQty;
              grnDetail.acceptedQuantity = grnQty.acceptedQty;
              grnDetail.rejectedQuantity = grnQty.rejectedQty;
          }

          // Update PR and PO details
          _updatePRDetailsFromGRN(stock, grnItem, grnNo);

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

          // Save to Firestore
          await _saveToFirestore(stock);

          // Save to Hive
          await stock.save();
        } catch (e) {
          print('Error processing item: $e');
          rethrow;
        }
      }

      // Update state
      state = [..._stockBox.values];
    } catch (e) {
      print('Error updating stock from inspection: $e');
      rethrow;
    }
  }

  // Get stock for a specific material
  StockMaintenance? getStockForMaterial(String materialCode) {
    return _stockBox.values
        .firstWhere((stock) => stock.materialCode == materialCode);
  }

  // Get all stocks under inspection
  List<StockMaintenance> getStocksUnderInspection() {
    return _stockBox.values
        .where((stock) => stock.stockUnderInspection > 0)
        .toList();
  }

  // Get all stocks below minimum level (you can set minimum level as parameter)
  List<StockMaintenance> getStocksBelowMinimum(double minimumLevel) {
    return _stockBox.values
        .where((stock) => stock.currentStock < minimumLevel)
        .toList();
  }

  // Get total stock value
  double getTotalStockValue() {
    return _stockBox.values
        .fold(0.0, (sum, stock) => sum + stock.totalStockValue);
  }

  // Update stock location
  Future<void> updateStockLocation(
      String materialCode, String location, String rack) async {
    final stock = getStockForMaterial(materialCode);
    if (stock != null) {
      stock.storageLocation = location;
      stock.rackNumber = rack;
      state = [..._stockBox.values];
    }
  }

  // Get pending delivery quantity for a job
  double getPendingDeliveryQuantityForJob(String materialCode, String jobNo) {
    final stock = getStockForMaterial(materialCode);
    if (stock != null && stock.jobDetails.containsKey(jobNo)) {
      return stock.jobDetails[jobNo]!.pendingDeliveryQuantity;
    }
    return 0.0;
  }

  // Get available quantity for a job
  double getAvailableQuantityForJob(String materialCode, String jobNo) {
    final stock = getStockForMaterial(materialCode);
    if (stock != null && stock.jobDetails.containsKey(jobNo)) {
      return stock.jobDetails[jobNo]!.availableQuantity;
    }
    return 0.0;
  }

  // Cancel pending delivery for a job
  Future<void> cancelPendingDelivery(
      String materialCode, String jobNo, double quantity) async {
    final stock = getStockForMaterial(materialCode);
    if (stock != null) {
      // Update job pending delivery if job exists
      if (stock.jobDetails.containsKey(jobNo)) {
        final jobDetails = stock.jobDetails[jobNo]!;
        
        // Remove pending delivery quantity
        jobDetails.removePendingDelivery(quantity);

        // Save to Firestore
        await _saveToFirestore(stock);

        // Save to Hive
        await stock.save();

        state = [..._stockBox.values];
      }
    }
  }

  // Update pending delivery quantity for a job
  Future<void> updatePendingDeliveryQuantity(
      String materialCode, String jobNo, double quantity) async {
    final stock = getStockForMaterial(materialCode);
    if (stock != null) {
      // Update job pending delivery if job exists
      if (stock.jobDetails.containsKey(jobNo)) {
        final jobDetails = stock.jobDetails[jobNo]!;
        
        // Check if we have enough available quantity
        if (jobDetails.availableQuantity >= quantity) {
          // Update pending delivery quantity
          jobDetails.addPendingDelivery(quantity);

          // Save to Firestore
          await _saveToFirestore(stock);

          // Save to Hive
          await stock.save();

          state = [..._stockBox.values];
        }
      }
    }
  }

  // Consume stock for a job
  Future<void> consumeStockForJob(
      String materialCode, String jobNo, double quantity) async {
    final stock = getStockForMaterial(materialCode);
    if (stock != null && stock.currentStock >= quantity) {
      stock.updateCurrentStock(stock.currentStock - quantity);

      // Update job consumption if job exists
      if (stock.jobDetails.containsKey(jobNo)) {
        final jobDetails = stock.jobDetails[jobNo]!;
        jobDetails.addConsumedQuantity(quantity);
        
        // If there was a pending delivery, remove it
        if (jobDetails.pendingDeliveryQuantity > 0) {
          jobDetails.removePendingDelivery(quantity);
        }
      }

      // Save to Firestore
      await _saveToFirestore(stock);

      // Save to Hive
      await stock.save();

      state = [..._stockBox.values];
    }
  }

  Future<void> refresh() async {
    try {
      await loadStock();
    } catch (e) {
      print('Error refreshing stock: $e');
      rethrow;
    }
  }

  // Update PR details from GRN
  void _updatePRDetailsFromGRN(StockMaintenance stock, InwardItem grnItem, String grnNo) {
    print('\nUpdating PR details for ${grnItem.materialCode}');
    
    // Process each PO and its PR quantities
    for (var poEntry in grnItem.prQuantities.entries) {
      final poNo = poEntry.key;
      final prMap = poEntry.value;
      if (prMap == null) continue;

      print('Processing PO: $poNo');
      
      // Create or update PO details
      stock.poDetails[poNo] ??= StockPODetails(
        poNo: poNo,
        poDate: '',  // This will be updated when we have PO date
        orderedQuantity: grnItem.orderedQty,
        receivedQuantity: 0.0,
        vendorId: stock.grnDetails[grnNo]?.vendorId ?? '',
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

        // Update PR received quantity
        stock.prDetails[prNo]!.receivedQuantity += prQty;
      }

      // Update total received quantity for PO
      stock.poDetails[poNo]!.receivedQuantity = stock.poDetails[poNo]!.receivedQuantities.values
          .expand((map) => map.values)
          .fold(0.0, (sum, qty) => sum + qty);
    }
  }
}
