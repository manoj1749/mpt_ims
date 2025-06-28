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
    return grnDetails.values
        .fold(0.0, (sum, grn) => sum + (grn.acceptedQuantity));
  }

  double get calculatedUnderInspection {
    return grnDetails.values.fold(
        0.0,
        (sum, grn) =>
            sum +
            (grn.receivedQuantity -
                (grn.acceptedQuantity + grn.rejectedQuantity)));
  }

  double get calculatedTotalStock =>
      calculatedCurrentStock + calculatedUnderInspection;

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

  // Update stock quantities based on GRN details
  void _updateStockQuantities() {
    double totalCurrentStock = 0.0;
    double totalUnderInspection = 0.0;

    // Calculate from GRN details
    for (var grnDetail in grnDetails.values) {
      totalCurrentStock += grnDetail.acceptedQuantity - grnDetail.issuedQuantity;
      totalUnderInspection += grnDetail.receivedQuantity - 
        (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
    }

    // Update the stock quantities
    currentStock = totalCurrentStock;
    stockUnderInspection = totalUnderInspection;

    // Update total stock value
    _updateTotalStockValue();
  }

  // Update total stock value based on GRN details
  void _updateTotalStockValue() {
    double total = 0.0;
    for (var grnDetail in grnDetails.values) {
      total += (grnDetail.acceptedQuantity - grnDetail.issuedQuantity) * grnDetail.rate;
    }
    totalStockValue = total;
  }

  // Update PR quantities based on PO details
  void _updatePRQuantities() {
    for (var prDetail in prDetails.values) {
      double prReceivedQty = 0.0;
      for (var poDetail in poDetails.values) {
        for (var grnQtys in poDetail.receivedQuantities.values) {
          prReceivedQty += grnQtys[prDetail.prNo] ?? 0.0;
        }
      }
      prDetail.receivedQuantity = prReceivedQty;
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

  // Find the oldest PR for a job that has available stock
  (String, double)? findAvailablePRForJob(
      String jobNo, double requiredQuantity) {
    // Get all PRs for this job
    final jobPRs = prDetails.entries
        .where(
            (pr) => pr.value.jobNo == jobNo && pr.value.availableQuantity > 0)
        .toList()
      ..sort((a, b) =>
          a.value.prDate.compareTo(b.value.prDate)); // Sort by date ascending

    for (var pr in jobPRs) {
      if (pr.value.availableQuantity >= requiredQuantity) {
        return (pr.key, requiredQuantity);
      }
    }

    // If no single PR has enough quantity, return the oldest PR with its available quantity
    if (jobPRs.isNotEmpty) {
      final oldestPR = jobPRs.first;
      return (oldestPR.key, oldestPR.value.availableQuantity);
    }

    return null;
  }

  // Find the oldest PO for a PR that has available stock
  (String, double)? findAvailablePOForPR(String prNo, double requiredQuantity) {
    // Get all POs that have received stock for this PR
    final prPOs = poDetails.entries
        .where((po) => po.value.getAvailableQuantityForPR(prNo) > 0)
        .toList()
      ..sort((a, b) =>
          a.value.poDate.compareTo(b.value.poDate)); // Sort by date ascending

    for (var po in prPOs) {
      final availableQty = po.value.getAvailableQuantityForPR(prNo);
      if (availableQty >= requiredQuantity) {
        return (po.key, requiredQuantity);
      }
    }

    // If no single PO has enough quantity, return the oldest PO with its available quantity
    if (prPOs.isNotEmpty) {
      final oldestPO = prPOs.first;
      return (oldestPO.key, oldestPO.value.getAvailableQuantityForPR(prNo));
    }

    return null;
  }

  // Find the oldest GRN for a PO that has available stock
  (String, double)? findAvailableGRNForPO(
      String poNo, String prNo, double requiredQuantity) {
    final po = poDetails[poNo];
    if (po == null) return null;

    // Get all GRNs that have received stock for this PO and PR
    final poGRNs = po.receivedQuantities.entries.where((grn) {
      final grnDetail = grnDetails[grn.key];
      return grnDetail != null &&
          grn.value[prNo] != null &&
          grnDetail.availableQuantity > 0;
    }).toList()
      ..sort((a, b) =>
          grnDetails[a.key]!.grnDate.compareTo(grnDetails[b.key]!.grnDate));

    for (var grn in poGRNs) {
      final grnDetail = grnDetails[grn.key]!;
      if (grnDetail.availableQuantity >= requiredQuantity) {
        return (grn.key, requiredQuantity);
      }
    }

    // If no single GRN has enough quantity, return the oldest GRN with its available quantity
    if (poGRNs.isNotEmpty) {
      final oldestGRN = poGRNs.first;
      return (oldestGRN.key, grnDetails[oldestGRN.key]!.availableQuantity);
    }

    return null;
  }

  // Issue stock from a specific job number
  void issueStockForJob(String jobNo, String materialIssueNo, double quantity) {
    // Find available PR
    final prInfo = findAvailablePRForJob(jobNo, quantity);
    if (prInfo == null) {
      throw Exception('No available PR found for job $jobNo');
    }

    var remainingQty = quantity;
    var currentPrNo = prInfo.$1;
    var currentPrQty = prInfo.$2;

    while (remainingQty > 0) {
      // Find available PO for current PR
      final poInfo = findAvailablePOForPR(currentPrNo, currentPrQty);
      if (poInfo == null) {
        throw Exception('No available PO found for PR $currentPrNo');
      }

      final currentPoNo = poInfo.$1;
      final currentPoQty = poInfo.$2;

      // Find available GRN for current PO
      final grnInfo =
          findAvailableGRNForPO(currentPoNo, currentPrNo, currentPoQty);
      if (grnInfo == null) {
        throw Exception('No available GRN found for PO $currentPoNo');
      }

      final currentGrnNo = grnInfo.$1;
      final currentGrnQty = grnInfo.$2;

      // Update quantities at all levels
      final issueQty = currentGrnQty.clamp(0.0, remainingQty).toDouble();

      // Update GRN
      final grnDetail = grnDetails[currentGrnNo]!;
      grnDetail.addIssuedQuantity(currentPrNo, issueQty);

      // Update PO
      final poDetail = poDetails[currentPoNo]!;
      poDetail.addIssuedQuantity(currentPrNo, issueQty);

      // Update PR
      final prDetail = prDetails[currentPrNo]!;
      prDetail.issuedQuantity += issueQty;

      // Update job details
      final jobDetail = jobDetails[jobNo]!;
      jobDetail.consumedQuantity += issueQty;

      remainingQty -= issueQty;

      // If we still need more quantity, find the next available PR
      if (remainingQty > 0) {
        final nextPrInfo = findAvailablePRForJob(jobNo, remainingQty);
        if (nextPrInfo == null) {
          throw Exception('Insufficient stock available for job $jobNo');
        }
        currentPrNo = nextPrInfo.$1;
        currentPrQty = nextPrInfo.$2;
      }
    }

    // Update current stock and total stock value
    _updateTotalStockValue();
    save();
  }

  // Get available quantity for a specific PR
  double getAvailableQuantityForPR(String prNo) {
    if (!prDetails.containsKey(prNo)) return 0.0;
    
    final prDetail = prDetails[prNo]!;
    return prDetail.receivedQuantity - prDetail.issuedQuantity;
  }

  // Get available quantity for a specific job
  double getAvailableQuantityForJob(String jobNo) {
    if (!jobDetails.containsKey(jobNo)) return 0.0;
    
    final jobDetail = jobDetails[jobNo]!;
    return jobDetail.allocatedQuantity - jobDetail.consumedQuantity;
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

  @HiveField(7)
  double issuedQuantity = 0.0;

  @HiveField(8)
  Map<String, double> issuedQuantities = {}; // PR -> Issued Quantity mapping

  double get availableQuantity => acceptedQuantity - issuedQuantity;

  StockGRNDetails({
    required this.grnNo,
    required this.grnDate,
    required this.receivedQuantity,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    required this.vendorId,
    required this.rate,
    this.issuedQuantity = 0.0,
    Map<String, double>? issuedQuantities,
  }) {
    this.issuedQuantities = Map<String, double>.from(issuedQuantities ?? {});
  }

  void addIssuedQuantity(String prNo, double quantity) {
    issuedQuantities[prNo] = (issuedQuantities[prNo] ?? 0.0) + quantity;
    issuedQuantity += quantity;
  }

  @override
  String toString() {
    return 'StockGRNDetails(grnNo: $grnNo, grnDate: $grnDate, receivedQuantity: $receivedQuantity, acceptedQuantity: $acceptedQuantity, rejectedQuantity: $rejectedQuantity, vendorId: $vendorId, rate: $rate, issuedQuantity: $issuedQuantity, issuedQuantities: $issuedQuantities)';
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

  @HiveField(7)
  double issuedQuantity = 0.0;

  @HiveField(8)
  Map<String, double> issuedQuantities = {}; // PR -> Issued Quantity mapping

  double get availableQuantity => receivedQuantity - issuedQuantity;

  StockPODetails({
    required this.poNo,
    required this.poDate,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.vendorId,
    required this.rate,
    Map<String, Map<String, double>>? receivedQuantities,
    this.issuedQuantity = 0.0,
    Map<String, double>? issuedQuantities,
  }) {
    this.receivedQuantities =
        Map<String, Map<String, double>>.from(receivedQuantities ?? {});
    this.issuedQuantities = Map<String, double>.from(issuedQuantities ?? {});
  }

  void addIssuedQuantity(String prNo, double quantity) {
    issuedQuantities[prNo] = (issuedQuantities[prNo] ?? 0.0) + quantity;
    issuedQuantity += quantity;
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

  // Helper method to get total issued quantity for a PR
  double getIssuedQuantityForPR(String prNo) {
    return issuedQuantities[prNo] ?? 0.0;
  }

  // Helper method to get available quantity for a PR
  double getAvailableQuantityForPR(String prNo) {
    return getReceivedQuantityForPR(prNo) - getIssuedQuantityForPR(prNo);
  }

  @override
  String toString() {
    return 'StockPODetails(poNo: $poNo, poDate: $poDate, orderedQuantity: $orderedQuantity, receivedQuantity: $receivedQuantity, vendorId: $vendorId, rate: $rate, receivedQuantities: $receivedQuantities, issuedQuantity: $issuedQuantity, issuedQuantities: $issuedQuantities)';
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

  @HiveField(5)
  double issuedQuantity = 0.0;

  @HiveField(6)
  String jobNo;

  double get availableQuantity => receivedQuantity - issuedQuantity;

  StockPRDetails({
    required this.prNo,
    required this.prDate,
    required this.requestedQuantity,
    required this.orderedQuantity,
    required this.receivedQuantity,
    this.issuedQuantity = 0.0,
    required this.jobNo,
  });

  @override
  String toString() {
    return 'StockPRDetails(prNo: $prNo, prDate: $prDate, requestedQuantity: $requestedQuantity, orderedQuantity: $orderedQuantity, receivedQuantity: $receivedQuantity, issuedQuantity: $issuedQuantity, jobNo: $jobNo)';
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
