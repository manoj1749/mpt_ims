import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sub_category.dart';

final subCategoryListProvider =
    StateNotifierProvider<SubCategoryListNotifier, List<SubCategory>>((ref) {
  return SubCategoryListNotifier();
});

class SubCategoryListNotifier extends StateNotifier<List<SubCategory>> {
  SubCategoryListNotifier() : super([]) {
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    final box = await Hive.openBox<SubCategory>('subCategories');
    state = box.values.toList();
  }

  Future<void> addSubCategory(String name, String categoryName) async {
    final box = await Hive.openBox<SubCategory>('subCategories');
    final subCategory = SubCategory(name: name, categoryName: categoryName);
    await box.add(subCategory);
    state = [...state, subCategory];
  }

  Future<void> deleteSubCategory(SubCategory subCategory) async {
    final box = await Hive.openBox<SubCategory>('subCategories');
    await subCategory.delete();
    state = state.where((c) => c != subCategory).toList();
  }

  List<SubCategory> getSubCategoriesForCategory(String categoryName) {
    return state.where((sc) => sc.categoryName == categoryName).toList();
  }
} 