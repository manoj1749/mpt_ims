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
    final category = Category(name: name);
    await box.add(category);
    state = box.values.toList();
  }

  Future<void> deleteCategory(Category category) async {
    await category.delete();
    state = box.values.toList();
  }
}
