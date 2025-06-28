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
      }

      if (mounted) {
        state = _stockBox.values.toList();
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
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
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

    // Get required boxes from providers
    final categoriesBox = _ref.read(categoryBoxProvider);
    final inspectionsBox = _ref.read(qualityInspectionBoxProvider);

    try {
      // Process each item in the GRN
      for (var item in grn.items) {
        print('\n--- Processing item: ${item.materialCode} ---');

        // Get or create stock record for this material
        var stock = _stockBox.values.firstWhere(
          (s) => s.materialCode == item.materialCode,
          orElse: () {
            print('Creating new stock record for ${item.materialCode}');
            return StockMaintenance(
              materialCode: item.materialCode,
              materialDescription: item.materialDescription,
              unit: item.unit,
              storageLocation: '',
              rackNumber: '',
            );
          },
        );

        if (!_stockBox.values.contains(stock)) {
          print('Adding new stock for ${item.materialCode}');
          await _stockBox.add(stock);
          stock = _stockBox.values.firstWhere(
            (s) => s.materialCode == item.materialCode,
            orElse: () {
              throw Exception('Failed to add new stock record');
            },
          );
        }

        // Get the category settings
        final material = _ref.read(materialBoxProvider).values.firstWhere(
              (m) => m.partNo == item.materialCode,
              orElse: () => MaterialItem(
                slNo: item.materialCode,
                description: item.materialDescription,
                partNo: item.materialCode,
                unit: item.unit,
                category: 'General',
                subCategory: '',
              ),
            );

        // Get the category settings
        final category = categoriesBox.values.firstWhere(
          (c) => c.name == material.category,
          orElse: () => Category(name: material.category),
        );

        // Get PO list to find rates
        final poList = _ref.read(purchaseOrderListProvider);

        // Add or update GRN details
        stock.grnDetails[grn.grnNo] = StockGRNDetails(
          grnNo: grn.grnNo,
          grnDate: grn.grnDate,
          receivedQuantity: item.receivedQty,
          acceptedQuantity: item.acceptedQty,
          rejectedQuantity: item.rejectedQty,
          vendorId:
              grn.supplierName.isNotEmpty ? grn.supplierName : 'Unknown Vendor',
          rate: double.tryParse(item.costPerUnit) ??
              item.prQuantities.entries.fold<double>(0.0, (rate, entry) {
                final po = poList.firstWhere(
                  (p) => p.poNo == entry.key,
                  orElse: () => PurchaseOrder(
                    poNo: entry.key,
                    poDate: '',
                    supplierName: '',
                    transport: '',
                    deliveryRequirements: '',
                    items: [],
                    total: 0.0,
                    igst: 0.0,
                    cgst: 0.0,
                    sgst: 0.0,
                    grandTotal: 0.0,
                  ),
                );
                final poItem = po.items.firstWhere(
                  (i) => i.materialCode == item.materialCode,
                  orElse: () => POItem(
                    materialCode: item.materialCode,
                    materialDescription: item.materialDescription,
                    unit: item.unit,
                    quantity: '0',
                    costPerUnit: '0',
                    totalCost: '0',
                    saleRate: '0',
                    marginPerUnit: '0',
                    totalMargin: '0',
                  ),
                );
                return double.tryParse(poItem.costPerUnit) ?? 0.0;
              }),
        );

        // Update PR details
        _updatePRDetailsFromGRN(stock, item, grn.grnNo);

        // Calculate total stock from all GRNs
        double totalCurrentStock = 0.0;
        double totalUnderInspection = 0.0;

        for (var grnEntry in stock.grnDetails.entries) {
          final grnDetail = grnEntry.value;
          if (!category.requiresQualityCheck) {
            // For materials that don't require quality check, set accepted quantity equal to received quantity
            grnDetail.acceptedQuantity = grnDetail.receivedQuantity;
            grnDetail.rejectedQuantity = 0.0;
            totalCurrentStock += grnDetail.receivedQuantity;

            // Update job details for non-QC items
            for (var poEntry in item.prQuantities.entries) {
              final poNo = poEntry.key;
              final prMap = poEntry.value;
              if (prMap == null) continue;

              for (var prEntry in prMap.entries) {
                final prNo = prEntry.key;
                final jobNo = item.prJobNumbers[poNo]?[prNo];
                if (jobNo != null && jobNo != 'General') {
                  // Create or update job details
                  stock.jobDetails[jobNo] ??= StockJobDetails(
                    jobNo: jobNo,
                    allocatedQuantity: 0.0,
                    consumedQuantity: 0.0,
                    prNo: prNo,
                  );
                  stock.jobDetails[jobNo]!.allocatedQuantity =
                      stock.prDetails[prNo]?.receivedQuantity ?? 0.0;
                }
              }
            }
          } else {
            // Check if there's a completed inspection for this GRN
            final inspections = inspectionsBox.values
                .where((insp) =>
                    insp.grnNo == grnEntry.key &&
                    insp.status.startsWith('Completed'))
                .toList();

            if (inspections.isNotEmpty) {
              // Sum up accepted quantities from all inspections for this GRN
              double totalAcceptedQty = 0.0;
              double totalRejectedQty = 0.0;

              for (var inspection in inspections) {
                // Only process completed inspections
                if (inspection.status == 'Approved' ||
                    inspection.status == 'Completed') {
                  for (var inspItem in inspection.items) {
                    if (inspItem.materialCode == item.materialCode) {
                      // Get GRN-specific quantities
                      totalAcceptedQty +=
                          inspItem.getAcceptedQuantityForGRN(grnEntry.key);
                      totalRejectedQty +=
                          inspItem.getRejectedQuantityForGRN(grnEntry.key);

                      // Update GRN details with inspection results
                      grnDetail.acceptedQuantity = totalAcceptedQty;
                      grnDetail.rejectedQuantity = totalRejectedQty;

                      // Move accepted quantity from under inspection to current stock
                      if (totalAcceptedQty > 0) {
                        totalCurrentStock += totalAcceptedQty;
                        totalUnderInspection = math.max(
                            0,
                            grnDetail.receivedQuantity -
                                (totalAcceptedQty + totalRejectedQty));
                      }
                    }
                  }
                }
              }
            } else {
              // If no completed inspection, all received quantity is under inspection
              totalUnderInspection += grnDetail.receivedQuantity;
            }
          }
        }

        print('New Current Stock: $totalCurrentStock');
        print('New Under Inspection: $totalUnderInspection');

        // Update the stock quantities
        stock.updateCurrentStock(totalCurrentStock);
        stock.updateStockUnderInspection(totalUnderInspection);

        // After updating the stock object, update both Firestore and Hive
        final querySnapshot = await _firestore
            .collection('stockMaintenance')
            .where('materialCode', isEqualTo: stock.materialCode)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docRef = querySnapshot.docs.first.reference;
          final data = _convertToMap(stock);
          data['lastUpdated'] = FieldValue.serverTimestamp();
          data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
          await docRef.update(data);
        } else {
          // Create new document if it doesn't exist
          final data = _convertToMap(stock);
          data['lastUpdated'] = FieldValue.serverTimestamp();
          data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
          await _firestore.collection('stockMaintenance').add(data);
        }

        // Update in Hive
        final index = _stockBox.values.toList().indexWhere((s) => s.materialCode == stock.materialCode);
        if (index != -1) {
          await _stockBox.putAt(index, stock);
        }
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
      'currentStock': stock.currentStock,
      'stockUnderInspection': stock.stockUnderInspection,
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
            'issuedQuantity': value.issuedQuantity,
            'issuedQuantities': value.issuedQuantities,
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
            'prNo': value.prNo,
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

  // Update stock based on inspection status change
  Future<void> updateStockFromInspection(QualityInspection inspection) async {
    print(
        '\n=== Debug: Starting Stock Update from Inspection ${inspection.inspectionNo} ===');
    print('GRN Number: ${inspection.grnNo}');

    // Get required boxes from providers
    final inwardBox = _ref.read(storeInwardBoxProvider);

    try {
      // Get the GRN
      print('Looking for GRN in inward box...');
      final grn = inwardBox.values.firstWhere(
        (gr) => gr.grnNo == inspection.grnNo,
        orElse: () {
          print(
              'Available GRNs: ${inwardBox.values.map((g) => g.grnNo).join(", ")}');
          throw Exception('GRN ${inspection.grnNo} not found');
        },
      );
      print('Found GRN: ${grn.grnNo}');

      // Process each inspected item
      for (var inspectionItem in inspection.items) {
        print('\n--- Processing item: ${inspectionItem.materialCode} ---');
        try {
          print(
              'GRN Quantities available: ${inspectionItem.grnQuantities.keys.join(", ")}');
          print('Looking for GRN ${inspection.grnNo} in quantities...');

          // Get or create stock record for this material
          var stock = _stockBox.values.firstWhere(
            (s) => s.materialCode == inspectionItem.materialCode,
            orElse: () {
              print(
                  'Creating new stock record for ${inspectionItem.materialCode}');
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
              print(
                  'Available GRN entries: ${inspectionItem.grnQuantities.keys.join(", ")}');
              throw Exception(
                  'GRN ${inspection.grnNo} not found in quantities');
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
            );
          } else {
            // Update existing GRN details
            final grnDetail = stock.grnDetails[grnNo]!;

            // Handle recheck cases
            if (grnQty.usageDecision == 'Accepted After 100% Recheck') {
              // For accepted after recheck, move all quantity to accepted
              grnDetail.acceptedQuantity = grnQty.receivedQty;
              grnDetail.rejectedQuantity = 0.0;

              // Update current stock and under inspection
              stock.updateCurrentStock(stock.currentStock + grnQty.receivedQty);
              stock.updateStockUnderInspection(
                  math.max(0, stock.stockUnderInspection - grnQty.receivedQty));

              // Update PR and PO quantities
              for (var poEntry in grn.items.first.prQuantities.entries) {
                final poNo = poEntry.key;
                final prMap = poEntry.value;
                if (prMap == null) continue;

                for (var prEntry in prMap.entries) {
                  final prNo = prEntry.key;
                  final qty = prEntry.value;

                  // Update PO details
                  if (stock.poDetails.containsKey(poNo)) {
                    stock.poDetails[poNo]!
                        .addReceivedQuantity(grnNo, prNo, qty);
                  }

                  // Update PR details
                  if (stock.prDetails.containsKey(prNo)) {
                    stock.prDetails[prNo]!.receivedQuantity = qty;
                  }
                }
              }
            } else if (grnQty.usageDecision ==
                'Partially Accepted After 100% Recheck') {
              // For partial acceptance after recheck
              grnDetail.acceptedQuantity = grnQty.acceptedQty;
              grnDetail.rejectedQuantity = grnQty.rejectedQty;

              // Update current stock and under inspection
              stock.updateCurrentStock(stock.currentStock + grnQty.acceptedQty);
              stock.updateStockUnderInspection(
                  math.max(0, stock.stockUnderInspection - grnQty.receivedQty));

              // Update PR and PO quantities using the GRN item's PR quantities
              for (var poEntry in grnItem.prQuantities.entries) {
                final poNo = poEntry.key;
                final prMap = poEntry.value;
                if (prMap == null) continue;

                for (var prEntry in prMap.entries) {
                  final prNo = prEntry.key;
                  final qty = prEntry.value;

                  // Update PO details
                  if (stock.poDetails.containsKey(poNo)) {
                    stock.poDetails[poNo]!
                        .addReceivedQuantity(grnNo, prNo, qty);
                  }

                  // Update PR details
                  if (stock.prDetails.containsKey(prNo)) {
                    stock.prDetails[prNo]!.receivedQuantity = qty;
                  }
                }
              }
            } else {
              // For normal cases, update quantities as is
              grnDetail.acceptedQuantity = grnQty.acceptedQty;
              grnDetail.rejectedQuantity = grnQty.rejectedQty;
            }
          }

          // Update PO and PR quantities based on acceptance
          for (var poEntry in grnItem.prQuantities.entries) {
            final poNo = poEntry.key;
            final prMap = poEntry.value;
            if (prMap == null) continue;

            // Ensure PO details exist
            stock.poDetails[poNo] ??= StockPODetails(
              poNo: poNo,
              poDate: grn.poDate,
              orderedQuantity: 0.0,
              receivedQuantity: 0.0,
              vendorId: grn.supplierName,
              rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
            );

            // Calculate acceptance ratio for this GRN
            double acceptanceRatio = grnQty.receivedQty > 0
                ? grnQty.acceptedQty / grnQty.receivedQty
                : 0.0;

            for (var prEntry in prMap.entries) {
              final prNo = prEntry.key;
              final originalQty = prEntry.value;

              // Calculate accepted quantity for this PR
              double prAcceptedQty = originalQty * acceptanceRatio;

              print('\nUpdating quantities for PO: $poNo, PR: $prNo');
              print('Original Qty: $originalQty');
              print('Acceptance Ratio: $acceptanceRatio');
              print('Accepted Qty: $prAcceptedQty');

              // Update PO details with PR quantities
              if (!stock.poDetails[poNo]!.receivedQuantities
                  .containsKey(grnNo)) {
                stock.poDetails[poNo]!.receivedQuantities[grnNo] = {};
              }
              stock.poDetails[poNo]!.receivedQuantities[grnNo]![prNo] =
                  prAcceptedQty;

              // Ensure PR details exist
              stock.prDetails[prNo] ??= StockPRDetails(
                prNo: prNo,
                prDate: '',
                requestedQuantity: 0.0,
                orderedQuantity: originalQty,
                receivedQuantity: 0.0,
                jobNo: grnItem.prJobNumbers[poNo]?[prNo] ?? 'General',
              );

              // Update PR details with total accepted quantity from all GRNs
              double totalPrAcceptedQty = 0.0;
              for (var poDetail in stock.poDetails.values) {
                for (var grnQtys in poDetail.receivedQuantities.values) {
                  totalPrAcceptedQty += grnQtys[prNo] ?? 0.0;
                }
              }
              stock.prDetails[prNo]!.receivedQuantity = totalPrAcceptedQty;

              // Update job details if not General
              final jobNo = grnItem.prJobNumbers[poNo]?[prNo];
              if (jobNo != null && jobNo != 'General') {
                stock.jobDetails[jobNo] ??= StockJobDetails(
                  jobNo: jobNo,
                  allocatedQuantity: 0.0,
                  consumedQuantity: 0.0,
                  prNo: prNo,
                );
                stock.jobDetails[jobNo]!.allocatedQuantity = totalPrAcceptedQty;
              }
            }

            // Update total received quantity for PO
            double totalPoAcceptedQty = 0.0;
            for (var grnQtys
                in stock.poDetails[poNo]!.receivedQuantities.values) {
              totalPoAcceptedQty +=
                  grnQtys.values.fold(0.0, (sum, qty) => sum + qty);
            }
            stock.poDetails[poNo]!.receivedQuantity = totalPoAcceptedQty;
          }

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

          // Save stock
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

  // Consume stock for a job
  Future<void> consumeStockForJob(
      String materialCode, String jobNo, double quantity) async {
    final stock = getStockForMaterial(materialCode);
    if (stock != null && stock.currentStock >= quantity) {
      stock.updateCurrentStock(stock.currentStock - quantity);

      // Update job consumption if job exists
      if (stock.jobDetails.containsKey(jobNo)) {
        final jobDetails = stock.jobDetails[jobNo]!;
        jobDetails.consumedQuantity += quantity;
      }

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
  void _updatePRDetailsFromGRN(StockMaintenance stock, InwardItem item, String grnNo) {
    print('\nUpdating PR details for ${item.materialCode}');
    
    // Process each PO and its PRs
    for (var poEntry in item.prQuantities.entries) {
      final poNo = poEntry.key;
      final prMap = poEntry.value;
      if (prMap == null) continue;

      for (var prEntry in prMap.entries) {
        final prNo = prEntry.key;
        final qty = prEntry.value;
        final jobNo = item.prJobNumbers[poNo]?[prNo] ?? 'General';

        print('Processing PR: $prNo, Job: $jobNo, Quantity: $qty');

        // Create or update PR details
        stock.prDetails[prNo] ??= StockPRDetails(
          prNo: prNo,
          prDate: DateTime.now().toString().split(' ')[0],
          requestedQuantity: qty,
          orderedQuantity: qty,
          receivedQuantity: 0.0,
          jobNo: jobNo,
        );

        // Update received quantity
        final grnDetail = stock.grnDetails[grnNo]!;
        final acceptanceRatio = grnDetail.receivedQuantity > 0 
          ? grnDetail.acceptedQuantity / grnDetail.receivedQuantity 
          : 0.0;
        final prAcceptedQty = qty * acceptanceRatio;

        stock.prDetails[prNo]!.receivedQuantity += prAcceptedQty;

        print('Updated PR details:');
        print('  Received Quantity: ${stock.prDetails[prNo]!.receivedQuantity}');
        print('  Issued Quantity: ${stock.prDetails[prNo]!.issuedQuantity}');
        print('  Job No: ${stock.prDetails[prNo]!.jobNo}');
      }
    }
  }
}
