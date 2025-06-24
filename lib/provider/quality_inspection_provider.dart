// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/quality_inspection.dart';
import '../provider/stock_maintenance_provider.dart';
import '../provider/store_inward_provider.dart';

final qualityInspectionBoxProvider = Provider<Box<QualityInspection>>((ref) {
  throw UnimplementedError();
});

final qualityInspectionProvider =
    StateNotifierProvider<QualityInspectionNotifier, List<QualityInspection>>(
  (ref) {
    final box = ref.watch(qualityInspectionBoxProvider);
    final stockMaintenance = ref.watch(stockMaintenanceProvider.notifier);
    final storeInward = ref.watch(storeInwardProvider.notifier);
    return QualityInspectionNotifier(box, stockMaintenance, storeInward);
  },
);

class QualityInspectionNotifier extends StateNotifier<List<QualityInspection>> {
  final Box<QualityInspection> box;
  final StockMaintenanceNotifier stockMaintenance;
  final StoreInwardNotifier storeInward;

  QualityInspectionNotifier(this.box, this.stockMaintenance, this.storeInward)
      : super(box.values.toList());

  String generateInspectionNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // Get last 2 digits of year
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    // Get all inspections from this year
    final yearInspections = state
        .where((inspection) => inspection.inspectionNo.startsWith('QI$year'))
        .toList();

    // Get the highest sequence number
    int maxSeq = 0;
    for (var inspection in yearInspections) {
      try {
        final seq = int.parse(inspection.inspectionNo.substring(8));
        if (seq > maxSeq) maxSeq = seq;
      } catch (e) {
        print('Error parsing sequence number: $e');
      }
    }

    // Generate new sequence number
    final seq = (maxSeq + 1).toString().padLeft(4, '0');

    return 'QI$year$month$day$seq';
  }

  Future<void> addInspection(QualityInspection inspection) async {
    // Generate inspection number if not provided
    if (inspection.inspectionNo.isEmpty) {
      inspection.inspectionNo = generateInspectionNumber();
    }

    // Add to state
    state = [...state, inspection];

    // Save to box
    await box.add(inspection);
  }

  Future<void> updateInspection(QualityInspection inspection) async {
    print('\n=== Debug: Updating Inspection ${inspection.inspectionNo} ===');

    // Find the index of the inspection to update
    final index = box.values.toList().indexWhere(
          (insp) => insp.inspectionNo == inspection.inspectionNo,
        );

    if (index != -1) {
      // Validate all required fields are filled
      bool allParametersFilled = inspection.items.every((item) {
        return item.parameters.every((param) {
          return param.observation.isNotEmpty && param.result != null;
        });
      });

      if (!allParametersFilled) {
        print('Warning: Not all parameters have observations filled');
      }

      // Update overall usage decision for each item
      for (var item in inspection.items) {
        print('\nProcessing item: ${item.materialCode}');

        // Get the selected GRN's quantities
        final selectedGRN = item.grnQuantities.entries
            .firstWhere((entry) => entry.value.isSelected == true);

        print('Selected GRN: ${selectedGRN.key}');
        print('Usage Decision: ${selectedGRN.value.usageDecision}');
        print('Received Qty: ${selectedGRN.value.receivedQty}');

        // Update quantities based on usage decision
        if (selectedGRN.value.usageDecision == 'Lot Accepted') {
          // If lot is accepted, set all received quantity as accepted
          selectedGRN.value.acceptedQty = selectedGRN.value.receivedQty;
          selectedGRN.value.rejectedQty = 0.0;
          item.acceptedQty = selectedGRN.value.receivedQty;
          item.rejectedQty = 0.0;
          item.usageDecision = 'Lot Accepted';
          inspection.status = 'Completed - Accepted';
        } else if (selectedGRN.value.usageDecision == 'Rejected') {
          // If lot is rejected, set all received quantity as rejected
          selectedGRN.value.acceptedQty = 0.0;
          selectedGRN.value.rejectedQty = selectedGRN.value.receivedQty;
          item.acceptedQty = 0.0;
          item.rejectedQty = selectedGRN.value.receivedQty;
          item.usageDecision = 'Rejected';
          inspection.status = 'Completed - Rejected';
        } else if (selectedGRN.value.usageDecision == 'Accepted After 100% Recheck') {
          // For 100% acceptance after recheck
          selectedGRN.value.acceptedQty = selectedGRN.value.receivedQty;
          selectedGRN.value.rejectedQty = 0.0;
          item.acceptedQty = selectedGRN.value.receivedQty;
          item.rejectedQty = 0.0;
          item.usageDecision = 'Accepted After 100% Recheck';
          inspection.status = 'Completed - Accepted After 100% Recheck';
        } else if (selectedGRN.value.usageDecision == 'Partially Accepted After 100% Recheck') {
          // For partial acceptance after recheck, use the quantities as set
          selectedGRN.value.acceptedQty = item.acceptedQty;
          selectedGRN.value.rejectedQty = item.rejectedQty;
          item.usageDecision = 'Partially Accepted After 100% Recheck';
          inspection.status = 'Completed - Partially Accepted After 100% Recheck';
        }

        item.receivedQty = selectedGRN.value.receivedQty;

        print('Updated quantities:');
        print('Accepted: ${item.acceptedQty}');
        print('Rejected: ${item.rejectedQty}');
        print('Received: ${item.receivedQty}');

        // Update pending quantity
        item.pendingQty =
            item.receivedQty - (item.acceptedQty + item.rejectedQty);
        print('Pending: ${item.pendingQty}');
      }

      print('Inspection status set to: ${inspection.status}');

      // Update the inspection in Hive
      await box.putAt(index, inspection);
      state = box.values.toList();

      // First update GRN status
      print('Updating GRN status...');
      try {
        await storeInward.updateGRNStatus(inspection.grnNo);
        // Then update stock
        await stockMaintenance.updateStockFromInspection(inspection);
      } catch (e) {
        print('Error updating GRN and stock: $e');
        rethrow;
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

  // Get inspections requiring CAPA
  List<QualityInspection> getInspectionsRequiringCAPA() {
    return state
        .where((inspection) =>
            inspection.capaStatus == 'Pending' ||
            inspection.capaStatus == 'In Progress')
        .toList();
  }

  // Update CAPA details
  Future<void> updateCapaDetails(
    String inspectionNo, {
    String? description,
    String? assignedTo,
    String? targetDate,
    String? completionDate,
    List<String>? actions,
  }) async {
    final index = box.values.toList().indexWhere(
          (insp) => insp.inspectionNo == inspectionNo,
        );

    if (index != -1) {
      final inspection = box.values.elementAt(index);

      if (description != null) inspection.capaDescription = description;
      if (assignedTo != null) inspection.capaAssignedTo = assignedTo;
      if (targetDate != null) inspection.capaTargetDate = targetDate;
      if (completionDate != null)
        inspection.capaCompletionDate = completionDate;
      if (actions != null) inspection.capaActions = actions;

      inspection.updateCapaStatus();

      await box.putAt(index, inspection);
      state = box.values.toList();
    }
  }

  // Update inspection status
  Future<void> updateInspectionStatus(String inspectionNo, String newStatus) async {
    print('\n=== Debug: Updating Inspection Status for $inspectionNo to $newStatus ===');
    
    // Find the index of the inspection to update
    final index = box.values.toList().indexWhere(
          (insp) => insp.inspectionNo == inspectionNo,
        );

    if (index != -1) {
      final inspection = box.getAt(index);
      if (inspection != null) {
        inspection.status = newStatus;
        
        // For recheck cases, update the usage decision of items too
        if (newStatus == 'Completed - Accepted After 100% Recheck') {
          for (var item in inspection.items) {
            for (var grnQty in item.grnQuantities.values) {
              if (grnQty.isSelected == true) {  // Explicitly check for true
                grnQty.usageDecision = 'Accepted After 100% Recheck';
                item.usageDecision = 'Accepted After 100% Recheck';
              }
            }
          }
        }
        
        await box.putAt(index, inspection);
        state = box.values.toList();
      }
    }
  }
}
