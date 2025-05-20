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

  @HiveField(5)
  List<PRItem> items = [];

  @HiveField(6)
  String? jobNo;

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
    List<PRItem>? items,
    this.jobNo,
  }) {
    _status = status;
    if (items != null) {
      this.items = items;
    }
  }

  PurchaseRequest copyWith({
    String? prNo,
    String? date,
    String? requiredBy,
    String? status,
    List<PRItem>? items,
    String? jobNo,
  }) {
    return PurchaseRequest(
      prNo: prNo ?? this.prNo,
      date: date ?? this.date,
      requiredBy: requiredBy ?? this.requiredBy,
      status: status ?? this._status,
      items: items ?? this.items.map((item) => item.copyWith()).toList(),
      jobNo: jobNo ?? this.jobNo,
    );
  }
}
