import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/job_order_request.dart';

class JobOrderRequestNotifier extends StateNotifier<List<JobOrderRequest>> {
  final Box<JobOrderRequest> _box;

  JobOrderRequestNotifier(this._box) : super(_box.values.toList()) {
    // Listen to Hive changes
    _box.watch().listen((event) {
      state = _box.values.toList();
    });
  }

  /// Get current financial year (e.g., 2026 for FY 2026-27)
  int getCurrentFinancialYear() {
    final now = DateTime.now();
    // Financial year in India: April 1 to March 31
    // If current month is Jan-Mar, FY is previous year
    // If current month is Apr-Dec, FY is current year
    if (now.month >= 4) {
      return now.year;
    } else {
      return now.year - 1;
    }
  }

  /// Generate next JOR number for new job order requests
  /// Format: JOR{FY}{6-digit-sequence} e.g., JOR2627000001
  String generateNextJORNumber() {
    final financialYear = getCurrentFinancialYear();
    final nextFinancialYear = financialYear + 1;

    // Get last 2 digits of current and next financial year
    final currentYearStr = financialYear.toString().substring(2);
    final nextYearStr = nextFinancialYear.toString().substring(2);
    final yearPrefix = '$currentYearStr$nextYearStr';

    // Get all JORs with the same prefix and financial year
    final existingJORs = state.where((jor) => 
      jor.requestNo.startsWith('JOR$yearPrefix')
    ).toList();
    
    if (existingJORs.isEmpty) {
      return 'JOR$yearPrefix${'000001'}';
    }
    
    // Extract sequence numbers and find max
    int maxSequence = 0;
    for (final jor in existingJORs) {
      final sequenceStr = jor.requestNo.substring(7); // After "JOR2627"
      final sequence = int.tryParse(sequenceStr) ?? 0;
      if (sequence > maxSequence) {
        maxSequence = sequence;
      }
    }
    
    // Generate next sequence with 6 digits padding
    final nextSequence = maxSequence + 1;
    return 'JOR$yearPrefix${nextSequence.toString().padLeft(6, '0')}';
  }

  Future<void> addJobOrderRequest(JobOrderRequest jobOrderRequest) async {
    await _box.add(jobOrderRequest);
    state = _box.values.toList();
  }

  Future<void> updateJobOrderRequest(int index, JobOrderRequest jobOrderRequest) async {
    await _box.putAt(index, jobOrderRequest);
    state = _box.values.toList();
  }

  Future<void> deleteJobOrderRequest(int index) async {
    await _box.deleteAt(index);
    state = _box.values.toList();
  }

  List<JobOrderRequest> searchJobOrderRequests(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((jor) =>
            jor.requestNo.toLowerCase().contains(lowercaseQuery) ||
            jor.selectedJobs.any((job) => job.toLowerCase().contains(lowercaseQuery)) ||
            jor.status.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}

final jobOrderRequestBoxProvider = Provider<Box<JobOrderRequest>>((ref) {
  throw UnimplementedError();
});

final jobOrderRequestProvider =
    StateNotifierProvider<JobOrderRequestNotifier, List<JobOrderRequest>>((ref) {
  final box = ref.watch(jobOrderRequestBoxProvider);
  return JobOrderRequestNotifier(box);
});
