import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sub_category.dart';
import '../services/sync_service.dart';

final subCategoryBoxProvider = Provider<Box<SubCategory>>((ref) {
  throw UnimplementedError();
});

final subCategoryListProvider =
    StateNotifierProvider<SubCategoryListNotifier, List<SubCategory>>((ref) {
  final box = ref.watch(subCategoryBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SubCategoryListNotifier(box, syncService);
});

class SubCategoryListNotifier extends StateNotifier<List<SubCategory>> {
  final Box<SubCategory> box;
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SubCategoryListNotifier(this.box, this._syncService) : super([]) {
    // Load sub-categories when initialized
    loadSubCategories();
  }

  Future<void> loadSubCategories() async {
    try {
      print('Loading sub-categories from Firestore...');
      final querySnapshot = await _firestore.collection('sub_categories').get();
      print('Found ${querySnapshot.docs.length} sub-categories in Firestore');

      // Clear existing sub-categories from Hive
      await box.clear();

      // Add new sub-categories to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final subCategory = _subCategoryFromMap(data);
        await box.add(subCategory);
      }

      // Update state
      state = box.values.toList();
      print('Successfully loaded sub-categories');
    } catch (e) {
      print('Error loading sub-categories: $e');
      rethrow;
    }
  }

  Future<void> addSubCategory(String name, String categoryName) async {
    try {
      print('Adding sub-category: $name under category: $categoryName');
      final subCategory = SubCategory(name: name, categoryName: categoryName);

      // Add to Firestore first
      final docRef = _firestore.collection('sub_categories').doc('$categoryName-$name');
      final data = _convertToMap(subCategory);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(subCategory);

      // Update state
      state = box.values.toList();
      print('Sub-category added successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('sub_categories', box);
    } catch (e) {
      print('Error adding sub-category: $e');
      rethrow;
    }
  }

  Future<void> deleteSubCategory(SubCategory subCategory) async {
    try {
      print('Deleting sub-category: ${subCategory.name} from category: ${subCategory.categoryName}');

      // Delete from Firestore first
      final docRef = _firestore.collection('sub_categories').doc('${subCategory.categoryName}-${subCategory.name}');
      await docRef.delete();

      // Then delete from Hive
      await subCategory.delete();

      // Update state
      state = box.values.toList();
      print('Sub-category deleted successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('sub_categories', box);
    } catch (e) {
      print('Error deleting sub-category: $e');
      rethrow;
    }
  }

  List<SubCategory> getSubCategoriesForCategory(String categoryName) {
    return state.where((sc) => sc.categoryName == categoryName).toList();
  }

  Future<void> refresh() async {
    try {
      await loadSubCategories();
    } catch (e) {
      print('Error refreshing sub-categories: $e');
      rethrow;
    }
  }

  // Helper method to convert SubCategory to Map
  Map<String, dynamic> _convertToMap(SubCategory subCategory) {
    return {
      'name': subCategory.name,
      'categoryName': subCategory.categoryName,
    };
  }

  // Helper method to convert Map to SubCategory
  SubCategory _subCategoryFromMap(Map<String, dynamic> map) {
    return SubCategory(
      name: map['name'] ?? '',
      categoryName: map['categoryName'] ?? '',
    );
  }
}
