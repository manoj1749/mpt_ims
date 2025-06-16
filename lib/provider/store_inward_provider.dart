// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/store_inward.dart';
import '../models/material_item.dart';
import '../models/purchase_order.dart';
import '../models/stock_maintenance.dart';
import '../models/po_item.dart';
import '../provider/stock_maintenance_provider.dart';
import '../provider/purchase_order.dart';
import '../models/quality_inspection.dart';
import '../models/category.dart';

final storeInwardBoxProvider = Provider<Box<StoreInward>>((ref) {
  throw UnimplementedError();
});

final storeInwardProvider =
    NotifierProvider<StoreInwardNotifier, List<StoreInward>>(
  () => StoreInwardNotifier(),
);

final storeInwardMaterialBoxProvider = Provider<Box<MaterialItem>>((ref) {
  return Hive.box<MaterialItem>('materials');
});

class StoreInwardNotifier extends Notifier<List<StoreInward>> {
  late Box<StoreInward> _inwardBox;
  int _lastGRNNumber = 0;

  @override
  List<StoreInward> build() {
    _inwardBox = ref.watch(storeInwardBoxProvider);
    _initializeLastGRNNumber();
    return _inwardBox.values.toList();
  }

  void _initializeLastGRNNumber() {
    if (_inwardBox.isEmpty) {
      _lastGRNNumber = 0;
      return;
    }

    // Find the highest GRN number
    _lastGRNNumber = _inwardBox.values.fold(0, (maxNum, inward) {
      final grnNum =
          int.tryParse(inward.grnNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return grnNum > maxNum ? grnNum : maxNum;
    });
  }

  String generateGRNNumber() {
    _lastGRNNumber++;
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    return 'GRN$year$month${_lastGRNNumber.toString().padLeft(4, '0')}';
  }

  Future<void> addInward(StoreInward inward) async {
    print('\nAdding new inward: ${inward.grnNo}');
    
    // Get all POs
    final poList = ref.read(purchaseOrderListProvider);
    
    // Process each item
    for (var item in inward.items) {
      print('\nProcessing item: ${item.materialCode}');
      
      // For each PO in the item
      for (var poNo in item.prQuantities.keys.toList()) {
        print('\nChecking PO: $poNo');
        final prQuantities = item.prQuantities[poNo];
        
        // Only auto-distribute if no PR quantities are manually set
        if (prQuantities == null || prQuantities.isEmpty) {
          print('No PR quantities found for PO, checking PR details');
          
          // Find the PO
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
          
          // Find the corresponding PO item
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

          print('DEBUG: poItem.prDetails for ${item.materialCode}/${po.poNo}: ${poItem.prDetails}');

          if (poItem.prDetails.isNotEmpty) {
            print('Found PR details in PO:');
            // Calculate total PR quantity
            double totalPRQty = poItem.prDetails.values
                .fold(0.0, (sum, detail) => sum + detail.quantity);

            // Distribute received quantity proportionally
            for (var prDetail in poItem.prDetails.entries) {
              final prNo = prDetail.key;
              final jobNo = prDetail.value.jobNo;
              final prQty = prDetail.value.quantity;
              
              // Calculate proportional quantity
              double proportion = prQty / totalPRQty;
              double allocatedQty = item.receivedQty * proportion;
              
              print('\nAdding PR quantity:');
              print('PO: $poNo, PR: $prNo, Quantity: $allocatedQty');
              
              if (!item.prQuantities.containsKey(poNo)) {
                item.prQuantities[poNo] = {};
              }
              item.prQuantities[poNo]![prNo] = allocatedQty;
              
              print('Updated PR quantities for $poNo:');
              item.prQuantities[poNo]!.forEach((pr, qty) => 
                print('PR: $pr, Quantity: $qty'));
              
              print('\nAdding job number:');
              print('PO: $poNo, PR: $prNo, Job: $jobNo');
              
              if (!item.prJobNumbers.containsKey(poNo)) {
                item.prJobNumbers[poNo] = {};
              }
              item.prJobNumbers[poNo]![prNo] = jobNo;
              
              print('Updated job numbers for $poNo:');
              item.prJobNumbers[poNo]!.forEach((pr, job) => 
                print('PR: $pr, Job: $job'));
            }
          } else {
            // If no PR details found, assign to General PR
            print('No PR details found in PO, assigning to General PR');
            if (!item.prQuantities.containsKey(poNo)) {
              item.prQuantities[poNo] = {};
            }
            item.prQuantities[poNo]!['General'] = item.receivedQty;
            
            if (!item.prJobNumbers.containsKey(poNo)) {
              item.prJobNumbers[poNo] = {};
            }
            item.prJobNumbers[poNo]!['General'] = 'General';
          }
        } else {
          print('Using manually set PR quantities for PO $poNo:');
          prQuantities.forEach((pr, qty) => print('PR: $pr, Quantity: $qty'));
        }
      }
    }

    // Add to Hive
    await _inwardBox.add(inward);

    // Update stock maintenance
    await ref
        .read(stockMaintenanceProvider.notifier)
        .updateStockFromGRN(inward);

    state = [..._inwardBox.values];
  }

  Future<void> updateInward(int index, StoreInward inward) async {
    print('\nUpdating inward: ${inward.grnNo}');
    
    // Process each item
    for (var item in inward.items) {
      print('\nProcessing item: ${item.materialCode}');
      
      // For each PO in the item
      for (var poNo in item.prQuantities.keys.toList()) {
        print('\nChecking PO: $poNo');
        final prQuantities = item.prQuantities[poNo];
        
        // If there are no PR quantities but we have a PO quantity
        if ((prQuantities?.isEmpty ?? true) && item.receivedQty > 0) {
          print('No PR quantities found for PO, distributing automatically');
          item.distributePOQuantityToPRs(poNo, item.receivedQty);
        }
      }
    }

    // Get old inward for comparison
    final oldInward = _inwardBox.getAt(index);

    // Update in Hive
    await _inwardBox.putAt(index, inward);

    // Update stock maintenance
    if (oldInward != null) {
      // First reverse the old GRN's effect on stock
      await _reverseStockUpdate(oldInward);
    }
    // Then apply the new GRN's effect
    await ref
        .read(stockMaintenanceProvider.notifier)
        .updateStockFromGRN(inward);

    // Update state
    state = [..._inwardBox.values];
  }

  Future<void> deleteInward(StoreInward inward) async {
    // First reverse the GRN's effect on stock
    await _reverseStockUpdate(inward);

    // Delete from Hive
    await inward.delete();

    // Update state
    state = [..._inwardBox.values];
  }

  // Helper method to reverse a GRN's effect on stock
  Future<void> _reverseStockUpdate(StoreInward inward) async {
    final stockProvider = ref.read(stockMaintenanceProvider.notifier);

    for (var item in inward.items) {
      final stock = stockProvider.getStockForMaterial(item.materialCode);
      if (stock != null) {
        // Reverse the stock quantities
        stock.updateCurrentStock(stock.currentStock - item.acceptedQty);
        stock.updateStockUnderInspection(stock.stockUnderInspection -
            (item.receivedQty - (item.acceptedQty + item.rejectedQty)));

        // Remove GRN details
        stock.grnDetails.remove(inward.grnNo);

        // Remove PO details if this was the only GR for that PO
        for (var poNo in item.prQuantities.keys) {
          bool hasOtherGRsForPO = _inwardBox.values
              .where((gr) => gr.grnNo != inward.grnNo)
              .any((gr) => gr.items.any((i) =>
                  i.materialCode == item.materialCode &&
                  i.prQuantities.containsKey(poNo)));

          if (!hasOtherGRsForPO) {
            stock.poDetails.remove(poNo);
          }
        }

        // Remove PR details if this was the only GR for those PRs
        for (var poEntry in item.prQuantities.entries) {
          final poNo = poEntry.key;
          for (var prNo in poEntry.value.keys) {
            bool hasOtherGRsForPR = _inwardBox.values
                .where((gr) => gr.grnNo != inward.grnNo)
                .any((gr) => gr.items.any((i) =>
                    i.materialCode == item.materialCode &&
                    i.prQuantities[poNo]?.containsKey(prNo) == true));

            if (!hasOtherGRsForPR) {
              stock.prDetails.remove(prNo);
            }
          }
        }

        // Remove job details if this was the only GR for those jobs
        final jobsToCheck = item.getJobNumbers();
        for (var jobNo in jobsToCheck) {
          bool hasOtherGRsForJob = _inwardBox.values
              .where((gr) => gr.grnNo != inward.grnNo)
              .any((gr) => gr.items.any((i) =>
                  i.materialCode == item.materialCode &&
                  i.getJobNumbers().contains(jobNo)));

          if (!hasOtherGRsForJob) {
            stock.jobDetails.remove(jobNo);
          }
        }

        // Update vendor details
        if (stock.vendorDetails.containsKey(inward.supplierName)) {
          final vendorDetails = stock.vendorDetails[inward.supplierName]!;
          vendorDetails.quantity -= item.receivedQty;
          if (vendorDetails.quantity <= 0) {
            stock.vendorDetails.remove(inward.supplierName);
          }
        }

        // Save the updated stock
        await stock.save();
      }
    }
  }

  // Get all inwards for a specific material
  List<StoreInward> getInwardsForMaterial(String materialCode) {
    return _inwardBox.values
        .where((inward) =>
            inward.items.any((item) => item.materialCode == materialCode))
        .toList();
  }

  // Get all inwards for a specific supplier
  List<StoreInward> getInwardsForSupplier(String supplierName) {
    return _inwardBox.values
        .where((inward) => inward.supplierName == supplierName)
        .toList();
  }

  // Get all inwards for a specific PO
  List<StoreInward> getInwardsForPO(String poNo) {
    return _inwardBox.values.where((inward) => inward.poNo == poNo).toList();
  }

  // Get all inwards between two dates
  List<StoreInward> getInwardsBetweenDates(DateTime start, DateTime end) {
    return _inwardBox.values.where((inward) {
      final grnDate = DateTime.tryParse(inward.grnDate);
      return grnDate != null &&
          grnDate.isAfter(start.subtract(const Duration(days: 1))) &&
          grnDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get total received quantity for a material from a specific PO
  double getTotalReceivedQuantityForPO(String materialCode, String poNo) {
    return _inwardBox.values
        .where((inward) => inward.items.any((item) =>
            item.materialCode == materialCode &&
            item.prQuantities.containsKey(poNo)))
        .fold(0.0, (sum, inward) {
      final item =
          inward.items.firstWhere((item) => item.materialCode == materialCode);
      return sum +
          item.prQuantities[poNo]!.values.fold(0.0, (sum, qty) => sum + qty);
    });
  }

  // Get total received quantity for a specific PR
  double? getReceivedQuantityForPR(String materialCode, String poNo, String prNo) {
    double total = 0;
    for (var inward in state) {
      for (var item in inward.items) {
        if (item.materialCode == materialCode) {
          final prQty = item.prQuantities[poNo]?[prNo] ?? 0;
          total += prQty;
        }
      }
    }
    return total;
  }

  // Check and delete PO if no GRs exist for it
  Future<void> deletePOIfNoGRs(String poNo) async {
    // Check if any GR exists for this PO
    bool hasGRs = false;
    for (var inward in _inwardBox.values) {
      for (var item in inward.items) {
        if (item.prQuantities.containsKey(poNo)) {
          hasGRs = true;
          break;
        }
      }
      if (hasGRs) break;
    }

    // If no GRs exist, delete the PO
    if (!hasGRs) {
      final poBox = await Hive.openBox<PurchaseOrder>('purchase_orders');
      try {
        final po = poBox.values.firstWhere((po) => po.poNo == poNo);
        await po.delete();
      } catch (e) {
        // PO not found, which is fine in this case
      }
      await poBox.close();

      // Also update stock maintenance
      ref.read(stockMaintenanceProvider.notifier);
      final stockBox =
          await Hive.openBox<StockMaintenance>('stock_maintenance');
      final stocks = stockBox.values.toList();
      for (var stock in stocks) {
        stock.poDetails.remove(poNo);
        stock.save();
      }
      await stockBox.close();
    }
  }

  // Delete GR and update related data
  Future<void> deleteGR(String grnNo) async {
    try {
      final inward = _inwardBox.values.firstWhere((gr) => gr.grnNo == grnNo);

      // Get all PO numbers from this GR
      final poNumbers = <String>{};
      for (var item in inward.items) {
        poNumbers.addAll(item.prQuantities.keys);
      }

      // First reverse the stock updates
      await _reverseStockUpdate(inward);

      // Delete the GR
      await inward.delete();

      // Check and delete POs that might have no more GRs
      for (var poNo in poNumbers) {
        await deletePOIfNoGRs(poNo);
      }

      state = _inwardBox.values.toList();
    } catch (e) {
      // GR not found
      return;
    }
  }

  // Update GRN status based on inspection status
  Future<void> updateGRNStatus(String grnNo) async {
    print('\n=== Debug: Updating GRN Status ===');
    print('GRN No: $grnNo');

    final inward = _inwardBox.values.firstWhere(
      (gr) => gr.grnNo == grnNo,
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

    if (inward.grnNo.isEmpty) {
      print('GRN not found: $grnNo');
      return;
    }

    print('Current Status: ${inward.status}');

    // Get all inspections for this GRN
    final inspectionBox = Hive.box<QualityInspection>('quality_inspections');
    final inspections = inspectionBox.values.where((insp) => insp.grnNo == grnNo).toList();

    bool allItemsProcessed = true;
    bool hasProcessedItems = false;
    bool hasItemsNeedingInspection = false;

    for (var item in inward.items) {
      print('\nChecking Item: ${item.materialCode}');
      print('Received Qty: ${item.receivedQty}');

      // Get the material's category
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

      // If quality check is not required, consider it as fully processed
      if (!category.requiresQualityCheck) {
        hasProcessedItems = true;
        item.acceptedQty = item.receivedQty;
        item.rejectedQty = 0;
        continue;
      }

      hasItemsNeedingInspection = true;

      // Calculate total inspected, accepted, and rejected quantities from all inspections
      double totalInspectedQty = 0;
      double totalAcceptedQty = 0;
      double totalRejectedQty = 0;

      for (var inspection in inspections) {
        for (var inspItem in inspection.items) {
          if (inspItem.materialCode == item.materialCode) {
            if (inspection.status == 'Completed') {
              totalInspectedQty += inspItem.inspectedQty;
              totalAcceptedQty += inspItem.acceptedQty;
              totalRejectedQty += inspItem.rejectedQty;
            }
          }
        }
      }

      // Update item's accepted and rejected quantities
      item.acceptedQty = totalAcceptedQty;
      item.rejectedQty = totalRejectedQty;

      print('Total Inspected Qty: $totalInspectedQty');
      print('Total Accepted Qty: $totalAcceptedQty');
      print('Total Rejected Qty: $totalRejectedQty');

      if (totalInspectedQty > 0) {
        hasProcessedItems = true;
      }

      if (totalInspectedQty < item.receivedQty) {
        allItemsProcessed = false;
        print('Item not fully inspected: $totalInspectedQty < ${item.receivedQty}');
      }
    }

    String newStatus;
    if (!hasItemsNeedingInspection) {
      newStatus = 'Completed'; // All items are general stock or don't need inspection
    } else if (!hasProcessedItems) {
      newStatus = 'Under Inspection';
    } else if (allItemsProcessed) {
      newStatus = 'Inspected';
    } else {
      newStatus = 'Partially Inspected';
    }

    print('New Status: $newStatus');
    inward.status = newStatus;

    // Save the updated inward
    final index = _inwardBox.values.toList().indexOf(inward);
    await _inwardBox.putAt(index, inward);

    // Update stock maintenance
    await ref.read(stockMaintenanceProvider.notifier).updateStockFromGRN(inward);

    // Update state
    state = [..._inwardBox.values];
  }
}
