import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';
import '../services/sync_service.dart';


final categoryBoxProvider =
    Provider<Box<Category>>((ref) => throw UnimplementedError());

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, List<Category>>((ref) {
  final box = ref.watch(categoryBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return CategoryListNotifier(box, syncService);
});

class CategoryListNotifier extends StateNotifier<List<Category>> {
  final Box<Category> box;
  final SyncService _syncService;

  CategoryListNotifier(this.box, this._syncService) : super(box.values.toList());

  Future<void> addCategory(String name) async {
    final category = Category(
      name: name,
      requiresQualityCheck: true,
    );
    await box.add(category);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> deleteCategory(Category category) async {
    await category.delete();
    state = box.values.toList();
    await _syncToFirebase();
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
    await _syncToFirebase();
  }

  Future<void> refresh() async {
    await _syncFromFirebase();
    state = box.values.toList();
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('categories', box);
    } catch (e) {
      print('Error syncing categories to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'categories',
        box,
        _syncService.categoryFromMap,
      );
    } catch (e) {
      print('Error syncing categories from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
