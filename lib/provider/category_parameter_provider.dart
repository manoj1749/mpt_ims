import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_parameter_mapping.dart';

final categoryParameterBoxProvider =
    Provider<Box<CategoryParameterMapping>>((ref) {
  return Hive.box<CategoryParameterMapping>('categoryParameterMappings');
});

final categoryParameterProvider = StateNotifierProvider<
        CategoryParameterNotifier, List<CategoryParameterMapping>>(
    (ref) => CategoryParameterNotifier(ref.read(categoryParameterBoxProvider)));

class CategoryParameterNotifier
    extends StateNotifier<List<CategoryParameterMapping>> {
  final Box<CategoryParameterMapping> box;

  CategoryParameterNotifier(this.box) : super(box.values.toList());

  Future<void> addMapping(CategoryParameterMapping mapping) async {
    await box.add(mapping);
    state = box.values.toList();
  }

  Future<void> updateMapping(CategoryParameterMapping mapping) async {
    // Find existing mapping index
    final existingIndex = box.values.toList().indexWhere(
          (m) => m.category == mapping.category,
        );

    if (existingIndex == -1) {
      // This is a new mapping
      await box.add(mapping);
    } else {
      // Update existing mapping
      await box.putAt(existingIndex, mapping);
    }

    state = box.values.toList();
  }

  Future<void> deleteMapping(CategoryParameterMapping mapping) async {
    await mapping.delete();
    state = state.where((m) => m.key != mapping.key).toList();
  }

  CategoryParameterMapping? getMappingForCategory(String category) {
    try {
      return state.firstWhere(
        (mapping) => mapping.category == category,
      );
    } catch (e) {
      return null;
    }
  }
}
