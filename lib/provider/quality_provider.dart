import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quality.dart';

final qualityBoxProvider =
    Provider<Box<Quality>>((ref) => throw UnimplementedError());

final qualityListProvider =
    StateNotifierProvider<QualityListNotifier, List<Quality>>((ref) {
  final box = ref.watch(qualityBoxProvider);
  return QualityListNotifier(box);
});

class QualityListNotifier extends StateNotifier<List<Quality>> {
  final Box<Quality> box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  QualityListNotifier(this.box) : super([]) {
    // Load quality data when initialized
    loadQualities();
  }

  Future<void> loadQualities() async {
    try {
      print('Loading qualities from Firestore...');
      final querySnapshot = await _firestore.collection('qualities').get();
      print('Found ${querySnapshot.docs.length} qualities in Firestore');

      // Clear existing qualities from Hive
      await box.clear();

      // Add new qualities to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final quality = _qualityFromMap(data);
        await box.add(quality);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded qualities');
    } catch (e) {
      print('Error loading qualities: $e');
      rethrow;
    }
  }

  Future<void> addQuality(String name) async {
    try {
      print('Adding quality: $name');
      final quality = Quality(name: name);

      // Add to Firestore first
      final docRef = _firestore.collection('qualities').doc();
      final data = _qualityToMap(quality);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(quality);

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Quality added successfully');
    } catch (e) {
      print('Error adding quality: $e');
      rethrow;
    }
  }

  Future<void> deleteQuality(Quality quality) async {
    try {
      print('Deleting quality: ${quality.name}');

      // Find and delete from Firestore first
      final querySnapshot = await _firestore
          .collection('qualities')
          .where('name', isEqualTo: quality.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      // Then delete from Hive
      await quality.delete();

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Quality deleted successfully');
    } catch (e) {
      print('Error deleting quality: $e');
      rethrow;
    }
  }

  // Public alias for loadQualities to maintain consistency with other providers
  Future<void> refresh() async {
    await loadQualities();
  }

  // Helper method to convert Quality to Map
  Map<String, dynamic> _qualityToMap(Quality quality) {
    return {
      'name': quality.name,
    };
  }

  // Helper method to convert Map to Quality
  Quality _qualityFromMap(Map<String, dynamic> map) {
    return Quality(
      name: map['name'] ?? '',
    );
  }
}
