import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category_parameter_mapping.dart';
import '../services/sync_service.dart';
import 'supplier_provider.dart';  // Import for syncServiceProvider

final categoryParameterBoxProvider =
    Provider<Box<CategoryParameterMapping>>((ref) {
  throw UnimplementedError();
});

final categoryParameterProvider = StateNotifierProvider<
        CategoryParameterNotifier, List<CategoryParameterMapping>>(
    (ref) => CategoryParameterNotifier(
      ref.read(categoryParameterBoxProvider),
      ref.read(syncServiceProvider),
    ));

class CategoryParameterNotifier
    extends StateNotifier<List<CategoryParameterMapping>> {
  final Box<CategoryParameterMapping> box;
  final SyncService _syncService;

  CategoryParameterNotifier(this.box, this._syncService) : super(box.values.toList());

  Future<void> addMapping(CategoryParameterMapping mapping) async {
    await box.add(mapping);
    state = box.values.toList();
    await _syncToFirebase();
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
    await _syncToFirebase();
  }

  Future<void> deleteMapping(CategoryParameterMapping mapping) async {
    await mapping.delete();
    state = state.where((m) => m.key != mapping.key).toList();
    await _syncToFirebase();
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

  Future<void> refresh() async {
    await _syncFromFirebase();
    state = box.values.toList();
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('category_parameter_mappings', box);
    } catch (e) {
      print('Error syncing category parameter mappings to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'category_parameter_mappings',
        box,
        _syncService.categoryParameterMappingFromMap,
      );
    } catch (e) {
      print('Error syncing category parameter mappings from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
