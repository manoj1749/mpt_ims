import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/store_inward.dart';
import '../models/material_item.dart';
import '../provider/stock_maintenance_provider.dart';
import 'package:intl/intl.dart';

final storeInwardBoxProvider = Provider<Box<StoreInward>>((ref) {
  throw UnimplementedError();
});

final storeInwardProvider =
    NotifierProvider<StoreInwardNotifier, List<StoreInward>>(
  () => StoreInwardNotifier(),
);

class StoreInwardNotifier extends Notifier<List<StoreInward>> {
  late Box<StoreInward> _inwardBox;
  late Box<MaterialItem> _materialBox;
  int _lastGRNNumber = 0;

  @override
  List<StoreInward> build() {
    _inwardBox = Hive.box<StoreInward>('store_inward');
    _materialBox = Hive.box<MaterialItem>('materials');
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
      final grnNum = int.tryParse(inward.grnNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
    // Add to Hive
    await _inwardBox.add(inward);

    // Update stock maintenance
    await ref.read(stockMaintenanceProvider.notifier).updateStockFromGRN(inward);

    // Update state
    state = [..._inwardBox.values];
  }

  Future<void> updateInward(int index, StoreInward inward) async {
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
    await ref.read(stockMaintenanceProvider.notifier).updateStockFromGRN(inward);

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

        // Update vendor details
        if (stock.vendorDetails.containsKey(inward.supplierName)) {
          final vendorDetails = stock.vendorDetails[inward.supplierName]!;
          vendorDetails.quantity -= item.receivedQty;
          if (vendorDetails.quantity <= 0) {
            stock.vendorDetails.remove(inward.supplierName);
          }
        }
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
    return _inwardBox.values
        .where((inward) => inward.poNo == poNo)
        .toList();
  }

  // Get all inwards between two dates
  List<StoreInward> getInwardsBetweenDates(DateTime start, DateTime end) {
    final dateFormat = DateFormat('yyyy-MM-dd');
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
      return sum + item.prQuantities[poNo]!.values.fold(0.0, (sum, qty) => sum + qty);
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
}
