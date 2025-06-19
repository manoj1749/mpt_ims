import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/material_request.dart';

final materialRequestBoxProvider = Provider<Box<MaterialRequest>>((ref) {
  return Hive.box<MaterialRequest>('material_requests');
});

final materialRequestListProvider = Provider<List<MaterialRequest>>((ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return box.values.toList();
});

class MaterialRequestProvider extends StateNotifier<List<MaterialRequest>> {
  final Box<MaterialRequest> _box;

  MaterialRequestProvider(this._box) : super(_box.values.toList());

  List<MaterialRequest> get requests => state;

  Future<void> addMaterialRequest(MaterialRequest request) async {
    await _box.add(request);
    state = _box.values.toList();
  }

  Future<void> updateMaterialRequest(MaterialRequest request) async {
    final index = _box.values.toList().indexWhere((r) => r.issueNo == request.issueNo);
    if (index != -1) {
      await _box.putAt(index, request);
      state = _box.values.toList();
    }
  }

  Future<void> deleteMaterialRequest(String issueNo) async {
    final index = _box.values.toList().indexWhere((r) => r.issueNo == issueNo);
    if (index != -1) {
      await _box.deleteAt(index);
      state = _box.values.toList();
    }
  }

  MaterialRequest? getMaterialRequestByNo(String issueNo) {
    try {
      return _box.values.firstWhere((request) => request.issueNo == issueNo);
    } catch (e) {
      return null;
    }
  }
}

final materialRequestProvider =
    StateNotifierProvider<MaterialRequestProvider, List<MaterialRequest>>((ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return MaterialRequestProvider(box);
}); 