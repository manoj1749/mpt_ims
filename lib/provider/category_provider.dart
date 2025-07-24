import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';
import 'base_provider.dart';

final categoryBoxProvider = Provider<Box<Category>>((ref) {
  throw UnimplementedError();
});

final categoryListProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>(
  (ref) => CategoryNotifier(ref.read(categoryBoxProvider)),
);

class CategoryNotifier extends BaseProvider<Category> {
  CategoryNotifier(Box<Category> box) : super(box, 'categories');

  @override
  Map<String, dynamic> modelToMap(Category category) {
    return {
      'name': category.name,
      'requiresQualityCheck': category.requiresQualityCheck,
      'sampleSizeLessThan100': category.sampleSizeLessThan100,
      'sampleSize100To500': category.sampleSize100To500,
      'sampleSizeGreaterThan500': category.sampleSizeGreaterThan500,
      'hasExpiryDate': category.hasExpiryDate,
      'hasShelfLife': category.hasShelfLife,
      'shelfLifeValue': category.shelfLifeValue,
      'shelfLifeUnit': category.shelfLifeUnit,
    };
  }

  @override
  Category mapToModel(Map<String, dynamic> map) {
    return Category(
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
  String getModelId(Category category) => category.name;

  // Map old method names to new base provider methods
  Future<void> loadCategories() => loadData();
  Future<void> addCategory(String name) => add(Category(name: name));
  Future<void> updateCategory(Category category) => update(category);
  Future<void> deleteCategory(Category category) => delete(category);

  // Helper methods
  Category? getCategoryByName(String name) {
    try {
      return state.firstWhere((category) => category.name == name);
    } catch (_) {
      return null;
    }
  }

  List<Category> getCategoriesRequiringQC() {
    return state.where((category) => category.requiresQualityCheck).toList();
  }

  List<Category> getCategoriesWithExpiry() {
    return state.where((category) => category.hasExpiryDate ?? false).toList();
  }

  List<Category> getCategoriesWithShelfLife() {
    return state.where((category) => category.hasShelfLife ?? false).toList();
  }
}
