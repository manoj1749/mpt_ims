import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/sub_category.dart';
import '../services/sync_service.dart';
import 'supplier_provider.dart';  // Import for syncServiceProvider

final subCategoryBoxProvider =
    Provider<Box<SubCategory>>((ref) => throw UnimplementedError());

final subCategoryListProvider =
    StateNotifierProvider<SubCategoryListNotifier, List<SubCategory>>((ref) {
  final box = ref.watch(subCategoryBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SubCategoryListNotifier(box, syncService);
});

class SubCategoryListNotifier extends StateNotifier<List<SubCategory>> {
  final Box<SubCategory> box;
  final SyncService _syncService;

  SubCategoryListNotifier(this.box, this._syncService) : super(box.values.toList());

  Future<void> addSubCategory(String name, String categoryName) async {
    final subCategory = SubCategory(name: name, categoryName: categoryName);
    await box.add(subCategory);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> deleteSubCategory(SubCategory subCategory) async {
    await subCategory.delete();
    state = box.values.toList();
    await _syncToFirebase();
  }

  List<SubCategory> getSubCategoriesForCategory(String categoryName) {
    return state.where((sc) => sc.categoryName == categoryName).toList();
  }

  Future<void> refresh() async {
    await _syncFromFirebase();
    state = box.values.toList();
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('sub_categories', box);
    } catch (e) {
      print('Error syncing sub-categories to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'sub_categories',
        box,
        _syncService.subCategoryFromMap,
      );
    } catch (e) {
      print('Error syncing sub-categories from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
