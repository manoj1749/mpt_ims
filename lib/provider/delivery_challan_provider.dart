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

  Future<void> addDeliveryChallan(DeliveryChallan dc) async {
    try {
      // Update stock maintenance first
      for (var item in dc.items) {
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);

        final jobNo = item.jobNo ?? 'General';
        
        // Update job details
        if (!stockItem.jobDetails.containsKey(jobNo)) {
          stockItem.jobDetails[jobNo] = StockJobDetails(
            jobNo: jobNo,
            allocatedQuantity: 0.0,
            consumedQuantity: 0.0,
            pendingDeliveryQuantity: item.quantity,
            prNo: item.prNo ?? '',
          );
        } else {
          // Update pending delivery quantity
          stockItem.jobDetails[jobNo]!.pendingDeliveryQuantity += item.quantity;
          
          // If this is a PR-based delivery, update consumed quantity
          if (item.prNo != null && item.prNo!.isNotEmpty) {
            stockItem.jobDetails[jobNo]!.consumedQuantity += item.quantity;
            
            // Also update PR issued quantity
            if (stockItem.prDetails.containsKey(item.prNo)) {
              stockItem.prDetails[item.prNo]!.issuedQuantity += item.quantity;
            }
          }
        }
        await stockItem.save();
      }

      // Add to Firestore first
      final docRef = _firestore.collection('delivery_challans').doc(dc.dcNo);
      final data = _convertToMap(dc);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await _dcBox.add(dc);

      // Update state
      state = _dcBox.values.toList();

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('delivery_challans', _dcBox);
    } catch (e) {
      print('Error adding delivery challan: $e');
      rethrow;
    }
  }

  Future<void> updateDeliveryChallan(int index, DeliveryChallan dc) async {
    try {
      // Get the old DC to revert quantities
      final oldDc = _dcBox.getAt(index);
      if (oldDc != null) {
        for (var item in oldDc.items) {
          final stockItem = _stockBox.values
              .firstWhere((stock) => stock.materialCode == item.materialCode);

          final jobNo = item.jobNo ?? 'General';
          
          // Revert old quantities
          if (stockItem.jobDetails.containsKey(jobNo)) {
            stockItem.jobDetails[jobNo]!.pendingDeliveryQuantity -= item.quantity;
            
            // If this was a PR-based delivery, revert consumed quantity
            if (item.prNo != null && item.prNo!.isNotEmpty) {
              stockItem.jobDetails[jobNo]!.consumedQuantity -= item.quantity;
              
              // Also revert PR issued quantity
              if (stockItem.prDetails.containsKey(item.prNo)) {
                stockItem.prDetails[item.prNo]!.issuedQuantity -= item.quantity;
              }
            }
          }
          await stockItem.save();
        }
      }

      // Update with new quantities
      for (var item in dc.items) {
        final stockItem = _stockBox.values
            .firstWhere((stock) => stock.materialCode == item.materialCode);

        final jobNo = item.jobNo ?? 'General';
        
        // Update job details
        if (!stockItem.jobDetails.containsKey(jobNo)) {
          stockItem.jobDetails[jobNo] = StockJobDetails(
            jobNo: jobNo,
            allocatedQuantity: 0.0,
            consumedQuantity: item.prNo != null && item.prNo!.isNotEmpty ? item.quantity : 0.0,
            pendingDeliveryQuantity: item.quantity,
            prNo: item.prNo ?? '',
          );
        } else {
          // Update pending delivery quantity
          stockItem.jobDetails[jobNo]!.pendingDeliveryQuantity += item.quantity;
          
          // If this is a PR-based delivery, update consumed quantity
          if (item.prNo != null && item.prNo!.isNotEmpty) {
            stockItem.jobDetails[jobNo]!.consumedQuantity += item.quantity;
            
            // Also update PR issued quantity
            if (stockItem.prDetails.containsKey(item.prNo)) {
              stockItem.prDetails[item.prNo]!.issuedQuantity += item.quantity;
            }
          }
        }
        await stockItem.save();
      }

      // Update in Firestore first
      final docRef = _firestore.collection('delivery_challans').doc(dc.dcNo);
      final data = _convertToMap(dc);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.update(data);

      // Then update in Hive
      await _dcBox.putAt(index, dc);

      // Update state
      state = _dcBox.values.toList();

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('delivery_challans', _dcBox);
    } catch (e) {
      print('Error updating delivery challan: $e');
      rethrow;
    }
  }

  Future<void> deleteDeliveryChallan(DeliveryChallan dc) async {
    try {
      print('Deleting delivery challan: ${dc.dcNo}');
      final index = _dcBox.values.toList().indexWhere((d) => d.dcNo == dc.dcNo);
      if (index != -1) {
        // Delete from Firestore first
        final docRef = _firestore.collection('delivery_challans').doc(dc.dcNo);
        await docRef.delete();

        // Then delete from Hive
        await _dcBox.deleteAt(index);

        // Update state
        state = _dcBox.values.toList();
        print('Delivery challan deleted successfully');

        // Keep existing sync for backward compatibility
        await _syncService.syncToFirestore('delivery_challans', _dcBox);
      }
    } catch (e) {
      print('Error deleting delivery challan: $e');
      rethrow;
    }
  }

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

  Map<String, dynamic> _convertToMap(DeliveryChallan dc) {
    return {
      'dcNo': dc.dcNo,
      'dcDate': dc.dcDate,
      'vendorName': dc.vendorName,
      'vendorEmail': dc.vendorEmail,
      'vendorGstin': dc.vendorGstin,
      'items': dc.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'jobNo': item.jobNo,
        'prNo': item.prNo,
      }).toList(),
      'isReturnable': dc.isReturnable,
      'note': dc.note,
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
