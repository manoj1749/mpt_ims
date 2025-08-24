import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category_parameter_mapping.dart';
import 'base_provider.dart';

final categoryParameterBoxProvider =
    Provider<Box<CategoryParameterMapping>>((ref) {
  throw UnimplementedError();
});

final categoryParameterProvider = StateNotifierProvider<
        CategoryParameterNotifier, List<CategoryParameterMapping>>(
    (ref) => CategoryParameterNotifier(ref.read(categoryParameterBoxProvider)));

class CategoryParameterNotifier extends BaseProvider<CategoryParameterMapping> {
  CategoryParameterNotifier(Box<CategoryParameterMapping> box)
      : super(box, 'category_parameter_mappings');

  @override
  Map<String, dynamic> modelToMap(CategoryParameterMapping mapping) {
    return {
      'category': mapping.category,
      'parameters': mapping.parameters,
      'requiresExpiryDate': mapping.requiresExpiryDate,
    };
  }

  @override
  CategoryParameterMapping mapToModel(Map<String, dynamic> map) {
    return CategoryParameterMapping(
      category: map['category'] ?? '',
      parameters: List<String>.from(map['parameters'] ?? []),
      requiresExpiryDate: map['requiresExpiryDate'] ?? false,
    );
  }

  @override
  String getModelId(CategoryParameterMapping mapping) => mapping.category;

  // Backward compatibility methods
  Future<void> loadMappings() => loadData();
  Future<void> addMapping(CategoryParameterMapping mapping) => add(mapping);

  Future<void> updateMapping(CategoryParameterMapping mapping) async {
    // Check if mapping already exists
    final existingIndex =
        state.indexWhere((m) => m.category == mapping.category);

    if (existingIndex == -1) {
      // This is a new mapping
      await add(mapping);
    } else {
      // Update existing mapping
      await update(mapping);
    }
  }

  Future<void> deleteMapping(CategoryParameterMapping mapping) async {
    await delete(mapping);
  }

  // Helper methods
  CategoryParameterMapping? getMappingForCategory(String category) {
    try {
      return state.firstWhere((mapping) => mapping.category == category);
    } catch (e) {
      return null;
    }
  }

  List<CategoryParameterMapping> searchMappings(String query) {
    return search(
        query,
        (mapping, query) =>
            mapping.category.toLowerCase().contains(query) ||
            mapping.parameters
                .any((param) => param.toLowerCase().contains(query)));
  }
}
