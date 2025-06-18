import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_issue.dart';

final materialIssueBoxProvider = Provider<Box<MaterialIssue>>((ref) {
  throw UnimplementedError();
});

final materialIssueListProvider =
    NotifierProvider<MaterialIssueNotifier, List<MaterialIssue>>(
  () => MaterialIssueNotifier(),
);

class MaterialIssueNotifier extends Notifier<List<MaterialIssue>> {
  late Box<MaterialIssue> _issueBox;

  @override
  List<MaterialIssue> build() {
    _issueBox = ref.watch(materialIssueBoxProvider);
    return _issueBox.values.toList();
  }

  // Add a new material issue
  Future<void> addMaterialIssue(MaterialIssue issue) async {
    await _issueBox.add(issue);
    state = [...state, issue];
  }

  // Update an existing material issue
  Future<void> updateMaterialIssue(MaterialIssue issue) async {
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      await _issueBox.putAt(index, issue);
      state = [..._issueBox.values.toList()];
    }
  }

  // Delete a material issue
  Future<void> deleteMaterialIssue(String issueNo) async {
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      await _issueBox.deleteAt(index);
      state = [..._issueBox.values.toList()];
    }
  }

  // Get a material issue by issue number
  MaterialIssue? getMaterialIssue(String issueNo) {
    return _issueBox.values.firstWhere(
      (issue) => issue.issueNo == issueNo,
      orElse: () => throw Exception('Material Issue not found'),
    );
  }

  // Generate new issue number
  String generateIssueNo() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    
    // Get count of issues for today
    final todayIssues = _issueBox.values.where((issue) {
      return issue.issueNo.startsWith('MI$year$month$day');
    }).length;
    
    final count = (todayIssues + 1).toString().padLeft(3, '0');
    return 'MI$year$month$day$count';
  }

  // Update issue status
  Future<void> updateStatus(String issueNo, String status) async {
    final issue = getMaterialIssue(issueNo);
    if (issue != null) {
      issue.status = status;
      await updateMaterialIssue(issue);
    }
  }
} 