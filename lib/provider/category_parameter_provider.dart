import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category_parameter_mapping.dart';
import 'base_provider.dart';
import 'quality_inspection_provider.dart';

final categoryParameterBoxProvider =
    Provider<Box<CategoryParameterMapping>>((ref) {
  throw UnimplementedError();
});

final categoryParameterProvider = StateNotifierProvider<
        CategoryParameterNotifier, List<CategoryParameterMapping>>(
    (ref) => CategoryParameterNotifier(
        ref.read(categoryParameterBoxProvider),
        ref.read(qualityInspectionProvider.notifier)));

class CategoryParameterNotifier extends BaseProvider<CategoryParameterMapping> {
  final QualityInspectionNotifier _qualityInspectionNotifier;

  CategoryParameterNotifier(Box<CategoryParameterMapping> box, this._qualityInspectionNotifier)
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
    // Get existing mapping to compare parameters (clone to avoid reference mutation issues)
    final existingMappingRef = getMappingForCategory(mapping.category);
    final existingMapping = existingMappingRef == null
        ? null
        : CategoryParameterMapping(
            category: existingMappingRef.category,
            parameters: List<String>.from(existingMappingRef.parameters),
            requiresExpiryDate: existingMappingRef.requiresExpiryDate,
            lastModified: existingMappingRef.lastModified,
          );

    // Update timestamp to track when parameters changed
    mapping.updateTimestamp();

    print('DEBUG: updateMapping called for category: ${mapping.category}');
    print('DEBUG: New lastModified: ${mapping.lastModified}');
    print('DEBUG: Existing mapping snapshot lastModified: ${existingMapping?.lastModified}');

    // Check if mapping already exists
    final existingIndex =
        state.indexWhere((m) => m.category == mapping.category);

    if (existingIndex == -1) {
      // This is a new mapping
      print('DEBUG: Adding new mapping for category: ${mapping.category}');
      await add(mapping);
    } else {
      // Update existing mapping
      print('DEBUG: Updating existing mapping for category: ${mapping.category}');
      await update(mapping);

      // Check if parameters have changed and reset affected inspections
      if (existingMapping != null && _parametersChanged(existingMapping, mapping)) {
        print('DEBUG: Parameters changed for category: ${mapping.category}, resetting inspections');
        await _resetInspectionsForCategory(mapping.category);
      } else {
        print('DEBUG: Parameters did not change for category: ${mapping.category}');
      }
    }
  }

  // Check if parameters have actually changed
  bool _parametersChanged(CategoryParameterMapping oldMapping, CategoryParameterMapping newMapping) {
    // Compare parameters list (order matters for quality control)
    if (oldMapping.parameters.length != newMapping.parameters.length) {
      return true;
    }

    for (int i = 0; i < oldMapping.parameters.length; i++) {
      if (oldMapping.parameters[i] != newMapping.parameters[i]) {
        return true;
      }
    }

    // Check if expiry date requirement changed
    if (oldMapping.requiresExpiryDate != newMapping.requiresExpiryDate) {
      return true;
    }

    return false;
  }

  // Reset completed inspections to pending when parameters change
  Future<void> _resetInspectionsForCategory(String category) async {
    final inspections = _qualityInspectionNotifier.state;
    print('DEBUG: Checking ${inspections.length} inspections for category: $category');

    for (final inspection in inspections) {
      // Check if this inspection has items from the modified category
      final hasCategoryItems = inspection.items.any((item) => item.category == category);
      print('DEBUG: Inspection ${inspection.inspectionNo} has category items: $hasCategoryItems, status: ${inspection.status}, category: $category');

      if (hasCategoryItems && inspection.status.startsWith('Completed')) {
        // Check if inspection was validated before parameters changed
        final validationTimestamp = inspection.parameterValidationTimestamp;
        final categoryMapping = getMappingForCategory(category);

        print('DEBUG: Inspection ${inspection.inspectionNo} validation timestamp: $validationTimestamp');
        print('DEBUG: Category mapping lastModified: ${categoryMapping?.lastModified}');

        if (validationTimestamp != null && categoryMapping != null) {
          final validationTime = DateTime.parse(validationTimestamp);
          final paramChangeTime = DateTime.parse(categoryMapping.lastModified);

          print('DEBUG: Validation time: $validationTime, Param change time: $paramChangeTime');
          print('DEBUG: Is param change after validation? ${paramChangeTime.isAfter(validationTime)}');

          // If parameters were changed after validation, reset inspection
          if (paramChangeTime.isAfter(validationTime)) {
            await _qualityInspectionNotifier.updateInspectionStatus(
              inspection.inspectionNo,
              'Pending - Parameters Changed'
            );
            print('Reset inspection ${inspection.inspectionNo} to pending - parameters changed after validation');
          }
        } else {
          // If no validation timestamp or mapping, reset as fallback
          await _qualityInspectionNotifier.updateInspectionStatus(
            inspection.inspectionNo,
            'Pending - Parameters Changed'
          );
          print('Reset inspection ${inspection.inspectionNo} to pending - missing validation timestamp or mapping');
        }
      }
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
