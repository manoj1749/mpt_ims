import 'package:hive/hive.dart';

part 'store_inward.g.dart';

@HiveType(typeId: 6)
class StoreInward extends HiveObject {
  @HiveField(0)
  String grnNo;

  @HiveField(1)
  String grnDate;

  @HiveField(2)
  String supplierName;

  @HiveField(3)
  String poNo;

  @HiveField(4)
  String poDate;

  @HiveField(5)
  String invoiceNo;

  @HiveField(6)
  String invoiceDate;

  @HiveField(7)
  String invoiceAmount;

  @HiveField(8)
  String receivedBy;

  @HiveField(9)
  String checkedBy;

  @HiveField(10)
  List<InwardItem> items;

  @HiveField(11)
  String? _status;

  String get status => _status ?? 'Pending';

  set status(String value) {
    _status = value;
  }

  bool get isFullyInspected => items.every((item) => item.isFullyInspected);

  void updateStatus() {
    if (isFullyInspected) {
      status = 'Completed';
    } else if (items.any((item) => item.inspectedQuantity > 0)) {
      status = 'Partially Inspected';
    } else {
      status = 'Pending';
    }
    save();
  }

  StoreInward({
    required this.grnNo,
    required this.grnDate,
    required this.supplierName,
    required this.poNo,
    required this.poDate,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.invoiceAmount,
    required this.receivedBy,
    required this.checkedBy,
    required this.items,
    String? status,
  }) {
    _status = status;
  }
}

@HiveType(typeId: 7)
class InwardItem {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double orderedQty;

  @HiveField(4)
  double receivedQty;

  @HiveField(5)
  double acceptedQty;

  @HiveField(6)
  double rejectedQty;

  @HiveField(7)
  String costPerUnit;

  @HiveField(8)
  Map<String, double> poQuantities =
      {}; // Store PO-wise quantities: PO No -> Quantity

  @HiveField(9)
  Map<String, double> inspectedQuantities =
      {}; // Map of inspection number to inspected quantity

  double get inspectedQuantity =>
      inspectedQuantities.values.fold(0.0, (sum, qty) => sum + qty);

  bool get isFullyInspected => inspectedQuantity >= receivedQty;

  void addInspectedQuantity(String inspectionNo, double quantity) {
    inspectedQuantities[inspectionNo] = quantity;
  }

  InwardItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.orderedQty,
    required this.receivedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.costPerUnit,
    Map<String, double>? poQuantities,
    Map<String, double>? inspectedQuantities,
  }) {
    this.poQuantities = poQuantities ?? {};
    this.inspectedQuantities = inspectedQuantities ?? {};
  }

  // Helper method to get total received quantity for a specific PO
  double getReceivedQuantityForPO(String poNo) {
    return poQuantities[poNo] ?? 0.0;
  }

  // Add received quantity for a PO
  void addReceivedQuantityForPO(String poNo, double quantity) {
    poQuantities[poNo] = (poQuantities[poNo] ?? 0.0) + quantity;
  }
}
