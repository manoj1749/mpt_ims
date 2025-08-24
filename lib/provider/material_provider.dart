import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_item.dart';
import '../models/vendor_material_rate.dart';
import 'base_provider.dart';

final materialBoxProvider = Provider<Box<MaterialItem>>((ref) {
  throw UnimplementedError();
});

final materialListProvider =
    StateNotifierProvider<MaterialNotifier, List<MaterialItem>>(
  (ref) => MaterialNotifier(ref.read(materialBoxProvider)),
);

class MaterialNotifier extends BaseProvider<MaterialItem> {
  MaterialNotifier(Box<MaterialItem> box) : super(box, 'materials');

  @override
  Map<String, dynamic> modelToMap(MaterialItem material) {
    return {
      'slNo': material.slNo,
      'description': material.description,
      'partNo': material.partNo,
      'unit': material.unit,
      'category': material.category,
      'subCategory': material.subCategory,
      'storageLocation': material.storageLocation,
      'rackNumber': material.rackNumber,
      'binNumber': material.binNumber,
      'hsnCode': material.hsnCode,
      'actualWeight': material.actualWeight,
      'saleRate': material.saleRate,
      'vendorRates': material.vendorRates
          .map((rate) => {
                'vendorId': rate.vendorId,
                'baseRate': rate.baseRate,
                'purchaseRate': rate.purchaseRate,
                'lastPurchaseDate': rate.lastPurchaseDate,
                'remarks': rate.remarks,
                'isPreferred': rate.isPreferred,
              })
          .toList(),
    };
  }

  @override
  MaterialItem mapToModel(Map<String, dynamic> map) {
    final vendorRatesList = (map['vendorRates'] as List<dynamic>?)
            ?.map((rateMap) => VendorMaterialRate(
                  vendorId: rateMap['vendorId'] ?? '',
                  baseRate: rateMap['baseRate'] ?? '',
                  purchaseRate: rateMap['purchaseRate'] ?? '',
                  lastPurchaseDate: rateMap['lastPurchaseDate'] ?? '',
                  remarks: rateMap['remarks'] ?? '',
                  isPreferred: rateMap['isPreferred'] ?? false,
                ))
            .toList() ??
        <VendorMaterialRate>[];

    return MaterialItem(
      slNo: map['slNo'] ?? '',
      description: map['description'] ?? '',
      partNo: map['partNo'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      storageLocation: map['storageLocation'],
      rackNumber: map['rackNumber'],
      binNumber: map['binNumber'],
      hsnCode: map['hsnCode'],
      actualWeight: map['actualWeight'],
      saleRate: map['saleRate'] ?? '0',
      vendorRates: vendorRatesList,
    );
  }

  @override
  String getModelId(MaterialItem material) => material.partNo;

  // Map old method names to new base provider methods
  Future<void> loadMaterials() => loadData();
  Future<void> addMaterial(MaterialItem material) => add(material);
  Future<void> updateMaterial(int index, MaterialItem material) async {
    final existingMaterial = box.getAt(index);
    if (existingMaterial != null) {
      await update(material);
    }
  }

  Future<void> deleteMaterial(MaterialItem material) => delete(material);

  // Helper methods
  List<MaterialItem> getMaterialsByCategory(String category) {
    return state.where((material) => material.category == category).toList();
  }

  List<MaterialItem> getMaterialsBySubCategory(String subCategory) {
    return state
        .where((material) => material.subCategory == subCategory)
        .toList();
  }

  MaterialItem? getMaterialBySlNo(String slNo) {
    try {
      return state.firstWhere((material) => material.slNo == slNo);
    } catch (_) {
      return null;
    }
  }

  List<MaterialItem> searchMaterials(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((material) =>
            material.description.toLowerCase().contains(lowercaseQuery) ||
            material.partNo.toLowerCase().contains(lowercaseQuery) ||
            material.category.toLowerCase().contains(lowercaseQuery) ||
            material.subCategory.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}
