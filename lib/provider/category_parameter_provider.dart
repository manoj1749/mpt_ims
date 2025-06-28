import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_parameter_mapping.dart';
import '../services/sync_service.dart';
import 'supplier_provider.dart';  // Import for syncServiceProvider

final categoryParameterBoxProvider =
    Provider<Box<CategoryParameterMapping>>((ref) {
  throw UnimplementedError();
});

final categoryParameterProvider = StateNotifierProvider<
        CategoryParameterNotifier, List<CategoryParameterMapping>>(
    (ref) => CategoryParameterNotifier(ref.read(categoryParameterBoxProvider)));

class CategoryParameterNotifier
    extends StateNotifier<List<CategoryParameterMapping>> {
  final Box<CategoryParameterMapping> box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CategoryParameterNotifier(this.box) : super([]) {
    // Load mappings when initialized
    loadMappings();
  }

  Future<void> loadMappings() async {
    try {
      print('Loading category parameter mappings from Firestore...');
      final querySnapshot = await _firestore.collection('category_parameter_mappings').get();
      print('Found ${querySnapshot.docs.length} mappings in Firestore');

      // Clear existing mappings from Hive
      await box.clear();

      // Add new mappings to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final mapping = _mappingFromMap(data);
        await box.add(mapping);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded category parameter mappings');
    } catch (e) {
      print('Error loading category parameter mappings: $e');
      rethrow;
    }
  }

  Future<void> addMapping(CategoryParameterMapping mapping) async {
    try {
      print('Adding mapping for category: ${mapping.category}');

      // Add to Firestore first
      final docRef = _firestore.collection('category_parameter_mappings').doc();
      final data = _mappingToMap(mapping);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(mapping);

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Mapping added successfully');
    } catch (e) {
      print('Error adding mapping: $e');
      rethrow;
    }
  }

  Future<void> updateMapping(CategoryParameterMapping mapping) async {
    try {
      print('Updating mapping for category: ${mapping.category}');

      // Find and update in Firestore first
      final querySnapshot = await _firestore
          .collection('category_parameter_mappings')
          .where('category', isEqualTo: mapping.category)
          .get();

      final data = _mappingToMap(mapping);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        await querySnapshot.docs.first.reference.update(data);
      } else {
        // Create new document
        await _firestore.collection('category_parameter_mappings').doc().set(data);
      }

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

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Mapping updated successfully');
    } catch (e) {
      print('Error updating mapping: $e');
      rethrow;
    }
  }

  Future<void> deleteMapping(CategoryParameterMapping mapping) async {
    try {
      print('Deleting mapping for category: ${mapping.category}');

      // Find and delete from Firestore first
      final querySnapshot = await _firestore
          .collection('category_parameter_mappings')
          .where('category', isEqualTo: mapping.category)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      // Then delete from Hive
      await mapping.delete();

      // Update state
      if (mounted) {
        state = state.where((m) => m.key != mapping.key).toList();
      }
      print('Mapping deleted successfully');
    } catch (e) {
      print('Error deleting mapping: $e');
      rethrow;
    }
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

  // Public alias for loadMappings to maintain consistency with other providers
  Future<void> refresh() async {
    await loadMappings();
  }

  // Helper method to convert CategoryParameterMapping to Map
  Map<String, dynamic> _mappingToMap(CategoryParameterMapping mapping) {
    return {
      'category': mapping.category,
      'parameters': mapping.parameters,
      'requiresExpiryDate': mapping.requiresExpiryDate,
    };
  }

  // Helper method to convert Map to CategoryParameterMapping
  CategoryParameterMapping _mappingFromMap(Map<String, dynamic> map) {
    return CategoryParameterMapping(
      category: map['category'] ?? '',
      parameters: List<String>.from(map['parameters'] ?? []),
      requiresExpiryDate: map['requiresExpiryDate'] ?? false,
    );
  }
}
