import 'package:hive/hive.dart';

part 'job_order_request.g.dart';

@HiveType(typeId: 120)
class JobOrderRequest extends HiveObject {
  @HiveField(0)
  String requestNo;

  @HiveField(1)
  String requestDate;

  @HiveField(2)
  List<String> selectedJobs;

  @HiveField(3)
  Map<String, List<String>> materialsByRawMaterial; // Raw material -> List of material codes

  @HiveField(4)
  DateTime createdDate;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  String status; // 'pending', 'approved', 'rejected'

  JobOrderRequest({
    required this.requestNo,
    required this.requestDate,
    required this.selectedJobs,
    required this.materialsByRawMaterial,
    required this.createdDate,
    this.notes,
    this.status = 'pending',
  });

  String getModelId() {
    return '$requestNo-$createdDate.millisecondsSinceEpoch';
  }
}
