// ignore_for_file: avoid_print

import 'package:hive/hive.dart';
import '../models/material_item.dart';
import '../models/category.dart';

part 'store_inward.g.dart';

@HiveType(typeId: 6)
class StoreInward extends HiveObject {
  @HiveField(0)
  String grnNo;

  @HiveField(1)
  String grnDate;

  @HiveField(2)
  String supplierName;

  @HiveField(3)
  String poNo;

  @HiveField(4)
  String poDate;

  @HiveField(5)
  String invoiceNo;

  @HiveField(6)
  String invoiceDate;

  @HiveField(7)
  String invoiceAmount;

  @HiveField(8)
  String receivedBy;

  @HiveField(9)
  String checkedBy;

  @HiveField(10)
  List<InwardItem> items;

  @HiveField(11)
  String? _status;

  String get status => _status ?? 'Pending';

  set status(String value) {
    _status = value;
  }

  bool get isFullyInspected => items.every((item) => item.isFullyInspected);

  void updateStatus() {
    print('\n=== Debug: Updating GRN Status ===');
    print('GRN No: $grnNo');
    print('Current Status: $status');

    bool allItemsProcessed = true;
    bool hasProcessedItems = false;
    bool hasItemsNeedingInspection = false;

    for (var item in items) {
      print('\nChecking Item: ${item.materialCode}');
      print('Received Qty: ${item.receivedQty}');

      // Get the material's category from the provider
      final material = Hive.box<MaterialItem>('materials').values.firstWhere(
            (m) => m.partNo == item.materialCode || m.slNo == item.materialCode,
            orElse: () => MaterialItem(
              slNo: item.materialCode,
              description: item.materialDescription,
              partNo: item.materialCode,
              unit: item.unit,
              category: 'General',
              subCategory: '',
            ),
          );

      // Get the category settings
      final category = Hive.box<Category>('categories').values.firstWhere(
            (c) => c.name == material.category,
            orElse: () => Category(name: material.category),
          );

      // If quality check is not required, consider it as inspected
      if (!category.requiresQualityCheck) {
        hasProcessedItems = true;
        continue;
      }

      hasItemsNeedingInspection = true;
      double totalInspectedQty = 0;
      for (var qty in item.inspectedQuantities.values) {
        totalInspectedQty += qty;
      }
      print('Total Inspected Qty: $totalInspectedQty');

      if (totalInspectedQty > 0) {
        hasProcessedItems = true;
      }

      if (totalInspectedQty < item.receivedQty) {
        allItemsProcessed = false;
        print(
            'Item not fully inspected: $totalInspectedQty < ${item.receivedQty}');
      }
    }

    String newStatus;
    if (!hasItemsNeedingInspection) {
      newStatus =
          'Completed'; // All items are general stock or don't need inspection
    } else if (!hasProcessedItems) {
      newStatus = 'Under Inspection';
    } else if (allItemsProcessed) {
      newStatus = 'Inspected';
    } else {
      newStatus = 'Partially Inspected';
    }

    print('New Status: $newStatus');
    status = newStatus;
  }

  StoreInward({
    required this.grnNo,
    required this.grnDate,
    required this.supplierName,
    required this.poNo,
    required this.poDate,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.invoiceAmount,
    required this.receivedBy,
    required this.checkedBy,
    required this.items,
    String? status,
  }) {
    _status = status;
  }
}

@HiveType(typeId: 7)
class InwardItem {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double orderedQty;

  @HiveField(4)
  double receivedQty;

  @HiveField(5)
  double acceptedQty;

  @HiveField(6)
  double rejectedQty;

  @HiveField(7)
  String costPerUnit;

  @HiveField(8)
  Map<String, Map<String, double>> prQuantities = {}; // Store PR-wise quantities: PO No -> {PR No -> Quantity}

  @HiveField(9)
  Map<String, double> inspectedQuantities = {}; // Map of inspection number to inspected quantity

  @HiveField(10)
  Map<String, Map<String, String>> prJobNumbers = {}; // Map of PO No -> {PR No -> Job No}

  // Factory constructor to handle migration from old format
  factory InwardItem.fromFields(Map<int, dynamic> fields) {
    // Handle old format where quantities were stored as doubles
    final oldPoQuantity = fields[8];
    Map<String, Map<String, double>>? prQuantities;
    
    if (oldPoQuantity is double) {
      // Convert old format to new format
      prQuantities = {};
    } else if (oldPoQuantity is Map) {
      // New format, cast appropriately
      prQuantities = (oldPoQuantity).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, double>()));
    }

    return InwardItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      orderedQty: fields[3] as double,
      receivedQty: fields[4] as double,
      acceptedQty: fields[5] as double,
      rejectedQty: fields[6] as double,
      costPerUnit: fields[7] as String,
      prQuantities: prQuantities,
      inspectedQuantities: (fields[9] as Map?)?.cast<String, double>(),
      prJobNumbers: (fields[10] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, String>())),
    );
  }

  double get inspectedQuantity =>
      inspectedQuantities.values.fold<double>(0.0, (sum, qty) => sum + (qty));

  bool get isFullyInspected => inspectedQuantity >= receivedQty;

  void addInspectedQuantity(String inspectionNo, double quantity) {
    inspectedQuantities[inspectionNo] = quantity;
  }

  // Helper method to get job number for a specific PR
  String getJobNumberForPR(String poNo, String prNo) {
    return prJobNumbers[poNo]?[prNo] ?? '';
  }

  // Helper method to add PR quantity
  void addPRQuantity(String poNo, String prNo, double quantity) {
    prQuantities.putIfAbsent(poNo, () => {});
    prQuantities[poNo]![prNo] = quantity;
  }

  // Helper method to add job number for PR
  void addJobNumberForPR(String poNo, String prNo, String jobNo) {
    prJobNumbers.putIfAbsent(poNo, () => {});
    prJobNumbers[poNo]![prNo] = jobNo;
  }

  // Helper method to get total quantity for a PO
  double getTotalQuantityForPO(String poNo) {
    if (!prQuantities.containsKey(poNo)) return 0.0;
    return prQuantities[poNo]!.values.fold(0.0, (sum, qty) => sum + qty);
  }

  InwardItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.orderedQty,
    required this.receivedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.costPerUnit,
    Map<String, Map<String, double>>? prQuantities,
    Map<String, double>? inspectedQuantities,
    Map<String, Map<String, String>>? prJobNumbers,
  }) {
    this.prQuantities = prQuantities ?? {};
    this.inspectedQuantities = inspectedQuantities ?? {};
    this.prJobNumbers = prJobNumbers ?? {};
  }
}
