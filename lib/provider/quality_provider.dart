import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/quality.dart';

final qualityBoxProvider =
    Provider<Box<Quality>>((ref) => throw UnimplementedError());

final qualityListProvider =
    StateNotifierProvider<QualityListNotifier, List<Quality>>((ref) {
  final box = ref.watch(qualityBoxProvider);
  return QualityListNotifier(box);
});

class QualityListNotifier extends StateNotifier<List<Quality>> {
  final Box<Quality> box;

  QualityListNotifier(this.box) : super(box.values.toList());

  Future<void> addQuality(String name) async {
    final quality = Quality(name: name);
    await box.add(quality);
    state = box.values.toList();
  }

  Future<void> deleteQuality(Quality quality) async {
    await quality.delete();
    state = box.values.toList();
  }
}
