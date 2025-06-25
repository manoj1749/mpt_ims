import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/supplier.dart';
import '../services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

final supplierBoxProvider =
    Provider<Box<Supplier>>((ref) => throw UnimplementedError());

final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, List<Supplier>>((ref) {
  final box = ref.watch(supplierBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SupplierListNotifier(box, syncService);
});

class SupplierListNotifier extends StateNotifier<List<Supplier>> {
  final Box<Supplier> box;
  final SyncService _syncService;

  SupplierListNotifier(this.box, this._syncService) : super(box.values.toList());

  Future<void> addSupplier(Supplier supplier) async {
    await box.add(supplier);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> updateSupplier(int key, Supplier updated) async {
    await box.put(key, updated);
    state = box.values.toList();
    await _syncToFirebase();
  }

  Future<void> deleteSupplier(Supplier supplier) async {
    await supplier.delete();
    state = state.where((s) => s.key != supplier.key).toList();
    await _syncToFirebase();
  }

  Future<void> refresh() async {
    await _syncFromFirebase();
    state = box.values.toList();
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('suppliers', box);
    } catch (e) {
      print('Error syncing suppliers to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'suppliers',
        box,
        _syncService.supplierFromMap,
      );
    } catch (e) {
      print('Error syncing suppliers from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
