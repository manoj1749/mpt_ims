import 'package:hive/hive.dart';

@HiveType(typeId: 60)
class RatingRange extends HiveObject {
  @HiveField(0)
  double minPercent; // inclusive, 0-100

  @HiveField(1)
  double maxPercent; // inclusive, 0-100

  @HiveField(2)
  double rating; // 0-5

  RatingRange({
    required this.minPercent,
    required this.maxPercent,
    required this.rating,
  });
}

class RatingRangeAdapter extends TypeAdapter<RatingRange> {
  @override
  final int typeId = 60;

  @override
  RatingRange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return RatingRange(
      minPercent: (fields[0] as num).toDouble(),
      maxPercent: (fields[1] as num).toDouble(),
      rating: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, RatingRange obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.minPercent)
      ..writeByte(1)
      ..write(obj.maxPercent)
      ..writeByte(2)
      ..write(obj.rating);
  }
}

@HiveType(typeId: 61)
class MaterialRatingRule extends HiveObject {
  @HiveField(0)
  String materialCode; // Can be material code or supplier code

  @HiveField(1)
  double lotAcceptedRating; // default 5

  @HiveField(2)
  double lotRejectedRating; // default 0

  @HiveField(3)
  List<RatingRange> partialAcceptanceSlabs;

  @HiveField(4)
  List<RatingRange> recheck100Slabs;

  MaterialRatingRule({
    required this.materialCode,
    this.lotAcceptedRating = 5.0,
    this.lotRejectedRating = 0.0,
    List<RatingRange>? partialAcceptanceSlabs,
    List<RatingRange>? recheck100Slabs,
  })  : partialAcceptanceSlabs = partialAcceptanceSlabs ?? [
          RatingRange(minPercent: 0, maxPercent: 5, rating: 4.5),
          RatingRange(minPercent: 5.01, maxPercent: 10, rating: 4.0),
          RatingRange(minPercent: 10.01, maxPercent: 20, rating: 3.0),
          RatingRange(minPercent: 20.01, maxPercent: 30, rating: 2.0),
          RatingRange(minPercent: 30.01, maxPercent: 100, rating: 1.0),
        ],
        recheck100Slabs = recheck100Slabs ?? [
          RatingRange(minPercent: 0, maxPercent: 5, rating: 3.0),
          RatingRange(minPercent: 5.01, maxPercent: 10, rating: 2.5),
          RatingRange(minPercent: 10.01, maxPercent: 20, rating: 2.0),
          RatingRange(minPercent: 20.01, maxPercent: 100, rating: 1.5),
        ];
  
  // Calculate rating based on inspection result
  double calculateRating(String usageDecision, double rejectionPercent) {
    if (usageDecision == 'Lot Accepted') {
      return lotAcceptedRating;
    } else if (usageDecision == 'Lot Rejected') {
      return lotRejectedRating;
    } else if (usageDecision == 'Conditionally Accepted' || usageDecision.contains('Partial')) {
      // Find rating from partial acceptance slabs
      for (var slab in partialAcceptanceSlabs) {
        if (rejectionPercent >= slab.minPercent && rejectionPercent <= slab.maxPercent) {
          return slab.rating;
        }
      }
      return 2.0; // Default if no slab matches
    } else if (usageDecision == '100% Recheck') {
      // Find rating from recheck slabs
      for (var slab in recheck100Slabs) {
        if (rejectionPercent >= slab.minPercent && rejectionPercent <= slab.maxPercent) {
          return slab.rating;
        }
      }
      return 1.5; // Default if no slab matches
    }
    return 0.0; // Unknown decision
  }
}

class MaterialRatingRuleAdapter extends TypeAdapter<MaterialRatingRule> {
  @override
  final int typeId = 61;

  @override
  MaterialRatingRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MaterialRatingRule(
      materialCode: fields[0] as String,
      lotAcceptedRating: (fields[1] as num).toDouble(),
      lotRejectedRating: (fields[2] as num).toDouble(),
      partialAcceptanceSlabs:
          (fields[3] as List).cast<RatingRange>(),
      recheck100Slabs:
          (fields[4] as List).cast<RatingRange>(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialRatingRule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.materialCode)
      ..writeByte(1)
      ..write(obj.lotAcceptedRating)
      ..writeByte(2)
      ..write(obj.lotRejectedRating)
      ..writeByte(3)
      ..write(obj.partialAcceptanceSlabs)
      ..writeByte(4)
      ..write(obj.recheck100Slabs);
  }
}
