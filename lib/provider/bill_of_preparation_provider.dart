import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bill_of_preparation.dart';
import 'base_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final billOfPreparationBoxProvider = Provider<Box<BillOfPreparation>>((ref) {
  throw UnimplementedError();
});

final billOfPreparationProvider =
    StateNotifierProvider<BillOfPreparationNotifier, List<BillOfPreparation>>(
  (ref) => BillOfPreparationNotifier(ref.watch(billOfPreparationBoxProvider)),
);

class BillOfPreparationNotifier extends BaseProvider<BillOfPreparation> {
  BillOfPreparationNotifier(Box<BillOfPreparation> box) : super(box, 'billOfPreparations');
  
  @override
  String getModelId(BillOfPreparation bop) {
    return '${bop.jobNo}_${bop.createdDate}'; // Unique identifier
  }

  @override
  Map<String, dynamic> modelToMap(BillOfPreparation bop) {
    return {
      'jobNo': bop.jobNo,
      'createdDate': bop.createdDate,
      'cktTypes': bop.cktTypes.map((ckt) => {
        'name': ckt.name,
        'quantity': ckt.quantity,
      }).toList(),
      'materials': bop.materials.map((mat) => {
        'materialCode': mat.materialCode,
        'materialDescription': mat.materialDescription,
        'materialSource': mat.materialSource,
        'cktTypes': mat.cktTypes.map((ckt) => {
          'cktTypeName': ckt.cktTypeName,
          'cktTypeQuantity': ckt.cktTypeQuantity,
          'materialQuantity': ckt.materialQuantity,
        }).toList(),
      }).toList(),
      'finalValue': bop.finalValue,
    };
  }

  @override
  BillOfPreparation mapToModel(Map<String, dynamic> map) {
    final cktTypesList = (map['cktTypes'] as List<dynamic>?)
        ?.map((ckt) => CktType(
              name: ckt['name'] ?? '',
              quantity: (ckt['quantity'] ?? 0).toDouble(),
            ))
        .toList() ?? <CktType>[];
        
    final materialsList = (map['materials'] as List<dynamic>?)
        ?.map((mat) {
          final cktTypesList = (mat['cktTypes'] as List<dynamic>?)
              ?.map((ckt) => MaterialCktType(
                    cktTypeName: ckt['cktTypeName'] ?? '',
                    cktTypeQuantity: (ckt['cktTypeQuantity'] ?? 0).toDouble(),
                    materialQuantity: (ckt['materialQuantity'] ?? 0).toDouble(),
                  ))
              .toList() ?? <MaterialCktType>[];
          
          return BopMaterial(
            materialCode: mat['materialCode'] ?? '',
            materialDescription: mat['materialDescription'] ?? '',
            materialSource: mat['materialSource'] ?? 'material_master',
            cktTypes: cktTypesList,
          );
        })
        .toList() ?? <BopMaterial>[];

    return BillOfPreparation(
      jobNo: map['jobNo'] ?? '',
      createdDate: map['createdDate'] ?? '',
      cktTypes: cktTypesList,
      materials: materialsList,
      finalValue: (map['finalValue'] ?? 0).toDouble(),
    );
  }

  Future<void> addBillOfPreparation(BillOfPreparation bop, WidgetRef ref) async {
    await add(bop);
  }

  Future<void> updateBillOfPreparation(int index, BillOfPreparation bop, WidgetRef ref) async {
    await update(bop);
  }

  Future<void> deleteBillOfPreparation(BillOfPreparation bop, WidgetRef ref) async {
    await delete(bop);
  }
}
