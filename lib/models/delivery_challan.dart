import 'package:hive/hive.dart';

part 'delivery_challan.g.dart';

@HiveType(typeId: 40)
class DeliveryChallanItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  String? jobNo; // Optional job number, if not provided uses general stock

  @HiveField(5)
  String? prNo; // Optional PR number if issuing from specific PR

  DeliveryChallanItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    this.jobNo,
    this.prNo,
  });

  DeliveryChallanItem copyWith({
    String? materialCode,
    String? materialDescription,
    String? unit,
    double? quantity,
    String? jobNo,
    String? prNo,
  }) {
    return DeliveryChallanItem(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      jobNo: jobNo ?? this.jobNo,
      prNo: prNo ?? this.prNo,
    );
  }
}

@HiveType(typeId: 41)
class DeliveryChallan extends HiveObject {
  @HiveField(0)
  String dcNo; // Delivery Challan number

  @HiveField(1)
  String dcDate;

  @HiveField(2)
  String vendorName;

  @HiveField(3)
  String? vendorEmail;

  @HiveField(4)
  String? vendorGstin;

  @HiveField(5)
  List<DeliveryChallanItem> items;

  @HiveField(6)
  bool isReturnable;

  @HiveField(7)
  String? note;

  @HiveField(8, defaultValue: 'regular')
  String dcType; // 'internal', 'regular', 'job_order', 'material_return'

  @HiveField(9, defaultValue: '')
  String? invoiceNumber; // For regular DC

  @HiveField(10, defaultValue: 0.0)
  double? invoiceAmount; // For regular DC

  @HiveField(11, defaultValue: '')
  String? paymentStatus; // For regular DC: 'pending', 'paid', 'partial'

  @HiveField(12, defaultValue: '')
  String? jobOrderNumber; // For job order DC

  @HiveField(13, defaultValue: '')
  String? inspectionNumber; // For material return DC

  @HiveField(14, defaultValue: '')
  String? grnNumber; // For material return DC

  @HiveField(15, defaultValue: '')
  String? rejectionReason; // For material return DC

  @HiveField(16, defaultValue: '')
  String? debitNoteNumber; // For material return DC

  @HiveField(17, defaultValue: '')
  String? fromVendor; // For internal DC

  @HiveField(18, defaultValue: '')
  String? toVendor; // For internal DC

  @HiveField(19, defaultValue: '')
  String? siteAddress; // For job order DC

  @HiveField(20, defaultValue: '')
  String? expectedReturnDate; // For job order DC

  @HiveField(21, defaultValue: '')
  String? returnStatus; // For material return DC: 'pending', 'returned', 'accepted'

  @HiveField(22, defaultValue: 'outward')
  String internalFlow; // For internal DC: 'inward' or 'outward'

  DeliveryChallan({
    required this.dcNo,
    required this.dcDate,
    required this.vendorName,
    this.vendorEmail,
    this.vendorGstin,
    required this.items,
    required this.isReturnable,
    this.note,
    this.dcType = 'regular',
    this.invoiceNumber,
    this.invoiceAmount,
    this.paymentStatus,
    this.jobOrderNumber,
    this.inspectionNumber,
    this.grnNumber,
    this.rejectionReason,
    this.debitNoteNumber,
    this.fromVendor,
    this.toVendor,
    this.siteAddress,
    this.expectedReturnDate,
    this.returnStatus,
    this.internalFlow = 'outward',
  });

  DeliveryChallan copyWith({
    String? dcNo,
    String? dcDate,
    String? vendorName,
    String? vendorEmail,
    String? vendorGstin,
    List<DeliveryChallanItem>? items,
    bool? isReturnable,
    String? note,
    String? dcType,
    String? invoiceNumber,
    double? invoiceAmount,
    String? paymentStatus,
    String? jobOrderNumber,
    String? inspectionNumber,
    String? grnNumber,
    String? rejectionReason,
    String? debitNoteNumber,
    String? fromVendor,
    String? toVendor,
    String? siteAddress,
    String? expectedReturnDate,
    String? returnStatus,
    String? internalFlow,
  }) {
    return DeliveryChallan(
      dcNo: dcNo ?? this.dcNo,
      dcDate: dcDate ?? this.dcDate,
      vendorName: vendorName ?? this.vendorName,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorGstin: vendorGstin ?? this.vendorGstin,
      items: items ?? List.from(this.items),
      isReturnable: isReturnable ?? this.isReturnable,
      note: note ?? this.note,
      dcType: dcType ?? this.dcType,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      jobOrderNumber: jobOrderNumber ?? this.jobOrderNumber,
      inspectionNumber: inspectionNumber ?? this.inspectionNumber,
      grnNumber: grnNumber ?? this.grnNumber,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      debitNoteNumber: debitNoteNumber ?? this.debitNoteNumber,
      fromVendor: fromVendor ?? this.fromVendor,
      toVendor: toVendor ?? this.toVendor,
      siteAddress: siteAddress ?? this.siteAddress,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      returnStatus: returnStatus ?? this.returnStatus,
      internalFlow: internalFlow ?? this.internalFlow,
    );
  }
}
