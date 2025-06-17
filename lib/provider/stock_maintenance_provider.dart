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
              // Sum up accepted quantities from all inspections
              double totalAcceptedQty = 0.0;
              for (var inspection in inspections) {
                for (var inspItem in inspection.items) {
                  if (inspItem.materialCode == item.materialCode) {
                    totalAcceptedQty += inspItem.acceptedQty;
                  }
                }
              }
              totalCurrentStock += totalAcceptedQty;
              totalUnderInspection += grnDetail.receivedQuantity -
                  (totalAcceptedQty + grnDetail.rejectedQuantity);
            } else {
              // No completed inspection, keep quantity under inspection
              totalUnderInspection += grnDetail.receivedQuantity -
                  (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
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

        // Find corresponding GRN item
        final grnItem = grn.items.firstWhere(
          (item) => item.materialCode == inspectionItem.materialCode,
          orElse: () => InwardItem(
            materialCode: '',
            materialDescription: '',
            unit: '',
            orderedQty: 0,
            receivedQty: 0,
            acceptedQty: 0,
            rejectedQty: 0,
            costPerUnit: '0',
          ),
        );

        if (grnItem.materialCode.isEmpty) {
          print(
              'GRN item not found for material: ${inspectionItem.materialCode}');
          continue;
        }

        // Get or create stock record
        var stock = _stockBox.values.firstWhere(
          (s) => s.materialCode == inspectionItem.materialCode,
          orElse: () => StockMaintenance(
            materialCode: inspectionItem.materialCode,
            materialDescription: grnItem.materialDescription,
            unit: grnItem.unit,
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

        // Update GRN details in stock
        if (stock.grnDetails.containsKey(grn.grnNo)) {
          final grnDetails = stock.grnDetails[grn.grnNo]!;
          grnDetails.acceptedQuantity = inspectionItem.acceptedQty;
          grnDetails.rejectedQuantity = inspectionItem.rejectedQty;
        } else {
          stock.grnDetails[grn.grnNo] = StockGRNDetails(
            grnNo: grn.grnNo,
            grnDate: grn.grnDate,
            receivedQuantity: inspectionItem.receivedQty,
            acceptedQuantity: inspectionItem.acceptedQty,
            rejectedQuantity: inspectionItem.rejectedQty,
            vendorId: grn.supplierName,
            rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
          );
        }

        // --- FIX: Use grnQuantities for per-GRN accepted/rejected split ---
        Map<String, double> prAcceptedTotals = {};
        Map<String, double> prRejectedTotals = {};
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

          for (var prEntry in prMap.entries) {
            final prNo = prEntry.key;
            final prQty = prEntry.value;

            // Use the accepted/rejected for this GRN from grnQuantities
            double grnAccepted = 0.0;
            double grnRejected = 0.0;
            if (inspectionItem.grnQuantities.containsKey(grn.grnNo)) {
              grnAccepted = inspectionItem.grnQuantities[grn.grnNo]?.acceptedQty ?? 0.0;
              grnRejected = inspectionItem.grnQuantities[grn.grnNo]?.rejectedQty ?? 0.0;
            }
            double prAcceptedQty = 0.0;
            double prRejectedQty = 0.0;
            if (grnItem.receivedQty > 0) {
              prAcceptedQty = (prQty / grnItem.receivedQty) * grnAccepted;
              prRejectedQty = (prQty / grnItem.receivedQty) * grnRejected;
            }
            // Update PO receivedQuantities mapping for this GRN and PR (only accepted)
            stock.poDetails[poNo]!.addReceivedQuantity(grn.grnNo, prNo, prAcceptedQty);
            // Ensure PR details exist
            stock.prDetails[prNo] ??= StockPRDetails(
              prNo: prNo,
              prDate: '',
              requestedQuantity: 0.0,
              orderedQuantity: 0.0,
              receivedQuantity: 0.0,
            );
            // Sum accepted/rejected for this PR across all GRNs
            prAcceptedTotals[prNo] = (prAcceptedTotals[prNo] ?? 0.0) + prAcceptedQty;
            prRejectedTotals[prNo] = (prRejectedTotals[prNo] ?? 0.0) + prRejectedQty;
          }
        }
        // Set PR receivedQuantity as total accepted only
        prAcceptedTotals.forEach((prNo, totalAccepted) {
          stock.prDetails[prNo]!.receivedQuantity = totalAccepted;
        });
        // --- END FIX ---

        // Calculate total stock
        double totalCurrentStock = 0.0;
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
            totalCurrentStock += totalAcceptedQty;
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
