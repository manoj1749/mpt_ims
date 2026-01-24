import 'package:hive/hive.dart';

part 'customer_scope_stock_maintenance.g.dart';

@HiveType(typeId: 36)
class CustomerScopeStockMaintenance extends HiveObject {
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
  late Map<String, CustomerScopeGRNDetails> grnDetails; // GRN-wise stock details

  @HiveField(8)
  late Map<String, CustomerScopeJobDetails> jobDetails; // Job-wise stock details

  @HiveField(9)
  String customerName; // Customer name for this scope material

  @HiveField(10)
  String customerId; // Customer ID

  @HiveField(11)
  double totalStockValue; // Total value of current stock

  // Getters for accurate stock calculations
  double get calculatedCurrentStock {
    return grnDetails.values
        .fold(0.0, (sum, grn) => sum + (grn.acceptedQuantity - grn.issuedQuantity));
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

  double get averageRate {
    double totalValue = 0.0;
    double totalQty = 0.0;

    for (var grn in grnDetails.values) {
      if (grn.acceptedQuantity > 0) {
        totalValue += grn.acceptedQuantity * grn.rate;
        totalQty += grn.acceptedQuantity;
      }
    }

    return totalQty > 0 ? totalValue / totalQty : 0.0;
  }

  double get totalStock => currentStock + stockUnderInspection;

  CustomerScopeStockMaintenance({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.storageLocation,
    required this.rackNumber,
    required this.customerName,
    required this.customerId,
    this.currentStock = 0.0,
    this.stockUnderInspection = 0.0,
    Map<String, CustomerScopeGRNDetails>? grnDetails,
    Map<String, CustomerScopeJobDetails>? jobDetails,
    this.totalStockValue = 0.0,
  }) {
    this.grnDetails = grnDetails ?? {};
    this.jobDetails = jobDetails ?? {};
  }

  // Helper method to add GRN details
  void addGRNDetails(String grnNo, CustomerScopeGRNDetails details) {
    grnDetails[grnNo] = details;
    _updateTotalStockValue();
  }

  // Helper method to add Job details
  void addJobDetails(String jobNo, CustomerScopeJobDetails details) {
    jobDetails[jobNo] = details;
  }

  // Update stock quantities
  void updateCurrentStock(double newStock) {
    currentStock = newStock;
    _updateTotalStockValue();
  }

  void updateStockUnderInspection(double newStock) {
    stockUnderInspection = newStock;
  }

  void _updateTotalStockValue() {
    totalStockValue = currentStock * averageRate;
  }

  // Issue stock for a job
  void issueStockForJob(String jobNo, String issueNo, double quantity) {
    if (currentStock < quantity) {
      throw Exception('Insufficient stock. Available: $currentStock, Requested: $quantity');
    }

    // Update job details
    if (!jobDetails.containsKey(jobNo)) {
      jobDetails[jobNo] = CustomerScopeJobDetails(
        jobNo: jobNo,
        allocatedQuantity: 0.0,
        consumedQuantity: 0.0,
      );
    }
    jobDetails[jobNo]!.consumedQuantity += quantity;

    // Update GRN issued quantities (FIFO)
    double remainingQty = quantity;
    for (var grnEntry in grnDetails.entries.toList()..sort((a, b) => a.value.grnDate.compareTo(b.value.grnDate))) {
      if (remainingQty <= 0) break;

      final grn = grnEntry.value;
      final availableInGrn = grn.acceptedQuantity - grn.issuedQuantity;

      if (availableInGrn > 0) {
        final qtyToIssue = remainingQty > availableInGrn ? availableInGrn : remainingQty;
        grn.issuedQuantity += qtyToIssue;
        grn.issuedQuantities[issueNo] = (grn.issuedQuantities[issueNo] ?? 0.0) + qtyToIssue;
        remainingQty -= qtyToIssue;
      }
    }

    // Update current stock
    currentStock -= quantity;
    _updateTotalStockValue();
  }
}

@HiveType(typeId: 37)
class CustomerScopeGRNDetails {
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
  double rate;

  @HiveField(6)
  double issuedQuantity;

  @HiveField(7)
  late Map<String, double> issuedQuantities; // Issue No -> Quantity

  CustomerScopeGRNDetails({
    required this.grnNo,
    required this.grnDate,
    required this.receivedQuantity,
    this.acceptedQuantity = 0.0,
    this.rejectedQuantity = 0.0,
    this.rate = 0.0,
    this.issuedQuantity = 0.0,
    Map<String, double>? issuedQuantities,
  }) {
    this.issuedQuantities = issuedQuantities ?? {};
  }
}

@HiveType(typeId: 38)
class CustomerScopeJobDetails {
  @HiveField(0)
  String jobNo;

  @HiveField(1)
  double allocatedQuantity;

  @HiveField(2)
  double consumedQuantity;

  CustomerScopeJobDetails({
    required this.jobNo,
    this.allocatedQuantity = 0.0,
    this.consumedQuantity = 0.0,
  });
}
