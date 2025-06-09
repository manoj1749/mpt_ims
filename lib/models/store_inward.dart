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

      // If quality check is not required, consider it as fully processed
      if (!category.requiresQualityCheck) {
        hasProcessedItems = true;
        item.acceptedQty = item.receivedQty; // Set full quantity as accepted
        item.rejectedQty = 0;
        continue;
      }

      hasItemsNeedingInspection = true;
      double totalInspectedQty = 0;
      double totalAcceptedQty = 0;
      double totalRejectedQty = 0;

      for (var status in item.inspectionStatus.values) {
        totalInspectedQty += status.inspectedQty;
        totalAcceptedQty += status.acceptedQty;
        totalRejectedQty += status.rejectedQty;
      }

      // Update item's accepted and rejected quantities
      item.acceptedQty = totalAcceptedQty;
      item.rejectedQty = totalRejectedQty;

      print('Total Inspected Qty: $totalInspectedQty');
      print('Total Accepted Qty: $totalAcceptedQty');
      print('Total Rejected Qty: $totalRejectedQty');

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
      newStatus = 'Completed'; // All items are general stock or don't need inspection
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
  Map<String, InspectionQuantityStatus> inspectionStatus = {}; // Map of inspection number to inspection status

  @HiveField(10)
  Map<String, Map<String, String>> prJobNumbers = {}; // Map of PO No -> {PR No -> Job No}

  // Helper property to get total inspected quantity
  double get inspectedQuantity =>
      inspectionStatus.values.fold<double>(0.0, (sum, status) => sum + status.inspectedQty);

  // Helper property to get total accepted quantity
  double get totalAcceptedQty =>
      inspectionStatus.values.fold<double>(0.0, (sum, status) => sum + status.acceptedQty);

  // Helper property to get total rejected quantity
  double get totalRejectedQty =>
      inspectionStatus.values.fold<double>(0.0, (sum, status) => sum + status.rejectedQty);

  // Helper property to get quantity under inspection
  double get underInspectionQty => receivedQty - (totalAcceptedQty + totalRejectedQty);

  bool get isFullyInspected => inspectedQuantity >= receivedQty;

  // Helper method to update inspection status
  void updateInspectionStatus(String inspectionNo, InspectionQuantityStatus status) {
    inspectionStatus[inspectionNo] = status;
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
    Map<String, InspectionQuantityStatus>? inspectionStatus,
    Map<String, Map<String, String>>? prJobNumbers,
  }) {
    this.prQuantities = prQuantities ?? {};
    this.inspectionStatus = inspectionStatus ?? {};
    this.prJobNumbers = prJobNumbers ?? {};
  }

  // Helper method to safely cast map values
  static Map<String, Map<String, double>> castPRQuantities(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, Map<String, double>>) return value;
    
    try {
      if (value is double || value is String) {
        // Handle legacy double or string values
        return {};
      }
      
      return (value as Map).map((key, val) {
        if (val is Map) {
          return MapEntry(
            key.toString(),
            (val as Map).map((k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0)),
          );
        }
        return MapEntry(key.toString(), <String, double>{});
      });
    } catch (e) {
      print('Error casting PR quantities: $e');
      return {};
    }
  }

  // Helper method to safely cast inspection status
  static Map<String, InspectionQuantityStatus> castInspectionStatus(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, InspectionQuantityStatus>) return value;
    
    try {
      if (value is double || value is String) {
        // Handle legacy double or string values
        return {};
      }
      
      return (value as Map).map((key, val) {
        if (val is InspectionQuantityStatus) {
          return MapEntry(key.toString(), val);
        }
        if (val is Map) {
          return MapEntry(
            key.toString(),
            InspectionQuantityStatus(
              inspectedQty: (val['inspectedQty'] as num?)?.toDouble() ?? 0.0,
              acceptedQty: (val['acceptedQty'] as num?)?.toDouble() ?? 0.0,
              rejectedQty: (val['rejectedQty'] as num?)?.toDouble() ?? 0.0,
              status: val['status']?.toString() ?? 'Pending',
            ),
          );
        }
        return MapEntry(
          key.toString(),
          InspectionQuantityStatus(
            inspectedQty: 0.0,
            acceptedQty: 0.0,
            rejectedQty: 0.0,
            status: 'Pending',
          ),
        );
      });
    } catch (e) {
      print('Error casting inspection status: $e');
      return {};
    }
  }

  // Helper method to safely cast PR job numbers
  static Map<String, Map<String, String>> castPRJobNumbers(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, Map<String, String>>) return value;
    
    try {
      if (value is double || value is String) {
        // Handle legacy double or string values
        return {};
      }
      
      return (value as Map).map((key, val) {
        if (val is Map) {
          return MapEntry(
            key.toString(),
            (val as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
        return MapEntry(key.toString(), <String, String>{});
      });
    } catch (e) {
      print('Error casting PR job numbers: $e');
      return {};
    }
  }
}

@HiveType(typeId: 23)
class InspectionQuantityStatus {
  @HiveField(0)
  double inspectedQty;

  @HiveField(1)
  double acceptedQty;

  @HiveField(2)
  double rejectedQty;

  @HiveField(3)
  String status; // 'Pending', 'Accepted', 'Rejected', 'Partially Accepted'

  InspectionQuantityStatus({
    required this.inspectedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.status,
  });
}
