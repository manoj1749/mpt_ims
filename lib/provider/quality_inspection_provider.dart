import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/quality_inspection.dart';

final qualityInspectionBoxProvider = Provider<Box<QualityInspection>>((ref) {
  throw UnimplementedError();
});

final qualityInspectionProvider =
    StateNotifierProvider<QualityInspectionNotifier, List<QualityInspection>>(
  (ref) => QualityInspectionNotifier(ref.watch(qualityInspectionBoxProvider)),
);

class QualityInspectionNotifier extends StateNotifier<List<QualityInspection>> {
  final Box<QualityInspection> box;

  QualityInspectionNotifier(this.box) : super(box.values.toList());

  String generateInspectionNumber() {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    
    // Get all inspections from today
    final todayInspections = state.where((inspection) {
      return inspection.inspectionNo.startsWith('QC$dateStr');
    }).toList();

    // Get the next sequence number
    final nextSeq = (todayInspections.length + 1).toString().padLeft(3, '0');
    
    return 'QC$dateStr$nextSeq';
  }

  void addInspection(QualityInspection inspection) {
    box.add(inspection);
    state = box.values.toList();
  }

  void updateInspection(QualityInspection inspection) {
    inspection.save();
    state = box.values.toList();
  }

  void deleteInspection(QualityInspection inspection) {
    inspection.delete();
    state = box.values.toList();
  }

  // Get pending inspections
  List<QualityInspection> getPendingInspections() {
    return state.where((inspection) => inspection.status == 'Pending').toList();
  }

  // Get completed inspections (both approved and rejected)
  List<QualityInspection> getCompletedInspections() {
    return state.where((inspection) => inspection.status != 'Pending').toList();
  }

  // Get inspections by GRN
  List<QualityInspection> getInspectionsByGRN(String grnNo) {
    return state.where((inspection) => inspection.grnNo == grnNo).toList();
  }

  // Get inspections by supplier
  List<QualityInspection> getInspectionsBySupplier(String supplierName) {
    return state.where((inspection) => inspection.supplierName == supplierName).toList();
  }

  // Get inspections by date range
  List<QualityInspection> getInspectionsByDateRange(DateTime start, DateTime end) {
    return state.where((inspection) {
      final inspectionDate = DateFormat('yyyy-MM-dd').parse(inspection.inspectionDate);
      return inspectionDate.isAfter(start.subtract(const Duration(days: 1))) &&
          inspectionDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
} 