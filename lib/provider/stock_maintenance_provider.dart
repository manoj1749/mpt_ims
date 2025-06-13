import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/material_item.dart';
import '../models/category.dart';

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
    
    for (var item in grn.items) {
      print('\nProcessing item: ${item.materialCode}');
      print('Received Qty: ${item.receivedQty}');
      print('Accepted Qty: ${item.acceptedQty}');
      print('Rejected Qty: ${item.rejectedQty}');
      
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

      print('Current Stock before update: ${stock.currentStock}');
      print('Under Inspection before update: ${stock.stockUnderInspection}');

      // Create GRN details
      final grnDetails = StockGRNDetails(
        grnNo: grn.grnNo,
        grnDate: grn.grnDate,
        receivedQuantity: item.receivedQty,
        acceptedQuantity: item.acceptedQty,
        rejectedQuantity: item.rejectedQty,
        vendorId: grn.supplierName,
        rate: double.tryParse(item.costPerUnit) ?? 0.0,
      );

      // Update stock details
      stock.addGRNDetails(grn.grnNo, grnDetails);

      // Update vendor details
      final vendorDetails = StockVendorDetails(
        vendorId: grn.supplierName,
        vendorName: grn.supplierName,
        quantity: item.receivedQty,
        rate: double.tryParse(item.costPerUnit) ?? 0.0,
        lastPurchaseDate: grn.grnDate,
      );
      stock.addVendorDetails(grn.supplierName, vendorDetails);

      // Update PO details
      if (grn.poNo.isNotEmpty) {
        final poDetails = StockPODetails(
          poNo: grn.poNo,
          poDate: grn.poDate,
          orderedQuantity: item.orderedQty,
          receivedQuantity: item.receivedQty,
          vendorId: grn.supplierName,
          rate: double.tryParse(item.costPerUnit) ?? 0.0,
        );
        stock.addPODetails(grn.poNo, poDetails);
      }

      // Update PR and Job details from item.prQuantities and item.prJobNumbers
      for (var poEntry in item.prQuantities.entries) {
        final poNo = poEntry.key;
        for (var prEntry in poEntry.value.entries) {
          final prNo = prEntry.key;
          final quantity = prEntry.value;
          final jobNo = item.getJobNumberForPR(poNo, prNo);

          print('Processing PR: $prNo, Job: $jobNo, Qty: $quantity');

          // Update PR details
          final prDetails = StockPRDetails(
            prNo: prNo,
            prDate: '', // You might want to fetch this from PR data
            requestedQuantity: quantity,
            orderedQuantity: quantity,
            receivedQuantity: quantity, // Use the actual PR quantity
          );
          stock.addPRDetails(prNo, prDetails);

          // Update Job details if available
          if (jobNo.isNotEmpty && jobNo != 'General') {
            final jobDetails = StockJobDetails(
              jobNo: jobNo,
              allocatedQuantity: quantity,
              consumedQuantity: 0.0, // This would need to be tracked separately
              prNo: prNo,
            );
            stock.addJobDetails(jobNo, jobDetails);
          }
        }
      }

      // Calculate total current stock and under inspection stock
      double totalCurrentStock = stock.currentStock;
      double totalUnderInspection = stock.stockUnderInspection; // Initialize with existing under inspection quantity

      // Get the material's category to check if inspection is required
      final materialsBox = Hive.box<MaterialItem>('materials');
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
      final categoriesBox = Hive.box<Category>('categories');
      final category = categoriesBox.values.firstWhere(
        (c) => c.name == material.category,
        orElse: () => Category(name: material.category),
      );

      // If quality check is not required, add to current stock
      if (!category.requiresQualityCheck) {
        print('Quality check not required, adding to current stock');
        totalCurrentStock += item.receivedQty;
      } else {
        print('Quality check required, calculating stocks');
        // Add accepted quantity to current stock
        totalCurrentStock += item.acceptedQty;
        // Add pending inspection quantity to under inspection
        totalUnderInspection += item.receivedQty - (item.acceptedQty + item.rejectedQty);
      }

      print('Updating stock quantities:');
      print('New Current Stock: $totalCurrentStock');
      print('New Under Inspection: $totalUnderInspection');

      // Update the stock quantities
      stock.updateCurrentStock(totalCurrentStock);
      stock.updateStockUnderInspection(totalUnderInspection);

      // Save to Hive if it's a new stock entry
      if (!_stockBox.values.contains(stock)) {
        await _stockBox.add(stock);
      }

      // Update state
      state = [..._stockBox.values];
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
