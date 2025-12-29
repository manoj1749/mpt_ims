import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/inventory_classification.dart';
import 'base_provider.dart';

final inventoryClassificationBoxProvider = Provider<Box<InventoryClassification>>((ref) {
  throw UnimplementedError();
});

final inventoryClassificationListProvider =
    StateNotifierProvider<InventoryClassificationNotifier, List<InventoryClassification>>(
  (ref) => InventoryClassificationNotifier(ref.read(inventoryClassificationBoxProvider)),
);

class InventoryClassificationNotifier extends BaseProvider<InventoryClassification> {
  InventoryClassificationNotifier(Box<InventoryClassification> box) : super(box, 'inventory_classifications');

  @override
  Map<String, dynamic> modelToMap(InventoryClassification inventoryClassification) {
    return {
      'name': inventoryClassification.name,
      'requiresQualityCheck': inventoryClassification.requiresQualityCheck,
      'sampleSizeLessThan100': inventoryClassification.sampleSizeLessThan100,
      'sampleSize100To500': inventoryClassification.sampleSize100To500,
      'sampleSizeGreaterThan500': inventoryClassification.sampleSizeGreaterThan500,
      'hasExpiryDate': inventoryClassification.hasExpiryDate,
      'hasShelfLife': inventoryClassification.hasShelfLife,
      'shelfLifeValue': inventoryClassification.shelfLifeValue,
      'shelfLifeUnit': inventoryClassification.shelfLifeUnit,
    };
  }

  @override
  InventoryClassification mapToModel(Map<String, dynamic> map) {
    return InventoryClassification(
      name: map['name'] ?? '',
      requiresQualityCheck: map['requiresQualityCheck'] ?? true,
      sampleSizeLessThan100: map['sampleSizeLessThan100'],
      sampleSize100To500: map['sampleSize100To500'],
      sampleSizeGreaterThan500: map['sampleSizeGreaterThan500'],
      hasExpiryDate: map['hasExpiryDate'],
      hasShelfLife: map['hasShelfLife'],
      shelfLifeValue: map['shelfLifeValue'],
      shelfLifeUnit: map['shelfLifeUnit'],
    );
  }

  @override
  String getModelId(InventoryClassification inventoryClassification) => inventoryClassification.name;

  // Map old method names to new base provider methods
  Future<void> loadInventoryClassifications() => loadData();
  Future<void> addInventoryClassification(String name) => add(InventoryClassification(name: name));
  Future<void> updateInventoryClassification(InventoryClassification inventoryClassification) => update(inventoryClassification);
  Future<void> deleteInventoryClassification(InventoryClassification inventoryClassification) => delete(inventoryClassification);

  // Helper methods
  InventoryClassification? getInventoryClassificationByName(String name) {
    try {
      return state.firstWhere((inventoryClassification) => inventoryClassification.name == name);
    } catch (_) {
      return null;
    }
  }

  List<InventoryClassification> getInventoryClassificationsRequiringQC() {
    return state.where((inventoryClassification) => inventoryClassification.requiresQualityCheck).toList();
  }

  List<InventoryClassification> getInventoryClassificationsWithExpiry() {
    return state.where((inventoryClassification) => inventoryClassification.hasExpiryDate ?? false).toList();
  }

  List<InventoryClassification> getInventoryClassificationsWithShelfLife() {
    return state.where((inventoryClassification) => inventoryClassification.hasShelfLife ?? false).toList();
  }
}
