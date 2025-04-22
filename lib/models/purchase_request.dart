import 'package:hive/hive.dart';
import 'pr_item.dart';

part 'purchase_request.g.dart';

@HiveType(typeId: 2)
class PurchaseRequest extends HiveObject {
  @HiveField(0)
  String prNo;

  @HiveField(1)
  String date;

  @HiveField(2)
  String requiredBy;

  @HiveField(3)
  String? _status;

  @HiveField(4)
  String supplierName;

  @HiveField(5)
  List<PRItem> items = [];

  String get status => _status ?? 'Draft';

  set status(String value) {
    _status = value;
  }

  bool get isFullyOrdered => items.every((item) => item.isFullyOrdered);

  void updateStatus() {
    if (isFullyOrdered) {
      status = 'Completed';
    } else if (items.any((item) => item.totalOrderedQuantity > 0)) {
      status = 'Partially Ordered';
    } else {
      status = 'Draft';
    }
    save();
  }

  PurchaseRequest({
    required this.prNo,
    required this.date,
    required this.requiredBy,
    String? status,
    required this.supplierName,
    List<PRItem>? items,
  }) {
    _status = status;
    if (items != null) {
      this.items = items;
    }
  }
}
