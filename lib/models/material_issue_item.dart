import 'package:hive/hive.dart';

part 'material_issue_item.g.dart';

@HiveType(typeId: 33)
class ItemMRDetails {
  @HiveField(0)
  String mrNo;

  @HiveField(1)
  String jobNo;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  String? prNo;

  ItemMRDetails({
    required this.mrNo,
    required this.jobNo,
    required this.quantity,
    this.prNo,
  });

  @override
  String toString() {
    return 'ItemMRDetails(mrNo: $mrNo, jobNo: $jobNo, quantity: $quantity, prNo: $prNo)';
  }
}

@HiveType(typeId: 34)
class MaterialIssueItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  Map<String, ItemMRDetails> mrDetails = {}; // MR No -> MR Details

  @HiveField(5)
  Map<String, double> issuedQuantities = {}; // MR No -> issued quantity

  @HiveField(6)
  Map<String, String> prMapping = {};  // Add PR mapping field

  // Get total issued quantity
  double get totalIssuedQuantity {
    return issuedQuantities.values.fold(0.0, (sum, qty) => sum + qty);
  }

  // Get total issued quantity for a specific MR
  double getIssuedQuantityForMR(String mrNo) {
    return issuedQuantities[mrNo] ?? 0.0;
  }

  // Get pending quantity for a specific MR
  double getPendingQuantityForMR(String mrNo) {
    final mrDetail = mrDetails[mrNo];
    if (mrDetail == null) return 0.0;

    final requestedQty = mrDetail.quantity;
    final issuedQty = getIssuedQuantityForMR(mrNo);

    return requestedQty - issuedQty;
  }

  // Get all unique job numbers for this item
  Set<String> get jobNumbers {
    final jobs = <String>{};
    for (var detail in mrDetails.values) {
      if (detail.jobNo != 'General') {
        jobs.add(detail.jobNo);
      }
    }
    return jobs;
  }

  // Helper method to add issued quantity
  void addIssuedQuantity(String mrNo, double quantity) {
    issuedQuantities[mrNo] = (issuedQuantities[mrNo] ?? 0.0) + quantity;
  }

  MaterialIssueItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.mrDetails,
    required this.issuedQuantities,
    required this.prMapping,
  }) {
    mrDetails = mrDetails;
    issuedQuantities = issuedQuantities;
    prMapping = prMapping;
  }

  MaterialIssueItem copyWith({
    String? materialCode,
    String? materialDescription,
    String? unit,
    double? quantity,
    Map<String, ItemMRDetails>? mrDetails,
    Map<String, double>? issuedQuantities,
    Map<String, String>? prMapping,
  }) {
    return MaterialIssueItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      mrDetails: mrDetails ?? Map.from(this.mrDetails),
      issuedQuantities: issuedQuantities ?? Map.from(this.issuedQuantities),
      prMapping: prMapping ?? Map.from(this.prMapping),
    );
  }

  @override
  String toString() {
    return 'MaterialIssueItem(materialCode: $materialCode, materialDescription: $materialDescription, unit: $unit, quantity: $quantity, mrDetails: $mrDetails, issuedQuantities: $issuedQuantities, prMapping: $prMapping)';
  }
}
