import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_rating_rule.dart';
import 'base_provider.dart';

final materialRatingRuleBoxProvider = Provider<Box<MaterialRatingRule>>((ref) {
  throw UnimplementedError();
});

final materialRatingRuleProvider =
    StateNotifierProvider<MaterialRatingRuleNotifier, List<MaterialRatingRule>>(
  (ref) => MaterialRatingRuleNotifier(ref.read(materialRatingRuleBoxProvider)),
);

class MaterialRatingRuleNotifier extends BaseProvider<MaterialRatingRule> {
  MaterialRatingRuleNotifier(Box<MaterialRatingRule> box)
      : super(box, 'materialRatingRules');

  @override
  Map<String, dynamic> modelToMap(MaterialRatingRule model) {
    return {
      'materialCode': model.materialCode,
      'lotAcceptedRating': model.lotAcceptedRating,
      'lotRejectedRating': model.lotRejectedRating,
      'partialAcceptanceSlabs': model.partialAcceptanceSlabs
          .map((e) => {
                'minPercent': e.minPercent,
                'maxPercent': e.maxPercent,
                'rating': e.rating,
              })
          .toList(),
      'recheck100Slabs': model.recheck100Slabs
          .map((e) => {
                'minPercent': e.minPercent,
                'maxPercent': e.maxPercent,
                'rating': e.rating,
              })
          .toList(),
    };
  }

  @override
  MaterialRatingRule mapToModel(Map<String, dynamic> map) {
    List<dynamic> partial = map['partialAcceptanceSlabs'] ?? [];
    List<dynamic> recheck = map['recheck100Slabs'] ?? [];
    return MaterialRatingRule(
      materialCode: map['materialCode'] ?? '',
      lotAcceptedRating: (map['lotAcceptedRating'] ?? 5).toDouble(),
      lotRejectedRating: (map['lotRejectedRating'] ?? 0).toDouble(),
      partialAcceptanceSlabs: partial
          .map((e) => RatingRange(
                minPercent: (e['minPercent'] as num).toDouble(),
                maxPercent: (e['maxPercent'] as num).toDouble(),
                rating: (e['rating'] as num).toDouble(),
              ))
          .toList(),
      recheck100Slabs: recheck
          .map((e) => RatingRange(
                minPercent: (e['minPercent'] as num).toDouble(),
                maxPercent: (e['maxPercent'] as num).toDouble(),
                rating: (e['rating'] as num).toDouble(),
              ))
          .toList(),
    );
  }

  @override
  String getModelId(MaterialRatingRule model) => model.materialCode;

  // Convenience methods
  MaterialRatingRule? getByMaterialCode(String code) {
    try {
      return state.firstWhere((m) => m.materialCode == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertRule(MaterialRatingRule rule) async {
    final existing = getByMaterialCode(rule.materialCode);
    if (existing == null) {
      await add(rule);
    } else {
      await update(rule);
    }
  }
}
