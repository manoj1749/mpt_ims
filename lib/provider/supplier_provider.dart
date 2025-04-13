import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/supplier.dart';

final supplierBoxProvider =
    Provider<Box<Supplier>>((ref) => throw UnimplementedError());

final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, List<Supplier>>((ref) {
  final box = ref.watch(supplierBoxProvider);
  return SupplierListNotifier(box);
});

class SupplierListNotifier extends StateNotifier<List<Supplier>> {
  final Box<Supplier> box;

  SupplierListNotifier(this.box) : super(box.values.toList());

  void addSupplier(Supplier supplier) async {
    await box.add(supplier);
    state = box.values.toList();
  }

  void updateSupplier(int key, Supplier updated) async {
    await box.put(key, updated); // ✅ not putAt
    state = box.values.toList();
  }

  void deleteSupplier(Supplier supplier) {
    supplier.delete(); // Hive object method
    state = state.where((s) => s.key != supplier.key).toList();
  }

  void refresh() {
    state = box.values.toList();
  }
}
