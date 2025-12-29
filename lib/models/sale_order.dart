import 'package:hive/hive.dart';

part 'sale_order.g.dart';

@HiveType(typeId: 14)
class SaleOrder extends HiveObject {
  @HiveField(0)
  String orderNo;

  @HiveField(1)
  String orderDate;

  @HiveField(2)
  String customerName;

  @HiveField(3)
  String boardNo;

  @HiveField(4)
  String jobStartDate; // Sales Target Start Date

  @HiveField(5)
  String targetDate; // Sales Target End Date

  @HiveField(6)
  String? endDate; // Actual End Date
  
  @HiveField(7)
  String jobNo;
  
  @HiveField(8)
  String? planningStartDate; // Planning Target Start Date
  
  @HiveField(9)
  String? planningEndDate; // Planning Target End Date
  
  @HiveField(10)
  String? actualStartDate; // Actual Start Date
  
  @HiveField(11)
  String? customerRequirementDate; // Customer Requirement Date
  
  @HiveField(12)
  String? customerCommitmentDate; // Customer Commitment Date
  
  @HiveField(13)
  String? actualCustomerDeliveryDate; // Actual Customer Delivery Date
  
  @HiveField(14)
  String? jobStatus; // Job Status
  
  @HiveField(15)
  String? jobNotes; // Job Notes

  @HiveField(16)
  bool? isCustomerFreeIssueAvailable;

  @HiveField(17)
  String? customerPoNo;

  @HiveField(18)
  String? customerPoDate;

  SaleOrder({
    required this.orderNo,
    required this.orderDate,
    required this.customerName,
    required this.boardNo,
    required this.jobStartDate,
    required this.targetDate,
    this.endDate,
    required this.jobNo,
    this.planningStartDate,
    this.planningEndDate,
    this.actualStartDate,
    this.customerRequirementDate,
    this.customerCommitmentDate,
    this.actualCustomerDeliveryDate,
    this.jobStatus,
    this.jobNotes,
    this.isCustomerFreeIssueAvailable,
    this.customerPoNo,
    this.customerPoDate,
  });

  bool get isCompleted => endDate != null;
}
