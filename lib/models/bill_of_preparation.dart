import 'package:hive/hive.dart';

part 'bill_of_preparation.g.dart';

@HiveType(typeId: 80)
class BillOfPreparation extends HiveObject {
  @HiveField(0)
  String jobNo;
  
  @HiveField(1)
  String createdDate;
  
  @HiveField(2)
  List<CktType> cktTypes;
  
  @HiveField(3)
  List<BopMaterial> materials;
  
  @HiveField(4)
  double finalValue;
  
  BillOfPreparation({
    required this.jobNo,
    required this.createdDate,
    required this.cktTypes,
    required this.materials,
    required this.finalValue,
  });
  
  BillOfPreparation copyWith({
    String? jobNo,
    String? createdDate,
    List<CktType>? cktTypes,
    List<BopMaterial>? materials,
    double? finalValue,
  }) {
    return BillOfPreparation(
      jobNo: jobNo ?? this.jobNo,
      createdDate: createdDate ?? this.createdDate,
      cktTypes: cktTypes ?? List.from(this.cktTypes),
      materials: materials ?? List.from(this.materials),
      finalValue: finalValue ?? this.finalValue,
    );
  }
}

@HiveType(typeId: 81)
class CktType extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  double quantity;
  
  CktType({
    required this.name,
    required this.quantity,
  });
  
  CktType copyWith({
    String? name,
    double? quantity,
  }) {
    return CktType(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}

@HiveType(typeId: 83)
class MaterialCktType extends HiveObject {
  @HiveField(0)
  String cktTypeName;
  
  @HiveField(1)
  double cktTypeQuantity;
  
  @HiveField(2)
  double materialQuantity;
  
  MaterialCktType({
    required this.cktTypeName,
    required this.cktTypeQuantity,
    required this.materialQuantity,
  });
  
  MaterialCktType copyWith({
    String? cktTypeName,
    double? cktTypeQuantity,
    double? materialQuantity,
  }) {
    return MaterialCktType(
      cktTypeName: cktTypeName ?? this.cktTypeName,
      cktTypeQuantity: cktTypeQuantity ?? this.cktTypeQuantity,
      materialQuantity: materialQuantity ?? this.materialQuantity,
    );
  }
}

@HiveType(typeId: 82)
class BopMaterial extends HiveObject {
  @HiveField(0)
  String materialCode;
  
  @HiveField(1)
  String materialDescription;
  
  @HiveField(2)
  List<MaterialCktType> cktTypes;

  @HiveField(3, defaultValue: 'material_master')
  String materialSource;
  
  BopMaterial({
    required this.materialCode,
    required this.materialDescription,
    required this.cktTypes,
    this.materialSource = 'material_master',
  });
  
  BopMaterial copyWith({
    String? materialCode,
    String? materialDescription,
    List<MaterialCktType>? cktTypes,
    String? materialSource,
  }) {
    return BopMaterial(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      cktTypes: cktTypes ?? List.from(this.cktTypes),
      materialSource: materialSource ?? this.materialSource,
    );
  }
}
