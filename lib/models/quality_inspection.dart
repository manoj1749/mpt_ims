import 'package:hive/hive.dart';

part 'quality_inspection.g.dart';

@HiveType(typeId: 11)
class QualityInspection extends HiveObject {
  @HiveField(0)
  String inspectionNo;

  @HiveField(1)
  String inspectionDate;

  // Purchase and Supplier Details
  @HiveField(2)
  String grnNo;

  @HiveField(3)
  String supplierName; // Supplier

  @HiveField(4)
  String poNo; // PO No

  // Logistics and Bill Details
  @HiveField(5)
  String billNo; // Bill No

  @HiveField(6)
  String billDate; // Bill Date

  @HiveField(7)
  String receivedDate; // Received Date

  @HiveField(8)
  String grnDate; // GR Date

  // Personnel Details
  @HiveField(9)
  String inspectedBy;

  @HiveField(10)
  String approvedBy;

  @HiveField(12)
  List<InspectionItem> items;

  @HiveField(13)
  String status; // Pending, Approved, Rejected, Recheck

  @HiveField(14)
  Map<String, String> prNumbers = {}; // Map of PO No to PR No

  @HiveField(15)
  Map<String, String> jobNumbers = {}; // Map of PO No to Job No

  QualityInspection({
    required this.inspectionNo,
    required this.inspectionDate,
    required this.grnNo,
    required this.supplierName,
    required this.poNo,
    required this.billNo,
    required this.billDate,
    required this.receivedDate,
    required this.grnDate,
    required this.inspectedBy,
    required this.approvedBy,
    required this.items,
    this.status = 'Pending',
    Map<String, String>? prNumbers,
    Map<String, String>? jobNumbers,
  }) {
    this.prNumbers = prNumbers ?? {};
    this.jobNumbers = jobNumbers ?? {};
  }
}

@HiveType(typeId: 12)
class InspectionItem extends HiveObject {
  @HiveField(0)
  String materialCode; // Part No

  @HiveField(1)
  String materialDescription; // Description

  @HiveField(2)
  String unit;

  @HiveField(3)
  String category;

  @HiveField(4)
  double receivedQty; // Total Qty

  @HiveField(5)
  double costPerUnit; // Cost/Unit

  @HiveField(6)
  double totalCost;

  @HiveField(7)
  double sampleSize;

  @HiveField(8)
  double inspectedQty;

  @HiveField(9)
  double acceptedQty;

  @HiveField(10)
  double rejectedQty;

  @HiveField(11)
  double pendingQty;

  @HiveField(13)
  String
      usageDecision; // Lot Accepted / Rejected / 100% Recheck / Conditionally Accepted

  @HiveField(14)
  String receivedDate; // Date when material was received

  @HiveField(15)
  String expirationDate; // Date when material will expire

  @HiveField(16)
  List<QualityParameter> parameters;

  @HiveField(17)
  bool? isPartialRecheck; // For 100% Recheck cases

  @HiveField(18)
  String? conditionalAcceptanceReason; // Reason for conditional acceptance

  @HiveField(19)
  String?
      conditionalAcceptanceAction; // Required action for conditional acceptance

  @HiveField(20)
  String?
      conditionalAcceptanceDeadline; // Deadline for completing the required action

  @HiveField(21)
  Map<String, InspectionPOQuantity> poQuantities =
      {}; // Store PO-wise quantities and decisions

  @HiveField(22)
  String? grnNo; // GRN number

  @HiveField(23)
  String? grnDate; // GRN date

  @HiveField(24)
  String? invoiceNo; // Invoice number

  @HiveField(25)
  String? invoiceDate; // Invoice date

  @HiveField(26)
  Map<String, Map<String, String>> grnDetails =
      {}; // PO No -> Map of GRN No to GRN details

  @HiveField(27)
  Map<String, InspectionGRNQuantity> grnQuantities =
      {}; // Store GRN-wise quantities and decisions

  @HiveField(28)
  String? inspectionRemark; // Remark for inspection

  @HiveField(29)
  bool capaRequired = false; // CAPA status for rejected/partially accepted lots

  @HiveField(30)
  String? recheckType; // '100% Acceptance' or 'Partial Acceptance'

  @HiveField(31)
  bool? conditionalAcceptance; // Whether conditional acceptance is applied

  InspectionItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.category,
    required this.receivedQty,
    required this.costPerUnit,
    required this.totalCost,
    required this.sampleSize,
    required this.inspectedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.pendingQty,
    required this.usageDecision,
    required this.receivedDate,
    required this.expirationDate,
    required this.parameters,
    this.isPartialRecheck = false,
    this.conditionalAcceptanceReason,
    this.conditionalAcceptanceAction,
    this.conditionalAcceptanceDeadline,
    Map<String, InspectionPOQuantity>? poQuantities,
    this.grnNo = '',
    this.grnDate = '',
    this.invoiceNo = '',
    this.invoiceDate = '',
    Map<String, Map<String, String>>? grnDetails,
    Map<String, InspectionGRNQuantity>? grnQuantities,
    this.inspectionRemark,
    this.recheckType,
    this.conditionalAcceptance = false,
  }) {
    this.poQuantities = poQuantities ?? {};
    this.grnDetails = grnDetails ?? {};
    this.grnQuantities = grnQuantities ?? {};
  }

  // Helper method to get total received quantity for a specific GRN
  double getReceivedQuantityForGRN(String grnNo) {
    return grnQuantities[grnNo]?.receivedQty ?? 0.0;
  }

  // Helper method to get total accepted quantity for a specific GRN
  double getAcceptedQuantityForGRN(String grnNo) {
    return grnQuantities[grnNo]?.acceptedQty ?? 0.0;
  }

  // Helper method to get total rejected quantity for a specific GRN
  double getRejectedQuantityForGRN(String grnNo) {
    return grnQuantities[grnNo]?.rejectedQty ?? 0.0;
  }

  // Helper method to get pending quantity for a specific GRN
  double getPendingQuantityForGRN(String grnNo) {
    final grnQty = grnQuantities[grnNo];
    if (grnQty == null) return 0.0;
    return grnQty.receivedQty - (grnQty.acceptedQty + grnQty.rejectedQty);
  }

  // Helper method to update quantities for a specific GRN
  void updateGRNQuantities(
    String grnNo, {
    double? receivedQty,
    double? acceptedQty,
    double? rejectedQty,
    String? usageDecision,
  }) {
    final grnQty = grnQuantities[grnNo] ??
        InspectionGRNQuantity(
          receivedQty: 0,
          acceptedQty: 0,
          rejectedQty: 0,
          usageDecision: this.usageDecision,
        );

    grnQuantities[grnNo] = grnQty.copyWith(
      receivedQty: receivedQty ?? grnQty.receivedQty,
      acceptedQty: acceptedQty ?? grnQty.acceptedQty,
      rejectedQty: rejectedQty ?? grnQty.rejectedQty,
      usageDecision: usageDecision ?? grnQty.usageDecision,
    );

    // Update total quantities
    this.receivedQty =
        grnQuantities.values.fold(0.0, (sum, qty) => sum + qty.receivedQty);
    this.acceptedQty =
        grnQuantities.values.fold(0.0, (sum, qty) => sum + qty.acceptedQty);
    this.rejectedQty =
        grnQuantities.values.fold(0.0, (sum, qty) => sum + qty.rejectedQty);
    pendingQty = this.receivedQty - (this.acceptedQty + this.rejectedQty);
  }

  // Helper method to update quantities for a specific PO
  void updatePOQuantities(
    String poNo, {
    double? receivedQty,
    double? acceptedQty,
    double? rejectedQty,
    String? usageDecision,
  }) {
    final poQty = poQuantities[poNo] ??
        InspectionPOQuantity(
          receivedQty: 0,
          acceptedQty: 0,
          rejectedQty: 0,
          usageDecision: this.usageDecision,
        );

    poQuantities[poNo] = poQty.copyWith(
      receivedQty: receivedQty ?? poQty.receivedQty,
      acceptedQty: acceptedQty ?? poQty.acceptedQty,
      rejectedQty: rejectedQty ?? poQty.rejectedQty,
      usageDecision: usageDecision ?? poQty.usageDecision,
    );

    // Update total quantities
    this.receivedQty =
        poQuantities.values.fold(0.0, (sum, qty) => sum + qty.receivedQty);
    this.acceptedQty =
        poQuantities.values.fold(0.0, (sum, qty) => sum + qty.acceptedQty);
    this.rejectedQty =
        poQuantities.values.fold(0.0, (sum, qty) => sum + qty.rejectedQty);
    pendingQty = this.receivedQty - (this.acceptedQty + this.rejectedQty);
  }
}

@HiveType(typeId: 20)
class InspectionPOQuantity extends HiveObject {
  @HiveField(0)
  double receivedQty;

  @HiveField(1)
  double acceptedQty;

  @HiveField(2)
  double rejectedQty;

  @HiveField(3)
  String usageDecision;

  @HiveField(4)
  String? recheckType; // '100% Acceptance' or 'Partial Acceptance'

  @HiveField(5)
  bool? conditionalAcceptance; // Whether conditional acceptance is applied

  InspectionPOQuantity({
    required this.receivedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.usageDecision,
    this.recheckType,
    this.conditionalAcceptance = false,
  });

  InspectionPOQuantity copyWith({
    double? receivedQty,
    double? acceptedQty,
    double? rejectedQty,
    String? usageDecision,
  }) {
    return InspectionPOQuantity(
      receivedQty: receivedQty ?? this.receivedQty,
      acceptedQty: acceptedQty ?? this.acceptedQty,
      rejectedQty: rejectedQty ?? this.rejectedQty,
      usageDecision: usageDecision ?? this.usageDecision,
    );
  }
}

@HiveType(typeId: 21)
class InspectionGRNQuantity {
  @HiveField(0)
  double receivedQty;

  @HiveField(1)
  double acceptedQty;

  @HiveField(2)
  double rejectedQty;

  @HiveField(3)
  String usageDecision;

  InspectionGRNQuantity({
    required this.receivedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.usageDecision,
  });

  InspectionGRNQuantity copyWith({
    double? receivedQty,
    double? acceptedQty,
    double? rejectedQty,
    String? usageDecision,
  }) {
    return InspectionGRNQuantity(
      receivedQty: receivedQty ?? this.receivedQty,
      acceptedQty: acceptedQty ?? this.acceptedQty,
      rejectedQty: rejectedQty ?? this.rejectedQty,
      usageDecision: usageDecision ?? this.usageDecision,
    );
  }
}

@HiveType(typeId: 13)
class QualityParameter {
  @HiveField(0)
  String parameter;

  @HiveField(1)
  String specification;

  @HiveField(2)
  bool isAcceptable;

  QualityParameter({
    required this.parameter,
    this.specification = '',
    this.isAcceptable = true,
  });

  // Standard Quality Parameters - Exact names as per sheet
  static const String visualCheck = 'Visual Check';
  static const String approvedMake = 'Check for Approved Make/Supplier';
  static const String surfaceFinish = 'Surface Finish';
  static const String dimensionalCheck = 'Dimensional Check';
  static const String ratingType = 'Rating/Type';
  static const String functionalCheck = 'Functional Check';
  static const String mouldingQuality = 'Moulding Quality (Deflashing)';
  static const String platingQuality = 'Plating Quality';
  static const String gradeCheck = 'Grade Check';
  static const String colourShade = 'Colour/Shade';
  static const String referenceStandard =
      'Check for Reference Standard (IS/IEC)';
  static const String conformanceReport = 'Review & Verify Conformance Report';
}
