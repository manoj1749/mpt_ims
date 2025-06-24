// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;
import '../models/stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/quality_inspection.dart';
import '../models/material_item.dart';
import '../models/category.dart';
import '../models/purchase_order.dart';
import '../provider/purchase_order.dart';
import '../provider/material_provider.dart';
import '../provider/category_provider.dart';
import '../provider/quality_inspection_provider.dart';
import '../provider/store_inward_provider.dart';
import '../models/po_item.dart';

final stockMaintenanceBoxProvider = Provider<Box<StockMaintenance>>((ref) {
  throw UnimplementedError();
});

final stockMaintenanceProvider =
    NotifierProvider<StockMaintenanceNotifier, List<StockMaintenance>>(
  () => StockMaintenanceNotifier(),
);

class StockMaintenanceNotifier extends Notifier<List<StockMaintenance>> {
  late Box<StockMaintenance> _stockBox;

  @override
  List<StockMaintenance> build() {
    _stockBox = ref.watch(stockMaintenanceBoxProvider);
    return _stockBox.values.toList();
  }

  // Initialize stock for a material
  Future<void> initializeStock(MaterialItem material) async {
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
      await _stockBox.add(existingStock);
      state = [...state, existingStock];
    }
  }

  // Update stock from GRN
  Future<void> updateStockFromGRN(StoreInward grn) async {
    print('\n=== Debug: Updating Stock from GRN ${grn.grnNo} ===');

    // Get required boxes from providers
    final materialsBox = ref.read(materialBoxProvider);
    final categoriesBox = ref.read(categoryBoxProvider);
    final inspectionsBox = ref.read(qualityInspectionBoxProvider);

    try {
      for (var item in grn.items) {
        print('\nProcessing item: ${item.materialCode}');
        print('Received Qty: ${item.receivedQty}');
        print('Accepted Qty: ${item.acceptedQty}');
        print('Rejected Qty: ${item.rejectedQty}');

        // First check if stock exists and add it if it doesn't
        var stock = _stockBox.values.firstWhere(
          (s) => s.materialCode == item.materialCode,
          orElse: () => StockMaintenance(
            materialCode: item.materialCode,
            materialDescription: item.materialDescription,
            unit: item.unit,
            storageLocation: '',
            rackNumber: '',
          ),
        );

        // If stock doesn't exist in box, add it first
        if (!_stockBox.values.contains(stock)) {
          print('Adding new stock for ${item.materialCode}');
          await _stockBox.add(stock);
          // Get the newly added stock from the box
          stock = _stockBox.values
              .firstWhere((s) => s.materialCode == item.materialCode);
        }

        print('Current Stock before update: ${stock.currentStock}');
        print('Under Inspection before update: ${stock.stockUnderInspection}');

        // Get the material's category to check if inspection is required
        final material = materialsBox.values.firstWhere(
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
        final poList = ref.read(purchaseOrderListProvider);

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
                return double.tryParse(poItem.costPerUnit) ?? rate;
              }),
        );

        // --- NEW: Update PO and PR mapping for this GRN ---
        for (var poEntry in item.prQuantities.entries) {
          final poNo = poEntry.key;
          final prMap = poEntry.value;
          if (prMap == null) continue;

          // Update PO details
          final po = poList.firstWhere(
            (p) => p.poNo == poNo,
            orElse: () => PurchaseOrder(
              poNo: poNo,
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
          final poDate = po.poDate;
          final vendorId =
              grn.supplierName.isNotEmpty ? grn.supplierName : 'Unknown Vendor';
          final rate = double.tryParse(item.costPerUnit) ?? 0.0;

          // Ensure PO details exist
          stock.poDetails[poNo] ??= StockPODetails(
            poNo: poNo,
            poDate: poDate,
            orderedQuantity: 0.0,
            receivedQuantity: 0.0,
            vendorId: vendorId,
            rate: rate,
          );

          for (var prEntry in prMap.entries) {
            final prNo = prEntry.key;
            final qty = prEntry.value;

            // Add received quantity mapping
            stock.poDetails[poNo]!.addReceivedQuantity(grn.grnNo, prNo, qty);

            // Ensure PR details exist
            stock.prDetails[prNo] ??= StockPRDetails(
              prNo: prNo,
              prDate: '',
              requestedQuantity: 0.0,
              orderedQuantity: 0.0,
              receivedQuantity: 0.0,
              jobNo: item.prJobNumbers[poNo]?[prNo] ?? 'General',
            );
            // Always update the job number, even for existing PR details
            stock.prDetails[prNo]!.jobNo =
                item.prJobNumbers[poNo]?[prNo] ?? 'General';
            stock.prDetails[prNo]!.receivedQuantity =
                (stock.prDetails[prNo]!.receivedQuantity) + qty;
          }
        }
        // --- END NEW ---

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

                      // Update PO and PR quantities based on acceptance
                      for (var poEntry in item.prQuantities.entries) {
                        final poNo = poEntry.key;
                        final prMap = poEntry.value;
                        if (prMap == null) continue;

                        // Calculate acceptance ratio for this GRN
                        double acceptanceRatio =
                            totalAcceptedQty / grnDetail.receivedQuantity;

                        for (var prEntry in prMap.entries) {
                          final prNo = prEntry.key;
                          final originalQty = prEntry.value;

                          // Calculate accepted quantity for this PR
                          double prAcceptedQty = originalQty * acceptanceRatio;

                          // Update PO details
                          if (stock.poDetails.containsKey(poNo)) {
                            stock.poDetails[poNo]!.addReceivedQuantity(
                                grnEntry.key, prNo, prAcceptedQty);
                          }

                          // Update PR details
                          if (stock.prDetails.containsKey(prNo)) {
                            stock.prDetails[prNo]!.receivedQuantity =
                                prAcceptedQty;
                          }
                        }
                      }
                    }
                  }
                }
              }
            } else {
              // No completed inspection, keep quantity under inspection
              totalUnderInspection += grnDetail.receivedQuantity;
            }
          }
        }

        print('Updating stock quantities:');
        print('New Current Stock: $totalCurrentStock');
        print('New Under Inspection: $totalUnderInspection');

        // Update the stock quantities
        stock.updateCurrentStock(totalCurrentStock);
        stock.updateStockUnderInspection(totalUnderInspection);

        // Save to Hive
        await stock.save();
      }

      // Update state
      state = [..._stockBox.values];
    } catch (e) {
      print('Error updating stock from GRN: $e');
      rethrow;
    }
  }

  // Update stock based on inspection status change
  Future<void> updateStockFromInspection(QualityInspection inspection) async {
    print(
        '\n=== Debug: Updating Stock from Inspection ${inspection.inspectionNo} ===');

    // Get required boxes from providers
    final inwardBox = ref.read(storeInwardBoxProvider);

    try {
      // Get the GRN
      final grn = inwardBox.values.firstWhere(
        (gr) => gr.grnNo == inspection.grnNo,
        orElse: () => throw Exception('GRN not found'),
      );

      // Process each inspected item
      for (var inspectionItem in inspection.items) {
        print('\nProcessing item: ${inspectionItem.materialCode}');

        // Get or create stock record for this material
        var stock = _stockBox.values.firstWhere(
          (s) => s.materialCode == inspectionItem.materialCode,
          orElse: () => StockMaintenance(
            materialCode: inspectionItem.materialCode,
            materialDescription: inspectionItem.materialDescription,
            unit: inspectionItem.unit,
            storageLocation: '',
            rackNumber: '',
          ),
        );

        if (!_stockBox.values.contains(stock)) {
          print('Adding new stock for ${inspectionItem.materialCode}');
          await _stockBox.add(stock);
          stock = _stockBox.values.firstWhere(
            (s) => s.materialCode == inspectionItem.materialCode,
          );
        }

        // Get the selected GRN's quantities
        final selectedGRN = inspectionItem.grnQuantities.entries
            .firstWhere((entry) => entry.value.isSelected == true);
        final grnNo = selectedGRN.key;
        final grnQty = selectedGRN.value;

        print('Selected GRN: $grnNo');
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
                  stock.poDetails[poNo]!.addReceivedQuantity(grnNo, prNo, qty);
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

            // Calculate acceptance ratio for PR distribution
            final acceptanceRatio = grnQty.acceptedQty / grnQty.receivedQty;

            // Update PR and PO quantities
            for (var poEntry in grn.items.first.prQuantities.entries) {
              final poNo = poEntry.key;
              final prMap = poEntry.value;
              if (prMap == null) continue;

              for (var prEntry in prMap.entries) {
                final prNo = prEntry.key;
                final originalQty = prEntry.value;
                final acceptedQty = originalQty * acceptanceRatio;

                // Update PO details
                if (stock.poDetails.containsKey(poNo)) {
                  stock.poDetails[poNo]!
                      .addReceivedQuantity(grnNo, prNo, acceptedQty);
                }

                // Update PR details
                if (stock.prDetails.containsKey(prNo)) {
                  stock.prDetails[prNo]!.receivedQuantity = acceptedQty;
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
            if (!stock.poDetails[poNo]!.receivedQuantities.containsKey(grnNo)) {
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
}
