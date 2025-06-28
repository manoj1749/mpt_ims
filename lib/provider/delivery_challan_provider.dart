// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/delivery_challan.dart';
import '../models/stock_maintenance.dart';
import '../services/sync_service.dart';

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
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DeliveryChallanNotifier(this._dcBox, this._stockBox, this._syncService)
      : super([]) {
    // Load delivery challans when initialized
    loadDeliveryChallans();
  }

  Future<void> loadDeliveryChallans() async {
    try {
      print('Loading delivery challan data from Firestore...');
      final querySnapshot = await _firestore.collection('delivery_challans').get();
      print('Found ${querySnapshot.docs.length} delivery challans in Firestore');

      // Clear existing delivery challans from Hive
      await _dcBox.clear();

      // Add new delivery challans to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final challan = _syncService.deliveryChallanFromMap(data);
        await _dcBox.add(challan);
      }

      // Update state
      state = _dcBox.values.toList();
      print('Successfully loaded delivery challan data');
    } catch (e) {
      print('Error loading delivery challan data: $e');
      rethrow;
    }
  }

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

      // Add to Firestore first
      final docRef = _firestore.collection('delivery_challans').doc(dc.dcNo);
      final data = _convertToMap(dc);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then save to Hive
      await _dcBox.add(dc);

      // Update state
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

        // Update in Firestore first
        final docRef = _firestore.collection('delivery_challans').doc(dc.dcNo);
        final data = _convertToMap(dc);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);

        // Then update in Hive
        await _dcBox.putAt(index, dc);

        // Update state
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

      // Delete from Firestore first
      final docRef = _firestore.collection('delivery_challans').doc(dcNo);
      await docRef.delete();

      // Then revert stock quantities
      await _revertStockQuantities(dc);

      // Then delete from Hive
      await _dcBox.delete(dc.key);

      // Update state
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

  // Helper method to convert DeliveryChallan to Map
  Map<String, dynamic> _convertToMap(DeliveryChallan dc) {
    return {
      'dcNo': dc.dcNo,
      'dcDate': dc.dcDate,
      'vendorName': dc.vendorName,
      'isReturnable': dc.isReturnable,
      'items': dc.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'quantity': item.quantity,
        'unit': item.unit,
        'jobNo': item.jobNo,
        'prNo': item.prNo,
      }).toList(),
    };
  }

  Future<void> refresh() async {
    try {
      await loadDeliveryChallans();
    } catch (e) {
      print('Error refreshing delivery challans: $e');
      rethrow;
    }
  }
}

final deliveryChallanProvider =
    StateNotifierProvider<DeliveryChallanNotifier, List<DeliveryChallan>>((ref) {
  final dcBox = ref.watch(deliveryChallanBoxProvider);
  final stockBox = Hive.box<StockMaintenance>('stock_maintenance');
  final syncService = ref.watch(syncServiceProvider);
  return DeliveryChallanNotifier(dcBox, stockBox, syncService);
});
