// ignore_for_file: avoid_print

import 'package:hive/hive.dart';

part 'po_item.g.dart';

@HiveType(typeId: 5)
class POItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  String quantity;

  @HiveField(4)
  String costPerUnit;

  @HiveField(5)
  String totalCost;

  @HiveField(6)
  String saleRate;

  @HiveField(7)
  String marginPerUnit;

  @HiveField(8)
  String totalMargin;

  @HiveField(9)
  Map<String, ItemPRDetails> prDetails = {}; // PR No -> PR Details

  @HiveField(10)
  Map<String, Map<String, double>> receivedQuantities =
      {}; // GRN_PR -> received quantity

  // Factory constructor to handle migration from old format
  factory POItem.fromFields(Map<int, dynamic> fields) {
    // Handle old format where quantities were stored as doubles
    final oldReceivedQty = fields[10];
    Map<String, Map<String, double>>? receivedQuantities;

    if (oldReceivedQty is double) {
      // Convert old format to new format
      receivedQuantities = {};
    } else if (oldReceivedQty is Map) {
      // New format, cast appropriately
      receivedQuantities = (oldReceivedQty).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, double>()));
    }

    return POItem(
      materialCode: fields[0] as String,
      materialDescription: fields[1] as String,
      unit: fields[2] as String,
      quantity: fields[3] as String,
      costPerUnit: fields[4] as String,
      totalCost: fields[5] as String,
      saleRate: fields[6] as String,
      marginPerUnit: fields[7] as String,
      totalMargin: fields[8] as String,
      prDetails: (fields[9] as Map?)?.cast<String, ItemPRDetails>(),
      receivedQuantities: receivedQuantities,
    );
  }

  // Get total received quantity
  double get totalReceivedQuantity {
    double total = 0.0;
    for (var grnQtys in receivedQuantities.values) {
      total += grnQtys.values.fold(0.0, (sum, qty) => sum + qty);
    }
    return total;
  }

  // Get total received quantity for a specific PR
  double getReceivedQuantityForPR(String prNo) {
    double total = 0.0;
    for (var grnQtys in receivedQuantities.values) {
      total += grnQtys[prNo] ?? 0.0;
    }
    return total;
  }

  // Check if this item is fully received
  bool get isFullyReceived {
    // Check if each PR has received its full quantity
    for (var prDetail in prDetails.entries) {
      final prNo = prDetail.key;
      final prQty = prDetail.value.quantity;
      final receivedQty = getReceivedQuantityForPR(prNo);

      if (receivedQty < prQty) {
        return false;
      }
    }

    return true;
  }

  // Get all unique job numbers for this item
  Set<String> get jobNumbers {
    final jobs = <String>{};
    for (var detail in prDetails.values) {
      if (detail.jobNo != 'General') {
        jobs.add(detail.jobNo);
      }
    }
    return jobs;
  }

  // Check if this item is for general stock
  bool get isGeneralStock {
    return prDetails.values.any((detail) => detail.jobNo == 'General');
  }

  // Get a formatted string for job numbers display
  String get formattedJobNumbers {
    final jobs = jobNumbers;
    if (jobs.isEmpty && isGeneralStock) {
      return 'General Stock';
    } else if (jobs.isNotEmpty) {
      return jobs.join(', ');
    } else {
      return 'General Stock';
    }
  }

  // Helper method to add received quantity
  void addReceivedQuantity(String grnPrKey, double quantity) {
    final parts = grnPrKey.split('_');
    if (parts.length != 2) return;

    final grnNo = parts[0];
    final prNo = parts[1];

    // Remove any existing quantity for this GRN and PR
    receivedQuantities.remove(grnNo);

    // Add the new quantity
    receivedQuantities.putIfAbsent(grnNo, () => {});
    receivedQuantities[grnNo]![prNo] = quantity;
  }

  // Get pending quantity for a specific PR
  double getPendingQuantityForPR(String prNo) {
    final prDetail = prDetails[prNo];
    if (prDetail == null) return 0.0;

    final orderedQty = prDetail.quantity;
    final receivedQty = getReceivedQuantityForPR(prNo);

    return orderedQty - receivedQty;
  }

  POItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
    required this.saleRate,
    required this.marginPerUnit,
    required this.totalMargin,
    Map<String, ItemPRDetails>? prDetails,
    Map<String, Map<String, double>>? receivedQuantities,
  }) {
    this.prDetails = prDetails ?? {};
    this.receivedQuantities = receivedQuantities ?? {};
  }

  void updateQuantity(String newQuantity) {
    quantity = newQuantity;
    final qty = double.parse(newQuantity);
    final cost = double.parse(costPerUnit);
    final margin = double.parse(marginPerUnit);
    totalCost = (qty * cost).toString();
    totalMargin = (qty * margin).toString();
  }

  void updateCostPerUnit(String newCostPerUnit) {
    costPerUnit = newCostPerUnit;
    final cost = double.parse(newCostPerUnit);
    final sale = double.parse(saleRate);
    final qty = double.parse(quantity);

    totalCost = (qty * cost).toString();
    marginPerUnit = (sale - cost).toString();
    totalMargin = (qty * (sale - cost)).toString();
  }

  // Calculate total rate difference as a number
  double get totalRateDifferenceValue {
    final qty = double.parse(quantity);
    final cost = double.parse(costPerUnit);
    final sale = double.parse(saleRate);
    return (sale - cost) * qty;
  }

  // Return total rate difference as a formatted string
  String get totalRateDifference {
    return totalRateDifferenceValue.toString();
  }

  POItem copyWith({
    String? materialCode,
    String? materialDescription,
    String? unit,
    String? quantity,
    String? costPerUnit,
    String? totalCost,
    String? saleRate,
    String? marginPerUnit,
    String? totalMargin,
    Map<String, ItemPRDetails>? prDetails,
    Map<String, Map<String, double>>? receivedQuantities,
  }) {
    return POItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      totalCost: totalCost ?? this.totalCost,
      saleRate: saleRate ?? this.saleRate,
      marginPerUnit: marginPerUnit ?? this.marginPerUnit,
      totalMargin: totalMargin ?? this.totalMargin,
      prDetails: prDetails ?? Map<String, ItemPRDetails>.from(this.prDetails),
      receivedQuantities: receivedQuantities ??
          Map<String, Map<String, double>>.from(this.receivedQuantities),
    );
  }

  // Helper method to safely cast map values
  static Map<String, Map<String, double>> castReceivedQuantities(dynamic value) {
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
            (val).map((k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0)),
          );
        }
        return MapEntry(key.toString(), <String, double>{});
      });
    } catch (e) {
      print('Error casting received quantities: $e');
      return {};
    }
  }

  // Helper method to safely cast PR details
  static Map<String, ItemPRDetails> castPRDetails(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, ItemPRDetails>) return value;
    
    try {
      if (value is double || value is String) {
        // Handle legacy double or string values
        return {};
      }
      
      return (value as Map).map((key, val) {
        if (val is ItemPRDetails) {
          return MapEntry(key.toString(), val);
        }
        if (val is Map) {
          return MapEntry(
            key.toString(),
            ItemPRDetails(
              prNo: val['prNo']?.toString() ?? '',
              jobNo: val['jobNo']?.toString() ?? 'General',
              quantity: (val['quantity'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
        return MapEntry(
          key.toString(),
          ItemPRDetails(
            prNo: '',
            jobNo: 'General',
            quantity: 0.0,
          ),
        );
      });
    } catch (e) {
      print('Error casting PR details: $e');
      return {};
    }
  }
}

@HiveType(typeId: 24)
class ItemPRDetails {
  @HiveField(0)
  String prNo;

  @HiveField(1)
  String jobNo;

  @HiveField(2)
  double quantity;

  ItemPRDetails({
    required this.prNo,
    required this.jobNo,
    required this.quantity,
  });

  ItemPRDetails copyWith({
    String? prNo,
    String? jobNo,
    double? quantity,
  }) {
    return ItemPRDetails(
      prNo: prNo ?? this.prNo,
      jobNo: jobNo ?? this.jobNo,
      quantity: quantity ?? this.quantity,
    );
  }
}
