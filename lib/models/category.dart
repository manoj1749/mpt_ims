import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 16)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool requiresQualityCheck;

  @HiveField(2)
  int? sampleSizeLessThan100;

  @HiveField(3)
  int? sampleSize100To500;

  @HiveField(4)
  int? sampleSizeGreaterThan500;

  @HiveField(5)
  bool? hasExpiryDate;

  @HiveField(6)
  bool? hasShelfLife;

  @HiveField(7)
  int? shelfLifeValue;

  @HiveField(8)
  String? shelfLifeUnit; // 'days', 'months', or 'years'

  Category({
    required this.name,
    this.requiresQualityCheck = true, // Default to true for existing data
    this.sampleSizeLessThan100,
    this.sampleSize100To500,
    this.sampleSizeGreaterThan500,
    bool? hasExpiryDate,
    bool? hasShelfLife,
    this.shelfLifeValue,
    this.shelfLifeUnit,
  })  : hasExpiryDate = hasExpiryDate ?? false,
        hasShelfLife = hasShelfLife ?? false;

  Category copyWith({
    String? name,
    bool? requiresQualityCheck,
    int? sampleSizeLessThan100,
    int? sampleSize100To500,
    int? sampleSizeGreaterThan500,
    bool? hasExpiryDate,
    bool? hasShelfLife,
    int? shelfLifeValue,
    String? shelfLifeUnit,
  }) {
    return Category(
      name: name ?? this.name,
      requiresQualityCheck: requiresQualityCheck ?? this.requiresQualityCheck,
      sampleSizeLessThan100:
          sampleSizeLessThan100 ?? this.sampleSizeLessThan100,
      sampleSize100To500: sampleSize100To500 ?? this.sampleSize100To500,
      sampleSizeGreaterThan500:
          sampleSizeGreaterThan500 ?? this.sampleSizeGreaterThan500,
      hasExpiryDate: hasExpiryDate ?? this.hasExpiryDate,
      hasShelfLife: hasShelfLife ?? this.hasShelfLife,
      shelfLifeValue: shelfLifeValue ?? this.shelfLifeValue,
      shelfLifeUnit: shelfLifeUnit ?? this.shelfLifeUnit,
    );
  }
}
