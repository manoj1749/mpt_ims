import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, List<Category>>((ref) {
  return CategoryListNotifier();
});

class CategoryListNotifier extends StateNotifier<List<Category>> {
  CategoryListNotifier() : super([]) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final box = await Hive.openBox<Category>('categories');
    state = box.values.toList();
  }

  Future<void> addCategory(String name) async {
    final box = await Hive.openBox<Category>('categories');
    final category = Category(name: name);
    await box.add(category);
    state = [...state, category];
  }

  Future<void> deleteCategory(Category category) async {
    final box = await Hive.openBox<Category>('categories');
    await category.delete();
    state = state.where((c) => c != category).toList();
  }
} 