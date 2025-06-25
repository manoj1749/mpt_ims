// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/quality_inspection.dart';
import '../models/store_inward.dart';
import '../models/purchase_order.dart';
import '../models/quality.dart';
import '../models/category_parameter_mapping.dart';
import '../services/sync_service.dart';
import 'stock_maintenance_provider.dart';
import 'store_inward_provider.dart';


final qualityInspectionBoxProvider = Provider<Box<QualityInspection>>((ref) {
  throw UnimplementedError();
});

final qualityInspectionProvider =
    StateNotifierProvider<QualityInspectionNotifier, List<QualityInspection>>(
  (ref) {
    final box = ref.watch(qualityInspectionBoxProvider);
    final stockMaintenance = ref.watch(stockMaintenanceProvider.notifier);
    final storeInward = ref.watch(storeInwardProvider.notifier);
    final syncService = ref.watch(syncServiceProvider);
    return QualityInspectionNotifier(box, stockMaintenance, storeInward, syncService);
  },
);

class QualityInspectionNotifier extends StateNotifier<List<QualityInspection>> {
  final Box<QualityInspection> box;
  final StockMaintenanceNotifier stockMaintenance;
  final StoreInwardNotifier storeInward;
  final SyncService _syncService;

  QualityInspectionNotifier(this.box, this.stockMaintenance, this.storeInward, this._syncService)
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
    await _syncToFirebase();
  }

  Future<void> updateInspection(QualityInspection inspection) async {
    print(
        '\n=== Debug: Starting Inspection Update ${inspection.inspectionNo} ===');
    try {
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
          print('\n--- Processing item: ${item.materialCode} ---');
          try {
            // Get the selected GRN's quantities
            print(
                'GRN Quantities available: ${item.grnQuantities.keys.join(", ")}');
            print('Looking for selected GRN...');

            final selectedGRN = item.grnQuantities.entries.firstWhere(
                (entry) => entry.value.isSelected == true, orElse: () {
              print(
                  'No selected GRN found. Available GRNs and their selection status:');
              item.grnQuantities.forEach((key, value) {
                print('GRN: $key, Selected: ${value.isSelected}');
              });
              throw Exception('No selected GRN found for ${item.materialCode}');
            });

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
            } else if (selectedGRN.value.usageDecision == '100% Recheck') {
              // For items under recheck
              if (selectedGRN.value.recheckType == 'Partial Acceptance') {
                // For partial acceptance, use the quantities as set in the form
                // Keep the quantities that were set in the form
                selectedGRN.value.usageDecision =
                    'Partially Accepted After 100% Recheck';
                item.usageDecision = 'Partially Accepted After 100% Recheck';
                inspection.status =
                    'Completed - Partially Accepted After 100% Recheck';
              } else {
                // For 100% acceptance
                selectedGRN.value.acceptedQty = selectedGRN.value.receivedQty;
                selectedGRN.value.rejectedQty = 0.0;
                item.acceptedQty = selectedGRN.value.receivedQty;
                item.rejectedQty = 0.0;

                // Set proper usage decision based on CAPA requirement
                if (inspection.requiresCapa) {
                  selectedGRN.value.usageDecision =
                      'Lot Accepted - CAPA Required';
                  item.usageDecision = 'Lot Accepted - CAPA Required';
                  inspection.status = 'Completed - Accepted with CAPA';
                  inspection
                      .updateCapaStatus(); // Update CAPA status and generate number if needed
                } else {
                  selectedGRN.value.usageDecision =
                      'Accepted After 100% Recheck';
                  item.usageDecision = 'Accepted After 100% Recheck';
                  inspection.status = 'Completed - Accepted After 100% Recheck';
                }
              }
            } else if (selectedGRN.value.usageDecision ==
                    'Accepted After 100% Recheck' ||
                selectedGRN.value.usageDecision ==
                    'Lot Accepted - CAPA Required') {
              // For 100% acceptance after recheck (with or without CAPA)
              selectedGRN.value.acceptedQty = selectedGRN.value.receivedQty;
              selectedGRN.value.rejectedQty = 0.0;
              item.acceptedQty = selectedGRN.value.receivedQty;
              item.rejectedQty = 0.0;

              // Keep the same usage decision and status
              item.usageDecision = selectedGRN.value.usageDecision;
              if (selectedGRN.value.usageDecision ==
                  'Lot Accepted - CAPA Required') {
                inspection.status = 'Completed - Accepted with CAPA';
                inspection
                    .updateCapaStatus(); // Update CAPA status and generate number if needed
              } else {
                inspection.status = 'Completed - Accepted After 100% Recheck';
              }
            } else if (selectedGRN.value.usageDecision ==
                'Partially Accepted After 100% Recheck') {
              // For partial acceptance after recheck, use the quantities as set
              // The quantities should already be set in the form, just update the status
              selectedGRN.value.usageDecision =
                  'Partially Accepted After 100% Recheck';
              item.usageDecision = 'Partially Accepted After 100% Recheck';
              inspection.status =
                  'Completed - Partially Accepted After 100% Recheck';
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
          } catch (e) {
            print('Error processing item: $e');
            rethrow;
          }
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
          await _syncToFirebase();
        } catch (e) {
          print('Error updating GRN and stock: $e');
          rethrow;
        }
      }
    } catch (e) {
      print('Error updating inspection: $e');
      rethrow;
    }
  }

  Future<void> deleteInspection(QualityInspection inspection) async {
    // Find the index of the inspection to delete
    final index = box.values.toList().indexWhere(
          (insp) => insp.inspectionNo == inspection.inspectionNo,
        );

    if (index != -1) {
      await box.deleteAt(index);
      state = box.values.toList();
      await _syncToFirebase();
    }
  }

  Future<void> refresh() async {
    try {
      await _syncFromFirebase();
      state = box.values.toList();
    } catch (e) {
      print('Error refreshing quality inspections: $e');
      rethrow;
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      await _syncService.syncToFirestore('quality_inspections', box);
    } catch (e) {
      print('Error syncing quality inspections to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      await _syncService.syncFromFirestore(
        'quality_inspections',
        box,
        _syncService.qualityInspectionFromMap,
      );
    } catch (e) {
      print('Error syncing quality inspections from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
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
      if (completionDate != null) {
        inspection.capaCompletionDate = completionDate;
      }
      if (actions != null) inspection.capaActions = actions;

      inspection.updateCapaStatus();

      await box.putAt(index, inspection);
      state = box.values.toList();
    }
  }

  // Update inspection status
  Future<void> updateInspectionStatus(
      String inspectionNo, String newStatus) async {
    print(
        '\n=== Debug: Updating Inspection Status for $inspectionNo to $newStatus ===');

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
              if (grnQty.isSelected == true) {
                // Explicitly check for true
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
