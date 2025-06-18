// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/material_item.dart';
import '../models/category.dart';
import '../models/quality_inspection.dart';
import '../provider/purchase_order.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';
import 'dart:math' as math;

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

    // Ensure all required boxes are open
    final materialsBox = await Hive.openBox<MaterialItem>('materials');
    final categoriesBox = await Hive.openBox<Category>('categories');
    final inspectionsBox =
        await Hive.openBox<QualityInspection>('quality_inspections');

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
            );
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
    } finally {
      // Close the boxes we opened
      await materialsBox.close();
      await categoriesBox.close();
      await inspectionsBox.close();
    }
  }

  // Update stock based on inspection status change
  Future<void> updateStockFromInspection(QualityInspection inspection) async {
    print(
        '\n=== Debug: Updating Stock from Inspection ${inspection.inspectionNo} ===');

    // Only process completed inspections
    if (!inspection.status.startsWith('Completed')) {
      print('Inspection not completed, skipping stock update');
      return;
    }

    // Ensure all required boxes are open
    final inwardBox = await Hive.openBox<StoreInward>('store_inwards');
    final inspectionsBox =
        await Hive.openBox<QualityInspection>('quality_inspections');

    try {
      // Get the GRN
      final grn = inwardBox.values.firstWhere(
        (gr) => gr.grnNo == inspection.grnNo,
        orElse: () => StoreInward(
          grnNo: '',
          grnDate: '',
          supplierName: '',
          poNo: '',
          poDate: '',
          invoiceNo: '',
          invoiceDate: '',
          invoiceAmount: 0.0,
          receivedBy: '',
          checkedBy: '',
          items: [],
        ),
      );

      if (grn.grnNo.isEmpty) {
        print('GRN not found: ${inspection.grnNo}');
        return;
      }

      // Process each inspected item
      for (var inspectionItem in inspection.items) {
        print('\nProcessing item: ${inspectionItem.materialCode}');
        print('Inspected Qty: ${inspectionItem.receivedQty}');
        print('Accepted Qty: ${inspectionItem.acceptedQty}');
        print('Rejected Qty: ${inspectionItem.rejectedQty}');

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

        // Find all GRNs for this PO and material
        final allGrnsForPO = inwardBox.values
            .where((gr) =>
                gr.poNo == grn.poNo &&
                gr.items.any(
                    (item) => item.materialCode == inspectionItem.materialCode))
            .toList();

        // Calculate total received for this PO/material
        double totalReceivedForPO = 0.0;
        for (var gr in allGrnsForPO) {
          InwardItem? item;
          try {
            item = gr.items.firstWhere(
                (item) => item.materialCode == inspectionItem.materialCode);
          } catch (e) {
            item = null;
          }
          totalReceivedForPO += (item != null) ? item.receivedQty : 0.0;
        }

        // Calculate total accepted for this PO/material (from inspection)
        double totalAcceptedForPO = inspection.items
            .where((item) => item.materialCode == inspectionItem.materialCode)
            .fold(
                0.0,
                (sum, item) =>
                    sum + (item.poQuantities[grn.poNo]?.acceptedQty ?? 0.0));

        // --- FIX: Accumulate PR/General split across all GRNs, only once per PR/General ---
        Map<String, double> prAcceptedTotals = {};
        Map<String, double> prRejectedTotals = {};
        for (var gr in allGrnsForPO) {
          final grnNo = gr.grnNo;
          final grnItem = gr.items.firstWhere(
              (item) => item.materialCode == inspectionItem.materialCode);
          double grnShare = (grnItem.receivedQty > 0 && totalReceivedForPO > 0)
              ? (grnItem.receivedQty / totalReceivedForPO)
              : 0.0;
          double grnAccepted = grnShare * totalAcceptedForPO;
          double grnRejected = grnShare *
              (inspectionItem.poQuantities[gr.poNo]?.rejectedQty ?? 0.0);

          // Update grnDetails for this GRN
          if (stock.grnDetails.containsKey(grnNo)) {
            final grnDetails = stock.grnDetails[grnNo]!;
            grnDetails.acceptedQuantity = grnAccepted;
            grnDetails.rejectedQuantity = grnRejected;
          } else {
            stock.grnDetails[grnNo] = StockGRNDetails(
              grnNo: grnNo,
              grnDate: gr.grnDate,
              receivedQuantity: grnItem.receivedQty,
              acceptedQuantity: grnAccepted,
              rejectedQuantity: grnRejected,
              vendorId: gr.supplierName,
              rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
            );
          }

          // Now split grnAccepted into PR/General as per prQuantities mapping for this GRN
          for (var poEntry in grnItem.prQuantities.entries) {
            final poNo = poEntry.key;
            final prMap = poEntry.value;
            if (prMap == null) continue;

            // Ensure PO details exist
            stock.poDetails[poNo] ??= StockPODetails(
              poNo: poNo,
              poDate: gr.poDate,
              orderedQuantity: 0.0,
              receivedQuantity: 0.0,
              vendorId: gr.supplierName,
              rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
            );

            for (var prEntry in prMap.entries) {
              final prNo = prEntry.key;
              final prQty = prEntry.value;

              // Proportion of this PR in this GRN
              double prShare = (grnItem.receivedQty > 0)
                  ? (prQty / grnItem.receivedQty)
                  : 0.0;
              double prAcceptedQty = prShare * grnAccepted;
              double prRejectedQty = prShare * grnRejected;

              // Update PO receivedQuantities mapping for this GRN and PR (only accepted)
              stock.poDetails[poNo]!
                  .addReceivedQuantity(grnNo, prNo, prAcceptedQty);
              // Ensure PR details exist
              stock.prDetails[prNo] ??= StockPRDetails(
                prNo: prNo,
                prDate: '',
                requestedQuantity: 0.0,
                orderedQuantity: 0.0,
                receivedQuantity: 0.0,
              );
              // Accumulate accepted/rejected for this PR across all GRNs
              prAcceptedTotals[prNo] =
                  (prAcceptedTotals[prNo] ?? 0.0) + prAcceptedQty;
              prRejectedTotals[prNo] =
                  (prRejectedTotals[prNo] ?? 0.0) + prRejectedQty;
            }
          }
        }
        // Set PR receivedQuantity as total accepted only
        prAcceptedTotals.forEach((prNo, totalAccepted) {
          stock.prDetails[prNo]!.receivedQuantity = totalAccepted;
        });
        // --- END FIX ---

        // --- FIX: Recalculate currentStock as sum of all PR/General accepted quantities ---
        double totalCurrentStock = 0.0;
        for (var prDetail in stock.prDetails.values) {
          totalCurrentStock += prDetail.receivedQuantity;
        }
        stock.updateCurrentStock(totalCurrentStock);
        // --- END FIX ---

        // Calculate total stock
        double totalUnderInspection = 0.0;

        for (var grnEntry in stock.grnDetails.entries) {
          final grnDetail = grnEntry.value;
          final inspections = inspectionsBox.values
              .where((insp) =>
                  insp.grnNo == grnEntry.key &&
                  insp.status.startsWith('Completed'))
              .toList();

          if (inspections.isNotEmpty) {
            // Sum up accepted quantities from completed inspections
            double totalAcceptedQty = 0.0;
            for (var insp in inspections) {
              for (var item in insp.items) {
                if (item.materialCode == inspectionItem.materialCode) {
                  totalAcceptedQty += item.acceptedQty;
                }
              }
            }
            totalUnderInspection += grnDetail.receivedQuantity -
                (totalAcceptedQty + grnDetail.rejectedQuantity);
          } else {
            // No completed inspection, keep quantity under inspection
            totalUnderInspection += grnDetail.receivedQuantity -
                (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
          }
        }

        print('Updating stock quantities:');
        print('New Current Stock: $totalCurrentStock');
        print('New Under Inspection: $totalUnderInspection');

        // Update stock quantities
        stock.updateCurrentStock(totalCurrentStock);
        stock.updateStockUnderInspection(totalUnderInspection);

        // Save stock
        await stock.save();
      }

      // Update GRN status
      grn.updateStatus();
      final grnIndex = inwardBox.values.toList().indexOf(grn);
      await inwardBox.putAt(grnIndex, grn);

      // Update state
      state = [..._stockBox.values];
    } finally {
      // Close the boxes we opened
      await inwardBox.close();
      await inspectionsBox.close();
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
