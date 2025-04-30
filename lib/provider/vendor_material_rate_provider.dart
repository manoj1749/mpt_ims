import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';

// Provider to track loading state
final vendorRatesLoadingProvider = StateProvider<bool>((ref) => true);

final vendorMaterialRateProvider =
    StateNotifierProvider<VendorMaterialRateNotifier, List<VendorMaterialRate>>(
  (ref) {
    final notifier = VendorMaterialRateNotifier(ref);
    // Initialize rates
    notifier._loadRates().then((_) {
      ref.read(vendorRatesLoadingProvider.notifier).state = false;
    });
    return notifier;
  },
);

class VendorMaterialRateNotifier
    extends StateNotifier<List<VendorMaterialRate>> {
  final Ref ref;

  VendorMaterialRateNotifier(this.ref) : super([]);

  static const String boxName = 'vendor_material_rates';

  Future<void> _loadRates() async {
    final box = await Hive.openBox<VendorMaterialRate>(boxName);
    state = box.values.toList();
  }

  Future<void> addRate(VendorMaterialRate rate) async {
    final box = await Hive.openBox<VendorMaterialRate>(boxName);
    await box.put(rate.uniqueKey, rate);
    state = [...state, rate];
  }

  Future<void> updateRate(VendorMaterialRate rate) async {
    final box = await Hive.openBox<VendorMaterialRate>(boxName);
    await box.put(rate.uniqueKey, rate);
    state = [
      for (final existingRate in state)
        if (existingRate.uniqueKey == rate.uniqueKey) rate else existingRate
    ];
  }

  Future<void> deleteRate(String materialId, String vendorId) async {
    final box = await Hive.openBox<VendorMaterialRate>(boxName);
    final key = "$materialId-$vendorId";
    await box.delete(key);
    state = state.where((rate) => rate.uniqueKey != key).toList();
  }

  List<VendorMaterialRate> getRatesForMaterial(String materialId) {
    return state.where((rate) => rate.materialId == materialId).toList();
  }

  List<VendorMaterialRate> getRatesForVendor(String vendorId) {
    return state.where((rate) => rate.vendorId == vendorId).toList();
  }
}
