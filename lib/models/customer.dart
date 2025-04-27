import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 9)
class Customer extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String address1;

  @HiveField(2)
  String address2;

  @HiveField(3)
  String address3;

  @HiveField(4)
  String address4;

  @HiveField(5)
  String gstNo;

  @HiveField(6)
  String email;

  @HiveField(7)
  String contact;

  @HiveField(8)
  String paymentTerms;

  @HiveField(9)
  String phone;

  @HiveField(10)
  String customerCode; // equivalent to vendorCode

  @HiveField(11)
  String state;

  @HiveField(12)
  String stateCode;

  @HiveField(13)
  String pan;

  @HiveField(14)
  String igst;

  @HiveField(15)
  String cgst;

  @HiveField(16)
  String sgst;

  @HiveField(17)
  String totalGst;

  @HiveField(18)
  String bank;

  @HiveField(19)
  String branch;

  @HiveField(20)
  String account;

  @HiveField(21)
  String ifsc;

  @HiveField(22)
  String email1;

  Customer({
    required this.name,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.address4,
    required this.gstNo,
    required this.email,
    required this.contact,
    required this.paymentTerms,
    required this.phone,
    required this.customerCode,
    required this.state,
    required this.stateCode,
    required this.pan,
    required this.igst,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.bank,
    required this.branch,
    required this.account,
    required this.ifsc,
    required this.email1,
  });
}
