import 'package:hive/hive.dart';

part 'inventory_classification.g.dart';

@HiveType(typeId: 72)
class InventoryClassification extends HiveObject {
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

  InventoryClassification({
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

  InventoryClassification copyWith({
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
    return InventoryClassification(
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
