// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/vendor_material_rate.dart';
import 'base_provider.dart';

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

class VendorMaterialRateNotifier extends BaseProvider<VendorMaterialRate> {
  VendorMaterialRateNotifier(Box<VendorMaterialRate> box) 
      : super(box, 'vendor_material_rates');

  @override
  Map<String, dynamic> modelToMap(VendorMaterialRate rate) {
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

  @override
  VendorMaterialRate mapToModel(Map<String, dynamic> map) {
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

  @override
  String getModelId(VendorMaterialRate rate) => rate.uniqueKey;

  // Backward compatibility methods
  Future<void> loadRates() => loadData();
  Future<void> addRate(VendorMaterialRate rate) => add(rate);
  Future<void> updateRate(VendorMaterialRate rate) => update(rate);
  Future<bool> deleteRate(dynamic rateOrMaterialId, [String? vendorId]) async {
    if (rateOrMaterialId is VendorMaterialRate) {
      return await delete(rateOrMaterialId);
    } else if (rateOrMaterialId is String && vendorId != null) {
      final rate = getRateByMaterialAndVendor(rateOrMaterialId, vendorId);
      if (rate != null) {
        return await delete(rate);
      }
      return false;
    }
    return false;
  }

  // Search and filter methods
  List<VendorMaterialRate> searchRates(String query) {
    return search(query, (rate, query) =>
        rate.materialId.toLowerCase().contains(query) ||
        rate.vendorId.toLowerCase().contains(query) ||
        rate.remarks.toLowerCase().contains(query));
  }

  List<VendorMaterialRate> getRatesByMaterial(String materialId) {
    return state.where((rate) => rate.materialId == materialId).toList();
  }

  // Alias for backward compatibility
  List<VendorMaterialRate> getRatesForMaterial(String materialId) {
    return getRatesByMaterial(materialId);
  }

  List<VendorMaterialRate> getRatesByVendor(String vendorId) {
    return state.where((rate) => rate.vendorId == vendorId).toList();
  }

  List<VendorMaterialRate> getPreferredRates() {
    return state.where((rate) => rate.isPreferred).toList();
  }

  VendorMaterialRate? getRateByMaterialAndVendor(String materialId, String vendorId) {
    try {
      return state.firstWhere((rate) => 
          rate.materialId == materialId && rate.vendorId == vendorId);
    } catch (e) {
      return null;
    }
  }

  // Stock-related methods
  List<VendorMaterialRate> getLowStockRates({double threshold = 10.0}) {
    return state.where((rate) {
      final stock = double.tryParse(rate.avlStock) ?? 0;
      return stock <= threshold;
    }).toList();
  }

  List<VendorMaterialRate> getZeroStockRates() {
    return state.where((rate) {
      final stock = double.tryParse(rate.avlStock) ?? 0;
      return stock == 0;
    }).toList();
  }

  List<VendorMaterialRate> getRatesWithInspectionStock() {
    return state.where((rate) {
      final inspectionStock = double.tryParse(rate.inspectionStock) ?? 0;
      return inspectionStock > 0;
    }).toList();
  }

  // Value calculation methods
  double getTotalStockValue() {
    return state.fold(0.0, (sum, rate) => sum + rate.stockValue);
  }

  double getTotalInspectionStockValue() {
    return state.fold(0.0, (sum, rate) => sum + rate.inspectionStockValue);
  }

  double getVendorTotalValue(String vendorId) {
    return getRatesByVendor(vendorId)
        .fold(0.0, (sum, rate) => sum + rate.stockValue);
  }

  double getMaterialTotalValue(String materialId) {
    return getRatesByMaterial(materialId)
        .fold(0.0, (sum, rate) => sum + rate.stockValue);
  }

  // Preference management
  Future<void> setPreferredVendor(String materialId, String vendorId) async {
    // First, remove preferred status from all vendors for this material
    final materialRates = getRatesByMaterial(materialId);
    for (var rate in materialRates) {
      if (rate.isPreferred) {
        final updatedRate = rate.copyWith(isPreferred: false);
        await update(updatedRate);
      }
    }

    // Then set the new preferred vendor
    final targetRate = getRateByMaterialAndVendor(materialId, vendorId);
    if (targetRate != null) {
      final updatedRate = targetRate.copyWith(isPreferred: true);
      await update(updatedRate);
    }
  }

  // Bulk operations
  Future<void> updateStockForMaterial(String materialId, String newStock) async {
    final materialRates = getRatesByMaterial(materialId);
    for (var rate in materialRates) {
      final updatedRate = rate.copyWith(avlStock: newStock);
      await update(updatedRate);
    }
  }

  Future<void> updateRateForVendor(String vendorId, String newRate) async {
    final vendorRates = getRatesByVendor(vendorId);
    for (var rate in vendorRates) {
      final updatedRate = rate.copyWith(saleRate: newRate);
      await update(updatedRate);
    }
  }
}
