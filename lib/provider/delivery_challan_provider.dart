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
      print('\n=== Creating Delivery Challan ===');
      print('DC No: ${dc.dcNo}');
      print('Date: ${dc.dcDate}');
      print('Vendor: ${dc.vendorName}');
      print('Returnable: ${dc.isReturnable}');

      // First update stock quantities
      await _updateStockQuantities(dc);

      // Then save the delivery challan
      await _dcBox.add(dc);
      state = [...state, dc];
      print('Delivery Challan created successfully');
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

  // Delete a delivery challan
  Future<void> deleteDeliveryChallan(String dcNo) async {
    try {
      print('\n=== Deleting Delivery Challan ===');
      print('DC No: $dcNo');

      final dc = _dcBox.values.firstWhere((d) => d.dcNo == dcNo);
      await _revertStockQuantities(dc);
      await _dcBox.delete(dc.key);
      state = state.where((d) => d.dcNo != dcNo).toList();
      print('Delivery Challan deleted successfully');
    } catch (e) {
      print('Error deleting delivery challan: $e');
      rethrow;
    }
  }

  // Helper method to update stock quantities
  Future<void> _updateStockQuantities(DeliveryChallan dc) async {
    print('\n=== Updating Stock Quantities ===');
    for (var item in dc.items) {
      print('\nProcessing Item: ${item.materialCode} - ${item.materialDescription}');
      print('Quantity: ${item.quantity} ${item.unit}');
      print('Job No: ${item.jobNo ?? "General"}');

      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      final jobNo = item.jobNo ?? 'General';
      print('Stock Item Found: ${stockItem.materialCode}');

      // Find available PR for this job
      final prInfo = stockItem.findAvailablePRForJob(jobNo, item.quantity);
      if (prInfo == null) {
        throw Exception(
            'No available PR found for material ${item.materialCode} in job $jobNo');
      }

      final (prNo, availableQty) = prInfo;
      print('Found PR: $prNo with available quantity: $availableQty ${item.unit}');

      if (availableQty < item.quantity) {
        throw Exception(
            'Insufficient stock for material ${item.materialCode} in job $jobNo. Available: $availableQty ${item.unit}, Requested: ${item.quantity} ${item.unit}');
      }

      // Update PR details
      final prDetails = stockItem.prDetails[prNo]!;
      prDetails.issuedQuantity += item.quantity;

      // Update job details
      if (!stockItem.jobDetails.containsKey(jobNo)) {
        stockItem.jobDetails[jobNo] = StockJobDetails(
          jobNo: jobNo,
          allocatedQuantity: item.quantity,
          consumedQuantity: item.quantity,
          prNo: prNo,
        );
      } else {
        final jobDetails = stockItem.jobDetails[jobNo]!;
        jobDetails.consumedQuantity += item.quantity;
        if (jobDetails.allocatedQuantity < jobDetails.consumedQuantity) {
          jobDetails.allocatedQuantity = jobDetails.consumedQuantity;
        }
      }

      // Update item with PR number for tracking
      item.prNo = prNo;

      // Save stock changes
      await _stockBox.put(stockItem.key, stockItem);
      print('Stock updated successfully');
    }
    print('\nStock quantities update completed');
  }

  // Helper method to revert stock quantities
  Future<void> _revertStockQuantities(DeliveryChallan dc) async {
    print('\n=== Reverting Stock Quantities ===');
    for (var item in dc.items) {
      print('\nProcessing Item: ${item.materialCode} - ${item.materialDescription}');
      print('Quantity to revert: ${item.quantity} ${item.unit}');
      print('Job No: ${item.jobNo ?? "General"}');

      final stockItem = _stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      final jobNo = item.jobNo ?? 'General';
      print('Stock Item Found: ${stockItem.materialCode}');

      if (item.prNo != null && stockItem.prDetails.containsKey(item.prNo)) {
        // Revert PR details
        final prDetails = stockItem.prDetails[item.prNo]!;
        prDetails.issuedQuantity = (prDetails.issuedQuantity - item.quantity).clamp(0.0, double.infinity);
        print('Reverted PR issued quantity: ${prDetails.issuedQuantity}');

        // Revert job details
        if (stockItem.jobDetails.containsKey(jobNo)) {
          final jobDetails = stockItem.jobDetails[jobNo]!;
          jobDetails.consumedQuantity = (jobDetails.consumedQuantity - item.quantity).clamp(0.0, double.infinity);
          print('Reverted consumed quantity: ${jobDetails.consumedQuantity}');
        }

        // Save stock changes
        await _stockBox.put(stockItem.key, stockItem);
        print('Stock reverted successfully');
      }
    }
    print('\nStock quantities revert completed');
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
