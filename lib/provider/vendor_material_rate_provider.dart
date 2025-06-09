import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  VendorMaterialRateNotifier(this.box) : super(box.values.toList());

  Future<void> addRate(VendorMaterialRate rate) async {
    await box.put(rate.uniqueKey, rate);
    state = box.values.toList();
  }

  Future<void> updateRate(VendorMaterialRate rate) async {
    await box.put(rate.uniqueKey, rate);
    state = box.values.toList();
  }

  Future<void> deleteRate(String materialId, String vendorId) async {
    final key = "$materialId-$vendorId";
    await box.delete(key);
    state = box.values.toList();
  }

  List<VendorMaterialRate> getRatesForMaterial(String materialId) {
    return state.where((rate) => rate.materialId == materialId).toList();
  }

  List<VendorMaterialRate> getRatesForVendor(String vendorId) {
    return state.where((rate) => rate.vendorId == vendorId).toList();
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
    print('Available rates: ${state.map((r) => '${r.materialId}-${r.vendorId}').join(', ')}');

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

    print('Found/Created rate record: ${existingRate.materialId}-${existingRate.vendorId}');
    print('Current inspection stock: ${existingRate.inspectionStock}');
    print('Current available stock: ${existingRate.avlStock}');

    final currentInspectionStock = double.tryParse(existingRate.inspectionStock) ?? 0;
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
      print('Error: Not enough inspection stock (have: $currentInspectionStock, need: $quantity)');
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
    print('Available rates: ${state.map((r) => '${r.materialId}-${r.vendorId}').join(', ')}');

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

    print('Found/Created rate record: ${existingRate.materialId}-${existingRate.vendorId}');
    print('Current inspection stock: ${existingRate.inspectionStock}');

    final currentInspectionStock = double.tryParse(existingRate.inspectionStock) ?? 0;

    if (currentInspectionStock >= quantity) {
      final updatedRate = existingRate.copyWith(
        inspectionStock: (currentInspectionStock - quantity).toString(),
      );

      print('Updated inspection stock: ${updatedRate.inspectionStock}');

      await updateRate(updatedRate);
    } else {
      print('Error: Not enough inspection stock (have: $currentInspectionStock, need: $quantity)');
    }
  }
}
