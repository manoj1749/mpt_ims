// ignore_for_file: avoid_print

import 'package:hive/hive.dart';
import '../models/material_item.dart';
import '../models/category.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';

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
  double invoiceAmount;

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

  @override
  String toString() {
    return '\nStoreInward(grnNo: $grnNo, grnDate: $grnDate, supplierName: $supplierName, poNo: $poNo, poDate: $poDate, invoiceNo: $invoiceNo, invoiceDate: $invoiceDate, invoiceAmount: $invoiceAmount, receivedBy: $receivedBy, checkedBy: $checkedBy, status: $status, items: [\n  ${items.map((e) => e.toString()).join(',\n  ')}\n])';
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
  Map<String, Map<String, double>> prQuantities =
      {}; // Store PR-wise quantities: PO No -> {PR No -> Quantity}

  @HiveField(9)
  Map<String, InspectionQuantityStatus> inspectionStatus =
      {}; // Map of inspection number to inspection status

  @HiveField(10)
  Map<String, Map<String, String>> prJobNumbers =
      {}; // Map of PO No -> {PR No -> Job No}

  // Helper property to get total inspected quantity
  double get inspectedQuantity => inspectionStatus.values
      .fold<double>(0.0, (sum, status) => sum + status.inspectedQty);

  // Helper property to get total accepted quantity
  double get totalAcceptedQty => inspectionStatus.values
      .fold<double>(0.0, (sum, status) => sum + status.acceptedQty);

  // Helper property to get total rejected quantity
  double get totalRejectedQty => inspectionStatus.values
      .fold<double>(0.0, (sum, status) => sum + status.rejectedQty);

  // Helper property to get quantity under inspection
  double get underInspectionQty =>
      receivedQty - (totalAcceptedQty + totalRejectedQty);

  bool get isFullyInspected =>
      inspectedQuantity >= receivedQty ||
      acceptedQty + rejectedQty >= receivedQty;

  // Helper method to update inspection status
  void updateInspectionStatus(
      String inspectionNo, InspectionQuantityStatus status) {
    inspectionStatus[inspectionNo] = status;
  }

  // Helper method to distribute PO quantity to PRs
  void distributePOQuantityToPRs(String poNo, double poQuantity) {
    print('\nDistributing PO quantity to PRs:');
    print('PO: $poNo, Quantity: $poQuantity');

    // Check if we already have PR quantities for this PO
    if (prQuantities.containsKey(poNo) && prQuantities[poNo]!.isNotEmpty) {
      print('PR quantities already exist for this PO, skipping distribution');
      return;
    }

    // Initialize maps if they don't exist
    if (!prQuantities.containsKey(poNo)) {
      prQuantities[poNo] = {};
    }
    if (!prJobNumbers.containsKey(poNo)) {
      prJobNumbers[poNo] = {};
    }

    // Get the PO from Hive to check PR details
    final poBox = Hive.box<PurchaseOrder>('purchase_orders');
    final po = poBox.values.firstWhere(
      (p) => p.poNo == poNo,
      orElse: () => PurchaseOrder(
        poNo: poNo,
        poDate: '',
        supplierName: '',
        transport: '',
        deliveryRequirements: '',
        items: [],
        total: 0.0,
        igst: 0.0,
        cgst: 0.0,
        sgst: 0.0,
        grandTotal: 0.0,
      ),
    );

    if (po.items.isNotEmpty) {
      // Find the corresponding PO item
      final poItem = po.items.firstWhere(
        (item) => item.materialCode == materialCode,
        orElse: () => POItem(
          materialCode: materialCode,
          materialDescription: materialDescription,
          unit: unit,
          quantity: '0',
          costPerUnit: '0',
          totalCost: '0',
          saleRate: '0',
          marginPerUnit: '0',
          totalMargin: '0',
        ),
      );

      if (poItem.prDetails.isNotEmpty) {
        print('Found PR details in PO:');
        // Distribute quantity according to PR details
        for (var prDetail in poItem.prDetails.entries) {
          final prNo = prDetail.key;
          final jobNo = prDetail.value.jobNo;
          final prQty = prDetail.value.quantity;
          
          print('PR: $prNo, Job: $jobNo, Qty: $prQty');
          prQuantities[poNo]![prNo] = prQty;
          prJobNumbers[poNo]![prNo] = jobNo;
        }
      } else {
        // If no PR details found, assign to General PR
        print('No PR details found in PO, assigning to General PR');
        prQuantities[poNo]!['General'] = poQuantity;
        prJobNumbers[poNo]!['General'] = 'General';
      }
    } else {
      // If PO not found, assign to General PR
      print('PO not found, assigning to General PR');
      prQuantities[poNo]!['General'] = poQuantity;
      prJobNumbers[poNo]!['General'] = 'General';
    }
    
    print('Final PR distribution:');
    prQuantities[poNo]?.forEach((pr, qty) => print('PR: $pr, Quantity: $qty'));
  }

  // Helper method to get job number for a PR
  String getJobNumberForPR(String poNo, String prNo) {
    return prJobNumbers[poNo]?[prNo] ?? 'General';
  }

  // Helper method to add PR quantity
  void addPRQuantity(String poNo, String prNo, double quantity) {
    print('\nAdding PR quantity:');
    print('PO: $poNo, PR: $prNo, Quantity: $quantity');
    
    if (!prQuantities.containsKey(poNo)) {
      prQuantities[poNo] = {};
    }
    prQuantities[poNo]![prNo] = quantity;
    
    print('Updated PR quantities for $poNo:');
    prQuantities[poNo]?.forEach((pr, qty) => print('PR: $pr, Quantity: $qty'));
  }

  // Helper method to add job number for PR
  void addJobNumberForPR(String poNo, String prNo, String jobNo) {
    print('\nAdding job number:');
    print('PO: $poNo, PR: $prNo, Job: $jobNo');
    
    if (!prJobNumbers.containsKey(poNo)) {
      prJobNumbers[poNo] = {};
    }
    prJobNumbers[poNo]![prNo] = jobNo;
    
    print('Updated job numbers for $poNo:');
    prJobNumbers[poNo]?.forEach((pr, job) => print('PR: $pr, Job: $job'));
  }

  // Helper method to get total quantity for a PO
  double getTotalQuantityForPO(String poNo) {
    if (!prQuantities.containsKey(poNo)) return 0.0;
    return prQuantities[poNo]!.values.fold(0.0, (sum, qty) => sum + qty);
  }

  // Get all job numbers associated with this item
  Set<String> getJobNumbers() {
    final jobs = <String>{};
    for (var poEntry in prJobNumbers.entries) {
      jobs.addAll(poEntry.value.values);
    }
    return jobs;
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
            (val).map((k, v) =>
                MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0)),
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
  static Map<String, InspectionQuantityStatus> castInspectionStatus(
      dynamic value) {
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
            (val).map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
        return MapEntry(key.toString(), <String, String>{});
      });
    } catch (e) {
      print('Error casting PR job numbers: $e');
      return {};
    }
  }

  @override
  String toString() {
    return 'InwardItem(materialCode: '
      '[33m$materialCode[0m, materialDescription: $materialDescription, unit: $unit, receivedQty: $receivedQty, acceptedQty: $acceptedQty, rejectedQty: $rejectedQty, prQuantities: $prQuantities, prJobNumbers: $prJobNumbers)';
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
