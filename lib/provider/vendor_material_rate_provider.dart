import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/vendor_material_rate.dart';

// Box provider
final vendorMaterialRateBoxProvider = Provider<Box<VendorMaterialRate>>((ref) {
  throw UnimplementedError();
});

// Provider to track loading state
final vendorRatesLoadingProvider = StateProvider<bool>((ref) => true);

final vendorMaterialRateProvider =
    StateNotifierProvider<VendorMaterialRateNotifier, List<VendorMaterialRate>>(
  (ref) {
    final box = ref.watch(vendorMaterialRateBoxProvider);
    return VendorMaterialRateNotifier(box);
  },
);

class VendorMaterialRateNotifier extends StateNotifier<List<VendorMaterialRate>> {
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
    final rate = state.firstWhere(
      (r) => r.materialId == materialId && r.vendorId == vendorId,
    );

    final currentInspectionStock = double.tryParse(rate.inspectionStock) ?? 0;
    final currentAvailableStock = double.tryParse(rate.avlStock) ?? 0;

    if (currentInspectionStock >= quantity) {
      final updatedRate = rate.copyWith(
        inspectionStock: (currentInspectionStock - quantity).toString(),
        avlStock: (currentAvailableStock + quantity).toString(),
        avlStockValue: ((currentAvailableStock + quantity) *
                (double.tryParse(rate.seiplRate) ?? 0))
            .toString(),
      );

      await updateRate(updatedRate);
    }
  }

  // Reject quantity from inspection stock
  Future<void> rejectFromInspectionStock(
    String materialId,
    String vendorId,
    double quantity,
  ) async {
    final rate = state.firstWhere(
      (r) => r.materialId == materialId && r.vendorId == vendorId,
    );

    final currentInspectionStock = double.tryParse(rate.inspectionStock) ?? 0;

    if (currentInspectionStock >= quantity) {
      final updatedRate = rate.copyWith(
        inspectionStock: (currentInspectionStock - quantity).toString(),
      );

      await updateRate(updatedRate);
    }
  }
}
