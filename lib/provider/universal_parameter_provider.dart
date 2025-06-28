import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/universal_parameter.dart';
import '../services/sync_service.dart';

// Box provider for dependency injection
final universalParameterBoxProvider = Provider<Box<UniversalParameter>>((ref) {
  throw UnimplementedError();
});

class UniversalParameterNotifier
    extends StateNotifier<List<UniversalParameter>> {
  final Box<UniversalParameter> _box;
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UniversalParameterNotifier(this._box, this._syncService) : super([]) {
    // Load parameters when initialized
    loadParameters();
  }

  Future<void> loadParameters() async {
    try {
      print('Loading universal parameters from Firestore...');
      final querySnapshot = await _firestore.collection('universalParameters').get();
      print('Found ${querySnapshot.docs.length} parameters in Firestore');

      // Clear existing parameters from Hive
      await _box.clear();

      // Add new parameters to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final parameter = _parameterFromMap(data);
        await _box.add(parameter);
      }

      // Update state
      state = _box.values.toList();
      print('Successfully loaded universal parameters');
    } catch (e) {
      print('Error loading universal parameters: $e');
      rethrow;
    }
  }

  Future<void> addParameter(String name) async {
    try {
      print('Adding universal parameter: $name');
      final parameter = UniversalParameter(name: name);

      // Add to Firestore first
      final docRef = _firestore.collection('universalParameters').doc(name);
      final data = _convertToMap(parameter);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await _box.add(parameter);

      // Update state
      state = _box.values.toList();
      print('Universal parameter added successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('universalParameters', _box);
    } catch (e) {
      print('Error adding universal parameter: $e');
      rethrow;
    }
  }

  Future<void> removeParameter(UniversalParameter parameter) async {
    try {
      print('Removing universal parameter: ${parameter.name}');

      // Delete from Firestore first
      final docRef = _firestore.collection('universalParameters').doc(parameter.name);
      await docRef.delete();

      // Then delete from Hive
      await parameter.delete();

      // Update state
      state = _box.values.toList();
      print('Universal parameter removed successfully');

      // Keep existing sync for backward compatibility
      await _syncService.syncToFirestore('universalParameters', _box);
    } catch (e) {
      print('Error removing universal parameter: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await loadParameters();
    } catch (e) {
      print('Error refreshing universal parameters: $e');
      rethrow;
    }
  }

  // Helper method to convert UniversalParameter to Map
  Map<String, dynamic> _convertToMap(UniversalParameter parameter) {
    return {
      'name': parameter.name,
    };
  }

  // Helper method to convert Map to UniversalParameter
  UniversalParameter _parameterFromMap(Map<String, dynamic> map) {
    return UniversalParameter(
      name: map['name'] ?? '',
    );
  }
}

final universalParameterProvider =
    StateNotifierProvider<UniversalParameterNotifier, List<UniversalParameter>>(
        (ref) {
  final box = ref.watch(universalParameterBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return UniversalParameterNotifier(box, syncService);
});
