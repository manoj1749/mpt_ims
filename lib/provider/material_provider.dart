import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  MaterialNotifier(this.box) : super(box.values.toList());

  Future<void> addMaterial(MaterialItem item) async {
    try {
      await box.add(item);
      if (mounted) {
        state = box.values.toList();
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
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
