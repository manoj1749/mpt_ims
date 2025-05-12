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

  @HiveField(11)
  String remarks;

  @HiveField(12)
  List<InspectionItem> items;

  @HiveField(13)
  String status; // Pending, Approved, Rejected, Recheck

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
    required this.remarks,
    required this.items,
    this.status = 'Pending',
  });
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
  double receivedQty; // Qty

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

  @HiveField(12)
  String remarks;

  @HiveField(13)
  String usageDecision; // Lot Accepted / Rejected / 100% Recheck / Conditionally Accepted

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
  String? conditionalAcceptanceAction; // Required action for conditional acceptance

  @HiveField(20)
  String? conditionalAcceptanceDeadline; // Deadline for completing the required action

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
    required this.remarks,
    required this.usageDecision,
    required this.receivedDate,
    required this.expirationDate,
    required this.parameters,
    this.isPartialRecheck = false,
    this.conditionalAcceptanceReason,
    this.conditionalAcceptanceAction,
    this.conditionalAcceptanceDeadline,
  });
}

@HiveType(typeId: 13)
class QualityParameter {
  @HiveField(0)
  String parameter;

  @HiveField(1)
  String specification;

  @HiveField(2)
  String observation;

  @HiveField(3)
  bool isAcceptable;

  @HiveField(4)
  String remarks;

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

  // Get list of standard parameters
  static List<String> get standardParameters => [
        visualCheck,
        approvedMake,
        surfaceFinish,
        dimensionalCheck,
        ratingType,
        functionalCheck,
        mouldingQuality,
        platingQuality,
        gradeCheck,
        colourShade,
        referenceStandard,
        conformanceReport,
      ];

  QualityParameter({
    required this.parameter,
    required this.specification,
    required this.observation,
    required this.isAcceptable,
    required this.remarks,
  });
}
