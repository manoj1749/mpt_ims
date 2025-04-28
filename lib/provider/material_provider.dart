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

  void addMaterial(MaterialItem item) async {
    await box.add(item);
    state = box.values.toList();
  }

  void updateMaterial(int index, MaterialItem updatedItem) async {
    if (index >= 0 && index < box.length) {
      await box.putAt(index, updatedItem);
      state = box.values.toList();
    }
  }

  void deleteMaterial(MaterialItem material) async {
    final index =
        box.values.toList().indexWhere((m) => m.slNo == material.slNo);
    if (index != -1) {
      await box.deleteAt(index);
      state = box.values.toList();
    }
  }
}
