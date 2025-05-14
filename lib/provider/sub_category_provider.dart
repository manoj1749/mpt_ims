import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/sub_category.dart';

final subCategoryBoxProvider =
    Provider<Box<SubCategory>>((ref) => throw UnimplementedError());

final subCategoryListProvider =
    StateNotifierProvider<SubCategoryListNotifier, List<SubCategory>>((ref) {
  final box = ref.watch(subCategoryBoxProvider);
  return SubCategoryListNotifier(box);
});

class SubCategoryListNotifier extends StateNotifier<List<SubCategory>> {
  final Box<SubCategory> box;

  SubCategoryListNotifier(this.box) : super(box.values.toList());

  Future<void> addSubCategory(String name, String categoryName) async {
    final subCategory = SubCategory(name: name, categoryName: categoryName);
    await box.add(subCategory);
    state = box.values.toList();
  }

  Future<void> deleteSubCategory(SubCategory subCategory) async {
    await subCategory.delete();
    state = box.values.toList();
  }

  List<SubCategory> getSubCategoriesForCategory(String categoryName) {
    return state.where((sc) => sc.categoryName == categoryName).toList();
  }
}
