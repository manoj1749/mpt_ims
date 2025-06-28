import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CategoryListNotifier(this.box, this._syncService) : super([]) {
    // Load categories when initialized
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      print('Loading categories from Firestore...');
      final querySnapshot = await _firestore.collection('categories').get();
      print('Found ${querySnapshot.docs.length} categories in Firestore');

      // Clear existing categories from Hive
      await box.clear();

      // Add new categories to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final category = _categoryFromMap(data);
        await box.add(category);
      }

      // Update state
      state = box.values.toList();
      print('Successfully loaded categories');
    } catch (e) {
      print('Error loading categories: $e');
      rethrow;
    }
  }

  Future<void> addCategory(String name) async {
    try {
      print('Adding category: $name');
      final category = Category(
        name: name,
        requiresQualityCheck: true,
      );

      // Add to Firestore first with auto-generated ID
      final docRef = _firestore.collection('categories').doc();
      final data = _convertToMap(category);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(category);

      // Update state
      state = box.values.toList();
      print('Category added successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('categories', box);
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(Category category) async {
    try {
      print('Deleting category: ${category.name}');

      // Find and delete from Firestore first
      final querySnapshot = await _firestore
          .collection('categories')
          .where('name', isEqualTo: category.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      // Then delete from Hive
      await category.delete();

      // Update state
      state = box.values.toList();
      print('Category deleted successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('categories', box);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      print('Updating category: ${category.name}');

      // Find the existing category with the same name
      final existingCategory = box.values.firstWhere(
        (c) => c.name == category.name,
        orElse: () => category,
      );

      // Find and update in Firestore first
      final querySnapshot = await _firestore
          .collection('categories')
          .where('name', isEqualTo: category.name)
          .get();

      final data = _convertToMap(category);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        await querySnapshot.docs.first.reference.update(data);
      } else {
        // Create new document with auto-generated ID
        await _firestore.collection('categories').doc().set(data);
      }

      // Then update in Hive
      final key = existingCategory.key ?? await box.add(category);
      await box.put(key, category);

      // Update state
      state = box.values.toList();
      print('Category updated successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('categories', box);
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await loadCategories();
    } catch (e) {
      print('Error refreshing categories: $e');
      rethrow;
    }
  }

  // Helper method to convert Category to Map
  Map<String, dynamic> _convertToMap(Category category) {
    return {
      'name': category.name,
      'requiresQualityCheck': category.requiresQualityCheck,
    };
  }

  // Helper method to convert Map to Category
  Category _categoryFromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'] ?? '',
      requiresQualityCheck: map['requiresQualityCheck'] ?? true,
    );
  }
}
