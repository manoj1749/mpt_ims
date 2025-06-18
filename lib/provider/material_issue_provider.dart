import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_request.dart';

final MaterialRequestBoxProvider = Provider<Box<MaterialRequest>>((ref) {
  throw UnimplementedError();
});

final MaterialRequestListProvider =
    NotifierProvider<MaterialRequestNotifier, List<MaterialRequest>>(
  () => MaterialRequestNotifier(),
);

class MaterialRequestNotifier extends Notifier<List<MaterialRequest>> {
  late Box<MaterialRequest> _issueBox;

  @override
  List<MaterialRequest> build() {
    _issueBox = ref.watch(MaterialRequestBoxProvider);
    return _issueBox.values.toList();
  }

  // Add a new Material Request
  Future<void> addMaterialRequest(MaterialRequest issue) async {
    await _issueBox.add(issue);
    state = [...state, issue];
  }

  // Update an existing Material Request
  Future<void> updateMaterialRequest(MaterialRequest issue) async {
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issue.issueNo);
    if (index != -1) {
      await _issueBox.putAt(index, issue);
      state = [..._issueBox.values.toList()];
    }
  }

  // Delete a Material Request
  Future<void> deleteMaterialRequest(String issueNo) async {
    final index = _issueBox.values.toList().indexWhere((i) => i.issueNo == issueNo);
    if (index != -1) {
      await _issueBox.deleteAt(index);
      state = [..._issueBox.values.toList()];
    }
  }

  // Get a Material Request by issue number
  MaterialRequest? getMaterialRequest(String issueNo) {
    return _issueBox.values.firstWhere(
      (issue) => issue.issueNo == issueNo,
      orElse: () => throw Exception('Material Request not found'),
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
    final issue = getMaterialRequest(issueNo);
    if (issue != null) {
      issue.status = status;
      await updateMaterialRequest(issue);
    }
  }
} 