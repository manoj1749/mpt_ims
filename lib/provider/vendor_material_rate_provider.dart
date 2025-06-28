// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vendor_material_rate.dart';

// Box provider
final vendorMaterialRateBoxProvider = Provider<Box<VendorMaterialRate>>((ref) {
  throw UnimplementedError();
});

final vendorMaterialRateProvider =
    StateNotifierProvider<VendorMaterialRateNotifier, List<VendorMaterialRate>>(
  (ref) {
    final box = ref.watch(vendorMaterialRateBoxProvider);
    return VendorMaterialRateNotifier(box);
  },
);

class VendorMaterialRateNotifier
    extends StateNotifier<List<VendorMaterialRate>> {
  final Box<VendorMaterialRate> box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VendorMaterialRateNotifier(this.box) : super([]) {
    // Load rates when initialized
    loadRates();
  }

  Future<void> loadRates() async {
    try {
      print('Loading vendor material rates from Firestore...');
      final querySnapshot = await _firestore.collection('vendor_material_rates').get();
      print('Found ${querySnapshot.docs.length} rates in Firestore');

      // Clear existing rates from Hive
      await box.clear();

      // Add new rates to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final rate = _rateFromMap(data);
        await box.put(rate.uniqueKey, rate);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded vendor material rates');
    } catch (e) {
      print('Error loading vendor material rates: $e');
      rethrow;
    }
  }

  Future<void> addRate(VendorMaterialRate rate) async {
    try {
      print('Adding rate for material ${rate.materialId} and vendor ${rate.vendorId}');
      
      // Add to Firestore first
      final docRef = _firestore.collection('vendor_material_rates').doc(rate.uniqueKey);
      final data = _rateToMap(rate);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.put(rate.uniqueKey, rate);
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Rate added successfully');
    } catch (e) {
      print('Error adding rate: $e');
      rethrow;
    }
  }

  Future<void> updateRate(VendorMaterialRate rate) async {
    try {
      print('Updating rate for material ${rate.materialId} and vendor ${rate.vendorId}');

      // Update in Firestore first
      final docRef = _firestore.collection('vendor_material_rates').doc(rate.uniqueKey);
      final data = _rateToMap(rate);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.update(data);

      // Then update in Hive
      await box.put(rate.uniqueKey, rate);
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Rate updated successfully');
    } catch (e) {
      print('Error updating rate: $e');
      rethrow;
    }
  }

  Future<void> deleteRate(String materialId, String vendorId) async {
    try {
      final key = "$materialId-$vendorId";
      print('Deleting rate with key: $key');

      // Delete from Firestore first
      final docRef = _firestore.collection('vendor_material_rates').doc(key);
      await docRef.delete();

      // Then delete from Hive
      await box.delete(key);
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Rate deleted successfully');
    } catch (e) {
      print('Error deleting rate: $e');
      rethrow;
    }
  }

  List<VendorMaterialRate> getRatesForMaterial(String materialId) {
    return state.where((rate) => rate.materialId == materialId).toList();
  }

  List<VendorMaterialRate> getRatesForVendor(String vendorId) {
    return state.where((rate) => rate.vendorId == vendorId).toList();
  }

  // Get specific rate
  VendorMaterialRate? getRate(String materialId, String vendorId) {
    try {
      return state.firstWhere(
        (rate) => rate.materialId == materialId && rate.vendorId == vendorId
      );
    } catch (e) {
      return null;
    }
  }

  // Public alias for loadRates to maintain consistency with other providers
  Future<void> refresh() async {
    await loadRates();
  }

  // Helper method to convert VendorMaterialRate to Map
  Map<String, dynamic> _rateToMap(VendorMaterialRate rate) {
    return {
      'materialId': rate.materialId,
      'vendorId': rate.vendorId,
      'saleRate': rate.saleRate,
      'lastPurchaseDate': rate.lastPurchaseDate,
      'remarks': rate.remarks,
      'totalReceivedQty': rate.totalReceivedQty,
      'issuedQty': rate.issuedQty,
      'receivedQty': rate.receivedQty,
      'avlStock': rate.avlStock,
      'avlStockValue': rate.avlStockValue,
      'billingQtyDiff': rate.billingQtyDiff,
      'totalReceivedCost': rate.totalReceivedCost,
      'totalBilledCost': rate.totalBilledCost,
      'costDiff': rate.costDiff,
      'inspectionStock': rate.inspectionStock,
      'isPreferred': rate.isPreferred,
    };
  }

  // Helper method to convert Map to VendorMaterialRate
  VendorMaterialRate _rateFromMap(Map<String, dynamic> map) {
    return VendorMaterialRate(
      materialId: map['materialId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      saleRate: map['saleRate'] ?? '0',
      lastPurchaseDate: map['lastPurchaseDate'] ?? '',
      remarks: map['remarks'] ?? '',
      totalReceivedQty: map['totalReceivedQty'] ?? '0',
      issuedQty: map['issuedQty'] ?? '0',
      receivedQty: map['receivedQty'] ?? '0',
      avlStock: map['avlStock'] ?? '0',
      avlStockValue: map['avlStockValue'] ?? '0',
      billingQtyDiff: map['billingQtyDiff'] ?? '0',
      totalReceivedCost: map['totalReceivedCost'] ?? '0',
      totalBilledCost: map['totalBilledCost'] ?? '0',
      costDiff: map['costDiff'] ?? '0',
      inspectionStock: map['inspectionStock'] ?? '0',
      isPreferred: map['isPreferred'] ?? false,
    );
  }

  // Add received quantity to inspection stock
  Future<void> addToInspectionStock(
    String materialId,
    String vendorId,
    double quantity,
  ) async {
    final rate = state.firstWhere(
      (r) => r.materialId == materialId && r.vendorId == vendorId,
    );

    final currentInspectionStock = double.tryParse(rate.inspectionStock) ?? 0;
    final updatedRate = rate.copyWith(
      inspectionStock: (currentInspectionStock + quantity).toString(),
      receivedQty: (double.tryParse(rate.receivedQty)! + quantity).toString(),
      totalReceivedQty:
          (double.tryParse(rate.totalReceivedQty)! + quantity).toString(),
    );

    await updateRate(updatedRate);
  }

  // Accept quantity from inspection stock to available stock
  Future<void> acceptFromInspectionStock(
    String materialId,
    String vendorId,
    double quantity,
  ) async {
    print('\nAccepting from inspection stock:');
    print('Material ID: $materialId');
    print('Vendor ID: $vendorId');
    print('Quantity: $quantity');
    print('Current state length: ${state.length}');
    print(
        'Available rates: ${state.map((r) => '${r.materialId}-${r.vendorId}').join(', ')}');

    // Try to find existing rate
    final existingRate = state.firstWhere(
      (r) => r.materialId == materialId && r.vendorId == vendorId,
      orElse: () {
        print('Creating new vendor material rate record');
        // Create a new rate record if none exists
        final newRate = VendorMaterialRate(
          materialId: materialId,
          vendorId: vendorId,
          saleRate: '0',
          lastPurchaseDate: DateTime.now().toString().split(' ')[0],
          remarks: '',
          totalReceivedQty: '0',
          issuedQty: '0',
          receivedQty: '0',
          avlStock: '0',
          avlStockValue: '0',
          billingQtyDiff: '0',
          totalReceivedCost: '0',
          totalBilledCost: '0',
          costDiff: '0',
          inspectionStock: quantity.toString(),
        );
        return newRate;
      },
    );

    print(
        'Found/Created rate record: ${existingRate.materialId}-${existingRate.vendorId}');
    print('Current inspection stock: ${existingRate.inspectionStock}');
    print('Current available stock: ${existingRate.avlStock}');

    final currentInspectionStock =
        double.tryParse(existingRate.inspectionStock) ?? 0;
    final currentAvailableStock = double.tryParse(existingRate.avlStock) ?? 0;

    if (currentInspectionStock >= quantity) {
      final updatedRate = existingRate.copyWith(
        inspectionStock: (currentInspectionStock - quantity).toString(),
        avlStock: (currentAvailableStock + quantity).toString(),
        avlStockValue: ((currentAvailableStock + quantity) *
                (double.tryParse(existingRate.saleRate) ?? 0))
            .toString(),
      );

      print('Updated inspection stock: ${updatedRate.inspectionStock}');
      print('Updated available stock: ${updatedRate.avlStock}');

      await updateRate(updatedRate);
    } else {
      print(
          'Error: Not enough inspection stock (have: $currentInspectionStock, need: $quantity)');
    }
  }

  // Reject quantity from inspection stock
  Future<void> rejectFromInspectionStock(
    String materialId,
    String vendorId,
    double quantity,
  ) async {
    print('\nRejecting from inspection stock:');
    print('Material ID: $materialId');
    print('Vendor ID: $vendorId');
    print('Quantity: $quantity');
    print('Current state length: ${state.length}');
    print(
        'Available rates: ${state.map((r) => '${r.materialId}-${r.vendorId}').join(', ')}');

    // Try to find existing rate
    final existingRate = state.firstWhere(
      (r) => r.materialId == materialId && r.vendorId == vendorId,
      orElse: () {
        print('Creating new vendor material rate record');
        // Create a new rate record if none exists
        final newRate = VendorMaterialRate(
          materialId: materialId,
          vendorId: vendorId,
          saleRate: '0',
          lastPurchaseDate: DateTime.now().toString().split(' ')[0],
          remarks: '',
          totalReceivedQty: '0',
          issuedQty: '0',
          receivedQty: '0',
          avlStock: '0',
          avlStockValue: '0',
          billingQtyDiff: '0',
          totalReceivedCost: '0',
          totalBilledCost: '0',
          costDiff: '0',
          inspectionStock: quantity.toString(),
        );
        return newRate;
      },
    );

    print(
        'Found/Created rate record: ${existingRate.materialId}-${existingRate.vendorId}');
    print('Current inspection stock: ${existingRate.inspectionStock}');

    final currentInspectionStock =
        double.tryParse(existingRate.inspectionStock) ?? 0;

    if (currentInspectionStock >= quantity) {
      final updatedRate = existingRate.copyWith(
        inspectionStock: (currentInspectionStock - quantity).toString(),
      );

      print('Updated inspection stock: ${updatedRate.inspectionStock}');

      await updateRate(updatedRate);
    } else {
      print(
          'Error: Not enough inspection stock (have: $currentInspectionStock, need: $quantity)');
    }
  }
}
