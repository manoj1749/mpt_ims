import 'package:hive/hive.dart';

part 'material_request_item.g.dart';

@HiveType(typeId: 31)
class MaterialRequestItem extends HiveObject {
  @HiveField(0)
  String materialCode;

  @HiveField(1)
  String materialDescription;

  @HiveField(2)
  String unit;

  @HiveField(3)
  String quantity;

  @HiveField(4)
  String issueNo;

  @HiveField(5)
  Map<String, double> issuedQuantities =
      {}; // Map of Material Issue No -> Issued Quantity

  double get totalIssuedQuantity =>
      issuedQuantities.values.fold(0.0, (sum, qty) => sum + qty);

  double get pendingQuantity => double.parse(quantity) - totalIssuedQuantity;

  MaterialRequestItem({
    required this.materialCode,
    required this.materialDescription,
    required this.unit,
    required this.quantity,
    required this.issueNo,
    Map<String, double>? issuedQuantities,
  }) {
    this.issuedQuantities = issuedQuantities ?? {};
  }

  void addIssuedQuantity(String materialIssueNo, double quantity) {
    issuedQuantities[materialIssueNo] = quantity;
    save();
  }

  void removeIssuedQuantity(String materialIssueNo) {
    issuedQuantities.remove(materialIssueNo);
    save();
  }
}
