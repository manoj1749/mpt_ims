import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/sub_category.dart';
import 'base_provider.dart';

final subCategoryBoxProvider = Provider<Box<SubCategory>>((ref) {
  throw UnimplementedError();
});

final subCategoryListProvider =
    StateNotifierProvider<SubCategoryNotifier, List<SubCategory>>(
  (ref) => SubCategoryNotifier(ref.read(subCategoryBoxProvider)),
);

class SubCategoryNotifier extends BaseProvider<SubCategory> {
  SubCategoryNotifier(Box<SubCategory> box) : super(box, 'subCategories');

  @override
  Map<String, dynamic> modelToMap(SubCategory subCategory) {
    return {
      'name': subCategory.name,
      'categoryName': subCategory.categoryName,
    };
  }

  @override
  SubCategory mapToModel(Map<String, dynamic> map) {
    return SubCategory(
      name: map['name'] ?? '',
      categoryName: map['categoryName'] ?? '',
    );
  }

  @override
  String getModelId(SubCategory subCategory) => '${subCategory.categoryName}_${subCategory.name}';

  // Map old method names to new base provider methods
  Future<void> loadSubCategories() => loadData();
  Future<void> addSubCategory(String name, String categoryName) => 
      add(SubCategory(name: name, categoryName: categoryName));
  Future<void> deleteSubCategory(SubCategory subCategory) => delete(subCategory);

  // Helper methods
  List<SubCategory> getSubCategoriesForCategory(String categoryName) {
    return state.where((subCategory) => subCategory.categoryName == categoryName).toList();
  }
}
