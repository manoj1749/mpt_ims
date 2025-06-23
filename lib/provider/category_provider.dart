import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';

final categoryBoxProvider =
    Provider<Box<Category>>((ref) => throw UnimplementedError());

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, List<Category>>((ref) {
  final box = ref.watch(categoryBoxProvider);
  return CategoryListNotifier(box);
});

class CategoryListNotifier extends StateNotifier<List<Category>> {
  final Box<Category> box;

  CategoryListNotifier(this.box) : super(box.values.toList());

  Future<void> addCategory(String name) async {
    final category = Category(
      name: name,
      requiresQualityCheck: true,
    );
    await box.add(category);
    state = box.values.toList();
  }

  Future<void> deleteCategory(Category category) async {
    await category.delete();
    state = box.values.toList();
  }

  Future<void> updateCategory(Category category) async {
    // Find the existing category with the same name
    final existingCategory = box.values.firstWhere(
      (c) => c.name == category.name,
      orElse: () => category,
    );
    
    // Get the key from the existing category or generate a new one
    final key = existingCategory.key ?? await box.add(category);
    
    // Update the category
    await box.put(key, category);
    state = box.values.toList();
  }
}
