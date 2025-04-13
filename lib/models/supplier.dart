import 'package:hive/hive.dart';

part 'supplier.g.dart';

@HiveType(typeId: 0)
class Supplier extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) String contact;
  @HiveField(2) String phone;
  @HiveField(3) String email;
  @HiveField(4) String vendorCode;
  @HiveField(5) String address1;
  @HiveField(6) String address2;
  @HiveField(7) String address3;
  @HiveField(8) String address4;
  @HiveField(9) String state;
  @HiveField(10) String stateCode;
  @HiveField(11) String paymentTerms;
  @HiveField(12) String pan;
  @HiveField(13) String gstNo;
  @HiveField(14) String igst;
  @HiveField(15) String cgst;
  @HiveField(16) String sgst;
  @HiveField(17) String totalGst;
  @HiveField(18) String bank;
  @HiveField(19) String branch;
  @HiveField(20) String account;
  @HiveField(21) String ifsc;
  @HiveField(22) String email1;

  Supplier({
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
    required this.vendorCode,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.address4,
    required this.state,
    required this.stateCode,
    required this.paymentTerms,
    required this.pan,
    required this.gstNo,
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
