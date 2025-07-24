import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/quality.dart';
import 'base_provider.dart';

final qualityBoxProvider = Provider<Box<Quality>>((ref) {
  throw UnimplementedError();
});

final qualityListProvider =
    StateNotifierProvider<QualityNotifier, List<Quality>>(
  (ref) => QualityNotifier(ref.read(qualityBoxProvider)),
);

class QualityNotifier extends BaseProvider<Quality> {
  QualityNotifier(Box<Quality> box) : super(box, 'qualities');

  @override
  Map<String, dynamic> modelToMap(Quality quality) {
    return {
      'name': quality.name,
    };
  }

  @override
  Quality mapToModel(Map<String, dynamic> map) {
    return Quality(
      name: map['name'] ?? '',
    );
  }

  @override
  String getModelId(Quality quality) => quality.name;

  // Get quality by name
  Quality? getQualityByName(String name) {
    return state.firstWhere(
      (quality) => quality.name == name,
      orElse: () => null as Quality,
    );
  }

  // Search qualities
  List<Quality> searchQualities(String query) {
    return search(query, (quality, query) {
      return quality.name.toLowerCase().contains(query);
    });
  }
}
