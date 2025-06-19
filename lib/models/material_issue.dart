import 'package:hive/hive.dart';
import 'material_issue_item.dart';
part 'material_issue.g.dart';

@HiveType(typeId: 32)
class MaterialIssue extends HiveObject {
  @HiveField(0)
  String issueNo;

  @HiveField(1)
  String issueDate;

  @HiveField(2)
  String issuedTo; // Department or person name

  @HiveField(3)
  List<MaterialIssueItem> items;

  @HiveField(4)
  String? _status;

  String get status => _status ?? 'Pending';

  set status(String value) {
    _status = value;
  }

  // Get all unique job numbers from all items
  Set<String> get jobNumbers {
    final jobs = <String>{};
    for (var item in items) {
      for (var mrDetail in item.mrDetails.values) {
        if (mrDetail.jobNo != 'General') {
          jobs.add(mrDetail.jobNo);
        }
      }
    }
    return jobs;
  }

  // Get a formatted string for job number display
  String get formattedJobNo {
    final jobs = jobNumbers;
    if (jobs.isEmpty) {
      return 'General Stock';
    } else {
      return jobs.join(', ');
    }
  }

  MaterialIssue({
    required this.issueNo,
    required this.issueDate,
    required this.issuedTo,
    required this.items,
    String? status,
  }) {
    _status = status;
  }

  MaterialIssue copyWith({
    String? issueNo,
    String? issueDate,
    String? issuedTo,
    List<MaterialIssueItem>? items,
    String? status,
  }) {
    return MaterialIssue(
      issueNo: issueNo ?? this.issueNo,
      issueDate: issueDate ?? this.issueDate,
      issuedTo: issuedTo ?? this.issuedTo,
      items: items ?? this.items.map((item) => item.copyWith()).toList(),
      status: status ?? _status,
    );
  }
} 