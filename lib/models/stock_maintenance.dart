import 'package:hive/hive.dart';

part 'stock_maintenance.g.dart';

@HiveType(typeId: 22)
class StockMaintenance extends HiveObject {
  @HiveField(0)
  String materialCode; // Material code/part number

  @HiveField(1)
  String materialDescription; // Material name/description

  @HiveField(2)
  String unit; // Unit of measurement

  @HiveField(3)
  String storageLocation; // Store location

  @HiveField(4)
  String rackNumber; // Rack information

  @HiveField(5)
  double currentStock; // Current available stock

  @HiveField(6)
  double stockUnderInspection; // Stock under quality inspection

  @HiveField(7)
  late Map<String, StockGRNDetails> grnDetails; // GRN-wise stock details

  @HiveField(8)
  late Map<String, StockPODetails> poDetails; // PO-wise stock details

  @HiveField(9)
  late Map<String, StockPRDetails> prDetails; // PR-wise stock details

  @HiveField(10)
  late Map<String, StockJobDetails> jobDetails; // Job-wise stock details

  @HiveField(11)
  late Map<String, StockVendorDetails>
      vendorDetails; // Vendor-wise stock details

  @HiveField(12)
  double totalStockValue; // Total value of current stock

  // New getters for accurate stock calculations
  double get calculatedCurrentStock {
    return grnDetails.values.fold(0.0, (sum, grn) => 
      sum + (grn.acceptedQuantity));
  }

  double get calculatedUnderInspection {
    return grnDetails.values.fold(0.0, (sum, grn) => 
      sum + (grn.receivedQuantity - (grn.acceptedQuantity + grn.rejectedQuantity)));
  }

  double get calculatedTotalStock => calculatedCurrentStock + calculatedUnderInspection;

  Map<String, double> get prWiseStock {
    final Map<String, double> summary = {};
    for (var po in poDetails.values) {
      for (var grnMap in po.receivedQuantities.values) {
        for (var entry in grnMap.entries) {
          summary[entry.key] = (summary[entry.key] ?? 0.0) + entry.value;
        }
      }
    }
    return summary;
  }

  StockMaintenance({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.storageLocation,
    required this.rackNumber,
    this.currentStock = 0.0,
    this.stockUnderInspection = 0.0,
    Map<String, StockGRNDetails>? grnDetails,
    Map<String, StockPODetails>? poDetails,
    Map<String, StockPRDetails>? prDetails,
    Map<String, StockJobDetails>? jobDetails,
    Map<String, StockVendorDetails>? vendorDetails,
    this.totalStockValue = 0.0,
  }) {
    this.grnDetails = grnDetails ?? {};
    this.poDetails = poDetails ?? {};
    this.prDetails = prDetails ?? {};
    this.jobDetails = jobDetails ?? {};
    this.vendorDetails = vendorDetails ?? {};
  }

  // Helper method to add GRN details
  void addGRNDetails(String grnNo, StockGRNDetails details) {
    grnDetails[grnNo] = details;
    _updateTotalStockValue();
    save();
  }

  // Helper method to add PO details
  void addPODetails(String poNo, StockPODetails details) {
    poDetails[poNo] = details;
    save();
  }

  // Helper method to add PR details
  void addPRDetails(String prNo, StockPRDetails details) {
    prDetails[prNo] = details;
    save();
  }

  // Helper method to add Job details
  void addJobDetails(String jobNo, StockJobDetails details) {
    jobDetails[jobNo] = details;
    save();
  }

  // Helper method to add Vendor details
  void addVendorDetails(String vendorId, StockVendorDetails details) {
    vendorDetails[vendorId] = details;
    _updateTotalStockValue();
    save();
  }

  // Helper method to update stock under inspection
  void updateStockUnderInspection(double quantity) {
    stockUnderInspection = quantity;
    save();
  }

  // Helper method to update current stock
  void updateCurrentStock(double quantity) {
    currentStock = quantity;
    _updateTotalStockValue();
    save();
  }

  // Helper method to move stock from inspection to current stock
  void moveStockFromInspectionToCurrent(double acceptedQuantity) {
    if (acceptedQuantity > 0 && stockUnderInspection >= acceptedQuantity) {
      stockUnderInspection -= acceptedQuantity;
      currentStock += acceptedQuantity;
      _updateTotalStockValue();
      save();
    }
  }

  // Private method to update total stock value
  void _updateTotalStockValue() {
    if (currentStock <= 0) {
      totalStockValue = 0.0;
      return;
    }

    // Calculate based on current stock and latest rates
    double total = 0.0;
    double remainingQty = currentStock;

    // Sort GRN details by date (newest first) to use latest rates
    final sortedGRNs = grnDetails.entries.toList()
      ..sort((a, b) => b.value.grnDate.compareTo(a.value.grnDate));

    for (var grn in sortedGRNs) {
      if (remainingQty <= 0) break;

      // Only consider accepted quantities for value calculation
      final qtyFromThisGRN = grn.value.acceptedQuantity.clamp(0, remainingQty);
      if (qtyFromThisGRN > 0) {
        total += qtyFromThisGRN * grn.value.rate;
        remainingQty -= qtyFromThisGRN;
      }
    }

    totalStockValue = total;
    
    // Update PR and PO quantities based on accepted stock
    for (var poDetail in poDetails.values) {
      double poAcceptedQty = 0.0;
      for (var grnQtys in poDetail.receivedQuantities.values) {
        for (var prQty in grnQtys.values) {
          poAcceptedQty += prQty;
        }
      }
      poDetail.receivedQuantity = poAcceptedQty;
    }
    
    // Update PR received quantities
    for (var prDetail in prDetails.values) {
      double prAcceptedQty = 0.0;
      for (var poDetail in poDetails.values) {
        for (var grnQtys in poDetail.receivedQuantities.values) {
          prAcceptedQty += grnQtys[prDetail.prNo] ?? 0.0;
        }
      }
      prDetail.receivedQuantity = prAcceptedQty;
    }
  }

  // Get average rate per unit
  double get averageRate {
    if (currentStock <= 0) return 0.0;
    return totalStockValue / currentStock;
  }

  // Get total stock (current + under inspection)
  double get totalStock => currentStock + stockUnderInspection;

  @override
  String toString() {
    return '\nStockMaintenance(materialCode: $materialCode, materialDescription: $materialDescription, unit: $unit, storageLocation: $storageLocation, rackNumber: $rackNumber, currentStock: $currentStock, stockUnderInspection: $stockUnderInspection, totalStockValue: $totalStockValue,\n  grnDetails: ${grnDetails.map((k, v) => MapEntry(k, v.toString()))},\n  poDetails: ${poDetails.map((k, v) => MapEntry(k, v.toString()))},\n  prDetails: ${prDetails.map((k, v) => MapEntry(k, v.toString()))},\n  jobDetails: ${jobDetails.map((k, v) => MapEntry(k, v.toString()))},\n  vendorDetails: ${vendorDetails.map((k, v) => MapEntry(k, v.toString()))}\n)';
  }
}

@HiveType(typeId: 25)
class StockGRNDetails {
  @HiveField(0)
  String grnNo;

  @HiveField(1)
  String grnDate;

  @HiveField(2)
  double receivedQuantity;

  @HiveField(3)
  double acceptedQuantity;

  @HiveField(4)
  double rejectedQuantity;

  @HiveField(5)
  String vendorId;

  @HiveField(6)
  double rate;

  StockGRNDetails({
    required this.grnNo,
    required this.grnDate,
    required this.receivedQuantity,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    required this.vendorId,
    required this.rate,
  });

  @override
  String toString() {
    return 'StockGRNDetails(grnNo: $grnNo, grnDate: $grnDate, receivedQuantity: $receivedQuantity, acceptedQuantity: $acceptedQuantity, rejectedQuantity: $rejectedQuantity, vendorId: $vendorId, rate: $rate)';
  }
}

@HiveType(typeId: 26)
class StockPODetails {
  @HiveField(0)
  String poNo;

  @HiveField(1)
  String poDate;

  @HiveField(2)
  double orderedQuantity;

  @HiveField(3)
  double receivedQuantity;

  @HiveField(4)
  String vendorId;

  @HiveField(5)
  double rate;

  @HiveField(6)
  Map<String, Map<String, double>> receivedQuantities =
      {}; // GRN -> PR -> Quantity mapping

  StockPODetails({
    required this.poNo,
    required this.poDate,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.vendorId,
    required this.rate,
    Map<String, Map<String, double>>? receivedQuantities,
  }) {
    this.receivedQuantities =
        Map<String, Map<String, double>>.from(receivedQuantities ?? {});
  }

  // Helper method to safely add received quantities
  void addReceivedQuantity(String grnNo, String prNo, double quantity) {
    receivedQuantities.putIfAbsent(grnNo, () => <String, double>{});
    receivedQuantities[grnNo]![prNo] = quantity;
  }

  // Helper method to get total received quantity for a PR
  double getReceivedQuantityForPR(String prNo) {
    double total = 0.0;
    for (var grnQtys in receivedQuantities.values) {
      total += grnQtys[prNo] ?? 0.0;
    }
    return total;
  }

  @override
  String toString() {
    return 'StockPODetails(poNo: $poNo, poDate: $poDate, orderedQuantity: $orderedQuantity, receivedQuantity: $receivedQuantity, vendorId: $vendorId, rate: $rate, receivedQuantities: $receivedQuantities)';
  }
}

@HiveType(typeId: 27)
class StockPRDetails {
  @HiveField(0)
  String prNo;

  @HiveField(1)
  String prDate;

  @HiveField(2)
  double requestedQuantity;

  @HiveField(3)
  double orderedQuantity;

  @HiveField(4)
  double receivedQuantity;

  StockPRDetails({
    required this.prNo,
    required this.prDate,
    required this.requestedQuantity,
    required this.orderedQuantity,
    required this.receivedQuantity,
  });

  @override
  String toString() {
    return 'StockPRDetails(prNo: $prNo, prDate: $prDate, requestedQuantity: $requestedQuantity, orderedQuantity: $orderedQuantity, receivedQuantity: $receivedQuantity)';
  }
}

@HiveType(typeId: 28)
class StockJobDetails {
  @HiveField(0)
  String jobNo;

  @HiveField(1)
  double allocatedQuantity;

  @HiveField(2)
  double consumedQuantity;

  @HiveField(3)
  String prNo;

  StockJobDetails({
    required this.jobNo,
    required this.allocatedQuantity,
    required this.consumedQuantity,
    required this.prNo,
  });

  @override
  String toString() {
    return 'StockJobDetails(jobNo: $jobNo, allocatedQuantity: $allocatedQuantity, consumedQuantity: $consumedQuantity, prNo: $prNo)';
  }
}

@HiveType(typeId: 29)
class StockVendorDetails {
  @HiveField(0)
  String vendorId;

  @HiveField(1)
  String vendorName;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double rate;

  @HiveField(4)
  String lastPurchaseDate;

  StockVendorDetails({
    required this.vendorId,
    required this.vendorName,
    required this.quantity,
    required this.rate,
    required this.lastPurchaseDate,
  });

  double get totalValue => quantity * rate;

  @override
  String toString() {
    return 'StockVendorDetails(vendorId: $vendorId, vendorName: $vendorName, quantity: $quantity, rate: $rate, lastPurchaseDate: $lastPurchaseDate)';
  }
}
