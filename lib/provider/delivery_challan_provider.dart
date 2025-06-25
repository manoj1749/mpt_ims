// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/delivery_challan.dart';
import '../models/stock_maintenance.dart';

final deliveryChallanBoxProvider = Provider<Box<DeliveryChallan>>((ref) {
  return Hive.box<DeliveryChallan>('delivery_challans');
});

final deliveryChallanListProvider = Provider<List<DeliveryChallan>>((ref) {
  final box = ref.watch(deliveryChallanBoxProvider);
  return box.values.toList();
});

class DeliveryChallanNotifier extends StateNotifier<List<DeliveryChallan>> {
  final Box<DeliveryChallan> _dcBox;
  final Box<StockMaintenance> _stockBox;

  DeliveryChallanNotifier(this._dcBox, this._stockBox)
      : super(_dcBox.values.toList());

  // Create a new delivery challan
  Future<void> createDeliveryChallan(DeliveryChallan dc) async {
    try {
      // First update stock quantities
      await _updateStockQuantities(dc);

      // Then save the delivery challan
      await _dcBox.add(dc);
      state = [...state, dc];
    } catch (e) {
      print('Error creating delivery challan: $e');
      // If there's an error, revert any stock changes
      await _revertStockQuantities(dc);
      rethrow;
    }
  }

  // Update an existing delivery challan
  Future<void> updateDeliveryChallan(DeliveryChallan dc) async {
    final index = _dcBox.values.toList().indexWhere((d) => d.dcNo == dc.dcNo);
    if (index != -1) {
      final oldDc = _dcBox.values.elementAt(index);

      // First revert old stock quantities
      await _revertStockQuantities(oldDc);

      try {
        // Then update with new quantities
        await _updateStockQuantities(dc);
        await _dcBox.putAt(index, dc);
        state = [...state.where((d) => d.dcNo != dc.dcNo), dc];
      } catch (e) {
        print('Error updating delivery challan: $e');
        // If there's an error, restore the old state
        await _updateStockQuantities(oldDc);
        await _dcBox.putAt(index, oldDc);
        rethrow;
      }
    }
  }

  // Helper method to update stock quantities
  Future<void> _updateStockQuantities(DeliveryChallan dc) async {
    for (var item in dc.items) {
      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      final jobNo = item.jobNo ?? 'General';

      // Create job details if it doesn't exist
      if (!stockItem.jobDetails.containsKey(jobNo)) {
        stockItem.jobDetails[jobNo] = StockJobDetails(
          jobNo: jobNo,
          allocatedQuantity: 0,
          consumedQuantity: 0,
          prNo: 'DC${dc.dcNo}', // Use DC number as PR number for tracking
        );
      }

      // Update consumed quantity
      stockItem.jobDetails[jobNo]!.consumedQuantity += item.quantity;

      // Save stock changes
      await _stockBox.put(stockItem.key, stockItem);
    }
  }

  // Helper method to revert stock quantities
  Future<void> _revertStockQuantities(DeliveryChallan dc) async {
    for (var item in dc.items) {
      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      final jobNo = item.jobNo ?? 'General';

      if (stockItem.jobDetails.containsKey(jobNo)) {
        // Revert consumed quantity
        stockItem.jobDetails[jobNo]!.consumedQuantity -= item.quantity;

        // Save stock changes
        await _stockBox.put(stockItem.key, stockItem);
      }
    }
  }

  // Delete a delivery challan
  Future<void> deleteDeliveryChallan(String dcNo) async {
    final dc = _dcBox.values.firstWhere((d) => d.dcNo == dcNo);
    await _revertStockQuantities(dc);
    await _dcBox.delete(dc.key);
    state = state.where((d) => d.dcNo != dcNo).toList();
  }

  // Generate a new DC number
  String generateDcNo() {
    final currentYear = DateTime.now().year.toString().substring(2);
    final prefix = 'DC$currentYear';

    final existingNos = state
        .map((dc) => dc.dcNo)
        .where((no) => no.startsWith(prefix))
        .map((no) => int.tryParse(no.substring(prefix.length)) ?? 0)
        .toList();

    final nextNo = existingNos.isEmpty ? 1 : (existingNos.reduce(max) + 1);
    return '$prefix${nextNo.toString().padLeft(4, '0')}';
  }
}
