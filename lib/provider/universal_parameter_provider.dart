import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  UniversalParameterNotifier(this._box, this._syncService) : super([]) {
    _loadParameters();
  }

  void _loadParameters() {
    state = _box.values.toList();
  }

  Future<void> addParameter(String name) async {
    final parameter = UniversalParameter(name: name);
    await _box.add(parameter);
    _loadParameters();
    await _syncToFirebase();
  }

  Future<void> removeParameter(UniversalParameter parameter) async {
    await parameter.delete();
    _loadParameters();
    await _syncToFirebase();
  }

  Future<void> refresh() async {
    await _syncFromFirebase();
    _loadParameters();
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('universalParameters', _box);
    } catch (e) {
      print('Error syncing universal parameters to Firebase: $e');
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'universalParameters',
        _box,
        _syncService.universalParameterFromMap,
      );
    } catch (e) {
      print('Error syncing universal parameters from Firebase: $e');
    }
  }
}

final universalParameterProvider =
    StateNotifierProvider<UniversalParameterNotifier, List<UniversalParameter>>(
        (ref) {
  final box = ref.watch(universalParameterBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return UniversalParameterNotifier(box, syncService);
});
