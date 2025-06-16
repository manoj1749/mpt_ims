// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/quality_inspection.dart';
import '../provider/stock_maintenance_provider.dart';

final qualityInspectionBoxProvider = Provider<Box<QualityInspection>>((ref) {
  throw UnimplementedError();
});

final qualityInspectionProvider =
    StateNotifierProvider<QualityInspectionNotifier, List<QualityInspection>>(
  (ref) {
    final box = ref.watch(qualityInspectionBoxProvider);
    final stockMaintenance = ref.watch(stockMaintenanceProvider.notifier);
    return QualityInspectionNotifier(box, stockMaintenance);
  },
);

class QualityInspectionNotifier extends StateNotifier<List<QualityInspection>> {
  final Box<QualityInspection> box;
  final StockMaintenanceNotifier stockMaintenance;

  QualityInspectionNotifier(this.box, this.stockMaintenance)
      : super(box.values.toList());

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

  void updateInspection(QualityInspection inspection) async {
    print('\n=== Debug: Updating Inspection ${inspection.inspectionNo} ===');

    // Find the index of the inspection to update
    final index = box.values.toList().indexWhere(
          (insp) => insp.inspectionNo == inspection.inspectionNo,
        );

    if (index != -1) {
      // Update inspection status based on all items
      bool allItemsAccepted = inspection.items.every((item) =>
          item.usageDecision == 'Lot Accepted' &&
          item.acceptedQty == item.receivedQty);

      bool allItemsRejected = inspection.items.every((item) =>
          item.usageDecision == 'Lot Rejected' &&
          item.rejectedQty == item.receivedQty);

      bool allItemsProcessed = inspection.items.every(
          (item) => item.acceptedQty + item.rejectedQty >= item.receivedQty);

      print('All Items Accepted: $allItemsAccepted');
      print('All Items Rejected: $allItemsRejected');
      print('All Items Processed: $allItemsProcessed');

      if (allItemsAccepted) {
        inspection.status = 'Completed - Accepted';
      } else if (allItemsRejected) {
        inspection.status = 'Completed - Rejected';
      } else if (allItemsProcessed) {
        inspection.status = 'Completed - Partial';
      } else {
        inspection.status = 'Pending';
      }

      print('Setting inspection status to: ${inspection.status}');

      // Update the inspection in Hive
      await box.putAt(index, inspection);
      state = box.values.toList();

      // Update stock if inspection is completed
      if (inspection.status.startsWith('Completed')) {
        print('Updating stock maintenance...');
        await stockMaintenance.updateStockFromInspection(inspection);
      }
    }
  }

  void deleteInspection(QualityInspection inspection) {
    // Find the index of the inspection to delete
    final index = box.values.toList().indexWhere(
          (insp) => insp.inspectionNo == inspection.inspectionNo,
        );

    if (index != -1) {
      box.deleteAt(index);
      state = box.values.toList();
    }
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
    return state
        .where((inspection) => inspection.supplierName == supplierName)
        .toList();
  }

  // Get inspections by date range
  List<QualityInspection> getInspectionsByDateRange(
      DateTime start, DateTime end) {
    return state.where((inspection) {
      final inspectionDate =
          DateFormat('yyyy-MM-dd').parse(inspection.inspectionDate);
      return inspectionDate.isAfter(start.subtract(const Duration(days: 1))) &&
          inspectionDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get inspections by material code
  List<QualityInspection> getInspectionsByMaterial(String materialCode) {
    return state
        .where((inspection) =>
            inspection.items.any((item) => item.materialCode == materialCode))
        .toList();
  }

  // Get total accepted quantity for a material from a specific GRN
  double getAcceptedQuantityForGRN(String materialCode, String grnNo) {
    return state.where((inspection) => inspection.grnNo == grnNo).fold(0.0,
        (sum, inspection) {
      return sum +
          inspection.items
              .where((item) => item.materialCode == materialCode)
              .fold(0.0, (itemSum, item) => itemSum + item.acceptedQty);
    });
  }

  // Get total rejected quantity for a material from a specific GRN
  double getRejectedQuantityForGRN(String materialCode, String grnNo) {
    return state.where((inspection) => inspection.grnNo == grnNo).fold(0.0,
        (sum, inspection) {
      return sum +
          inspection.items
              .where((item) => item.materialCode == materialCode)
              .fold(0.0, (itemSum, item) => itemSum + item.rejectedQty);
    });
  }

  // Get total pending quantity for a material from a specific GRN
  double getPendingQuantityForGRN(String materialCode, String grnNo) {
    return state.where((inspection) => inspection.grnNo == grnNo).fold(0.0,
        (sum, inspection) {
      return sum +
          inspection.items
              .where((item) => item.materialCode == materialCode)
              .fold(0.0, (itemSum, item) => itemSum + item.pendingQty);
    });
  }
}
