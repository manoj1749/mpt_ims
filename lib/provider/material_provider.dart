import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/material_item.dart';

final materialBoxProvider = Provider<Box<MaterialItem>>((ref) {
  throw UnimplementedError(); // Overridden in main
});

final materialListProvider =
    StateNotifierProvider<MaterialNotifier, List<MaterialItem>>(
  (ref) => MaterialNotifier(ref.read(materialBoxProvider)),
);

class MaterialNotifier extends StateNotifier<List<MaterialItem>> {
  final Box<MaterialItem> box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MaterialNotifier(this.box) : super([]) {
    // Load data when initialized
    loadMaterials();
  }

  Future<void> loadMaterials() async {
    try {
      print('Loading materials from Firestore...');
      final querySnapshot = await _firestore.collection('materials').get();
      print('Found ${querySnapshot.docs.length} materials in Firestore');

      // Clear existing materials from Hive
      await box.clear();

      // Add new materials to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final material = _materialFromMap(data);
        await box.add(material);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded materials');
    } catch (e) {
      print('Error loading materials: $e');
      rethrow;
    }
  }

  Future<void> addMaterial(MaterialItem item) async {
    try {
      print('Adding material: ${item.partNo}');
      
      // Add to Firestore first
      final docRef = _firestore.collection('materials').doc(item.partNo);
      final data = _convertToMap(item);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(item);

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Material added successfully');
    } catch (e) {
      print('Error adding material: $e');
      rethrow;
    }
  }

  Future<void> updateMaterial(int index, MaterialItem updatedItem) async {
    try {
      print('Updating material: ${updatedItem.partNo}');
      if (index >= 0 && index < box.length) {
        // Update in Firestore first
        final docRef = _firestore.collection('materials').doc(updatedItem.partNo);
        final data = _convertToMap(updatedItem);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);

        // Then update in Hive
        await box.putAt(index, updatedItem);

        // Update state
        if (mounted) {
          state = box.values.toList();
        }
        print('Material updated successfully');
      }
    } catch (e) {
      print('Error updating material: $e');
      rethrow;
    }
  }

  Future<void> deleteMaterial(MaterialItem material) async {
    try {
      print('Deleting material: ${material.partNo}');
      final index = box.values.toList().indexWhere((m) => m.slNo == material.slNo);
      if (index != -1) {
        // Delete from Firestore first
        final docRef = _firestore.collection('materials').doc(material.partNo);
        await docRef.delete();

        // Then delete from Hive
        await box.deleteAt(index);

        // Update state
        if (mounted) {
          state = box.values.toList();
        }
        print('Material deleted successfully');
      }
    } catch (e) {
      print('Error deleting material: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await loadMaterials();
    } catch (e) {
      print('Error refreshing materials: $e');
      rethrow;
    }
  }

  // Convert Material to Map for Firestore
  Map<String, dynamic> _convertToMap(MaterialItem item) {
    return {
      'slNo': item.slNo,
      'description': item.description,
      'partNo': item.partNo,
      'unit': item.unit,
      'category': item.category,
      'subCategory': item.subCategory,
      'storageLocation': item.storageLocation ?? '',
      'rackNumber': item.rackNumber ?? '',
      'actualWeight': item.actualWeight ?? '',
    };
  }

  // Convert Firestore Map to Material
  MaterialItem _materialFromMap(Map<String, dynamic> map) {
    return MaterialItem(
      slNo: map['slNo'] ?? '',
      description: map['description'] ?? '',
      partNo: map['partNo'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      storageLocation: map['storageLocation'] ?? '',
      rackNumber: map['rackNumber'] ?? '',
      actualWeight: map['actualWeight'] ?? '',
    );
  }
}
