import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_parameter_mapping.dart';

final categoryParameterProvider =
    StateNotifierProvider<CategoryParameterNotifier, List<CategoryParameterMapping>>(
        (ref) => CategoryParameterNotifier());

class CategoryParameterNotifier
    extends StateNotifier<List<CategoryParameterMapping>> {
  CategoryParameterNotifier() : super([]) {
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    final box = await Hive.openBox<CategoryParameterMapping>('category_parameters');
    state = box.values.toList();
  }

  Future<void> addMapping(CategoryParameterMapping mapping) async {
    final box = await Hive.openBox<CategoryParameterMapping>('category_parameters');
    await box.add(mapping);
    state = [...state, mapping];
  }

  Future<void> updateMapping(CategoryParameterMapping mapping) async {
    final box = await Hive.openBox<CategoryParameterMapping>('category_parameters');
    
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
    final box = await Hive.openBox<CategoryParameterMapping>('category_parameters');
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