import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quality.dart';

final qualityListProvider =
    StateNotifierProvider<QualityListNotifier, List<Quality>>((ref) {
  return QualityListNotifier();
});

class QualityListNotifier extends StateNotifier<List<Quality>> {
  QualityListNotifier() : super([]) {
    _loadQualities();
  }

  Future<void> _loadQualities() async {
    final box = await Hive.openBox<Quality>('qualities');
    state = box.values.toList();
  }

  Future<void> addQuality(String name) async {
    final box = await Hive.openBox<Quality>('qualities');
    final quality = Quality(name: name);
    await box.add(quality);
    state = [...state, quality];
  }

  Future<void> deleteQuality(Quality quality) async {
    final box = await Hive.openBox<Quality>('qualities');
    await quality.delete();
    state = state.where((q) => q != quality).toList();
  }
} 