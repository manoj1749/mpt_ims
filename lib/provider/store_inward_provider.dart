import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/store_inward.dart';
import '../models/material_item.dart';
import '../models/purchase_order.dart';
import '../models/stock_maintenance.dart';
import '../provider/stock_maintenance_provider.dart';

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

    // Add to Hive
    await _inwardBox.add(inward);

    // Update stock maintenance
    await ref
        .read(stockMaintenanceProvider.notifier)
        .updateStockFromGRN(inward);

    // Update state
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
  double getTotalReceivedQuantityForPR(
      String materialCode, String poNo, String prNo) {
    double total = 0.0;
    for (var inward in _inwardBox.values) {
      for (var item in inward.items) {
        if (item.materialCode == materialCode) {
          // Check if this item has quantities for this PO and PR
          if (item.prQuantities.containsKey(poNo) &&
              item.prQuantities[poNo]!.containsKey(prNo)) {
            total += item.prQuantities[poNo]![prNo]!;
          }
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
}
