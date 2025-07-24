import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart'; // Added for WidgetsBinding

abstract class BaseProvider<T> extends StateNotifier<List<T>> {
  final Box<T> box;
  final String collectionName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoaded = false;
  bool _isLoading = false;

  BaseProvider(this.box, this.collectionName) : super([]) {
    // Start with empty state - data will be loaded when needed
    // This ensures we always fetch fresh data from Firebase first
    
    // Auto-load data immediately
    _autoLoadData();
  }

  void _autoLoadData() {
    // Load data asynchronously without blocking constructor
    Future.microtask(() async {
      if (!_isLoaded && !_isLoading) {
        await loadData();
      }
    });
  }

  // Convert model to Map
  Map<String, dynamic> modelToMap(T model);

  // Convert Map to model
  T mapToModel(Map<String, dynamic> map);

  // Get unique identifier for the model
  String getModelId(T model);

  Future<void> loadData() async {
    if (_isLoading) return; // Prevent concurrent loading
    _isLoading = true;

    // Always try to load fresh data from Firebase first
    try {
      print('Loading fresh data from Firebase for $collectionName...');
      
      // Fetch from Firestore
      final querySnapshot = await _firestore.collection(collectionName).get();
      print('Found ${querySnapshot.docs.length} documents in Firebase for $collectionName');
      
      // Clear existing local data
      await box.clear();
      
      final List<T> firebaseData = [];
      
      // Add new data to Hive (for offline caching)
      for (var doc in querySnapshot.docs) {
        try {
          final model = mapToModel(doc.data());
          await box.add(model);
          firebaseData.add(model);
        } catch (e) {
          print('Error parsing document ${doc.id} in $collectionName: $e');
        }
      }

      // Update state with fresh Firebase data
      if (mounted) {
        state = firebaseData;
        _isLoaded = true;
        print('Successfully loaded ${firebaseData.length} items from Firebase for $collectionName');
      }
      
    } catch (e) {
      print('Error loading from Firebase for $collectionName: $e');
      
      // Fallback: Load from local Hive cache if Firebase fails
      print('Falling back to local cache for $collectionName...');
      final localData = box.values.toList();
      
      if (localData.isNotEmpty && mounted) {
        state = localData;
        _isLoaded = true;
        print('Loaded ${localData.length} items from local cache for $collectionName');
      } else {
        print('No local cache available for $collectionName');
        state = [];
        _isLoaded = true;
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> add(T model) async {
    try {
      // 1. Add to local state immediately (optimistic update)
      state = [...state, model];
      
      // 2. Add to local Hive cache
      await box.add(model);
      
      // 3. Sync to Firebase in background
      final data = modelToMap(model);
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = _auth.currentUser?.email ?? 'unknown';
      
      await _firestore.collection(collectionName).doc(getModelId(model)).set(data);
      
      print('Successfully added ${getModelId(model)} to $collectionName');
    } catch (e) {
      print('Error adding to $collectionName: $e');
      // Revert optimistic update on error
      await refresh();
      rethrow;
    }
  }

  Future<void> update(T model) async {
    try {
      // 1. Update in local state immediately
      final index = state.indexWhere((item) => getModelId(item) == getModelId(model));
      if (index != -1) {
        final newState = [...state];
        newState[index] = model;
        state = newState;
      }
      
      // 2. Update in local Hive cache
      // Find and remove existing model
      final existingIndex = box.values.toList().indexWhere((item) => getModelId(item) == getModelId(model));
      if (existingIndex != -1) {
        await box.deleteAt(existingIndex);
      }
      await box.add(model);
      
      // 3. Sync to Firebase in background
      final data = modelToMap(model);
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['updatedBy'] = _auth.currentUser?.email ?? 'unknown';
      
      await _firestore.collection(collectionName).doc(getModelId(model)).update(data);
      
      print('Successfully updated ${getModelId(model)} in $collectionName');
    } catch (e) {
      print('Error updating in $collectionName: $e');
      // Revert optimistic update on error
      await refresh();
      rethrow;
    }
  }

  Future<bool> delete(T model) async {
    try {
      final modelId = getModelId(model);
      
      // 1. Remove from local state immediately
      state = state.where((item) => getModelId(item) != modelId).toList();
      
      // 2. Remove from local Hive cache
      final existingIndex = box.values.toList().indexWhere((item) => getModelId(item) == modelId);
      if (existingIndex != -1) {
        await box.deleteAt(existingIndex);
      }
      
      // 3. Delete from Firebase in background
      await _firestore.collection(collectionName).doc(modelId).delete();
      
      print('Successfully deleted $modelId from $collectionName');
      return true;
    } catch (e) {
      print('Error deleting from $collectionName: $e');
      // Revert optimistic update on error
      await refresh();
      return false;
    }
  }

  // Force refresh data from Firebase
  Future<void> refresh() async {
    _isLoaded = false;
    await loadData();
  }

  // Optional: Search functionality
  List<T> search(String query, bool Function(T item, String query) matcher) {
    final lowercaseQuery = query.toLowerCase();
    return state.where((item) => matcher(item, lowercaseQuery)).toList();
  }
} 