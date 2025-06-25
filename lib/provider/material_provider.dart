import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_item.dart';
import '../services/sync_service.dart';
import 'supplier_provider.dart';  // Import for syncServiceProvider

final materialBoxProvider = Provider<Box<MaterialItem>>((ref) {
  throw UnimplementedError(); // Overridden in main
});

final materialListProvider =
    StateNotifierProvider<MaterialNotifier, List<MaterialItem>>(
  (ref) => MaterialNotifier(
    ref.read(materialBoxProvider),
    ref.read(syncServiceProvider),
  ),
);

class MaterialNotifier extends StateNotifier<List<MaterialItem>> {
  final Box<MaterialItem> box;
  final SyncService _syncService;

  MaterialNotifier(this.box, this._syncService) : super(box.values.toList());

  Future<void> addMaterial(MaterialItem item) async {
    try {
      await box.add(item);
      if (mounted) {
        state = box.values.toList();
        await _syncToFirebase();
      }
    } catch (e) {
      // Re-throw the error to be handled by the UI
      rethrow;
    }
  }

  Future<void> updateMaterial(int index, MaterialItem updatedItem) async {
    try {
      if (index >= 0 && index < box.length) {
        await box.putAt(index, updatedItem);
        if (mounted) {
          state = box.values.toList();
          await _syncToFirebase();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMaterial(MaterialItem material) async {
    try {
      final index =
          box.values.toList().indexWhere((m) => m.slNo == material.slNo);
      if (index != -1) {
        await box.deleteAt(index);
        if (mounted) {
          state = box.values.toList();
          await _syncToFirebase();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await _syncFromFirebase();
      if (mounted) {
        state = box.values.toList();
      }
    } catch (e) {
      print('Error refreshing materials: $e');
      rethrow;
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('materials', box);
    } catch (e) {
      print('Error syncing materials to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'materials',
        box,
        _syncService.materialFromMap,
      );
    } catch (e) {
      print('Error syncing materials from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
