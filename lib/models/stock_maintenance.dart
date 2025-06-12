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
  late Map<String, StockVendorDetails> vendorDetails; // Vendor-wise stock details

  @HiveField(12)
  double totalStockValue; // Total value of current stock

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
  }

  // Helper method to add PO details
  void addPODetails(String poNo, StockPODetails details) {
    poDetails[poNo] = details;
  }

  // Helper method to add PR details
  void addPRDetails(String prNo, StockPRDetails details) {
    prDetails[prNo] = details;
  }

  // Helper method to add Job details
  void addJobDetails(String jobNo, StockJobDetails details) {
    jobDetails[jobNo] = details;
  }

  // Helper method to add Vendor details
  void addVendorDetails(String vendorId, StockVendorDetails details) {
    vendorDetails[vendorId] = details;
    _updateTotalStockValue();
  }

  // Helper method to update stock under inspection
  void updateStockUnderInspection(double quantity) {
    stockUnderInspection = quantity;
  }

  // Helper method to update current stock
  void updateCurrentStock(double quantity) {
    currentStock = quantity;
    _updateTotalStockValue();
  }

  // Private method to update total stock value
  void _updateTotalStockValue() {
    double total = 0.0;
    for (var vendor in vendorDetails.values) {
      total += vendor.quantity * vendor.rate;
    }
    totalStockValue = total;
  }

  // Get average rate per unit
  double get averageRate {
    if (currentStock <= 0) return 0.0;
    return totalStockValue / currentStock;
  }

  // Get total stock (current + under inspection)
  double get totalStock => currentStock + stockUnderInspection;
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

  StockPODetails({
    required this.poNo,
    required this.poDate,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.vendorId,
    required this.rate,
  });
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
} 