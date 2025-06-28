// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  QualityInspectionNotifier(this.box, this.stockMaintenance, this.storeInward, this._syncService)
      : super([]) {
    // Load inspections when initialized
    loadInspections();
  }

  Future<void> loadInspections() async {
    try {
      print('Loading quality inspection data from Firestore...');
      final querySnapshot = await _firestore.collection('qualityInspections').get();
      print('Found ${querySnapshot.docs.length} inspections in Firestore');

      // Clear existing inspections from Hive
      await box.clear();

      // Add new inspections to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final inspection = _syncService.qualityInspectionFromMap(data);
        await box.add(inspection);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded quality inspection data');
    } catch (e) {
      print('Error loading quality inspection data: $e');
      rethrow;
    }
  }

  String generateInspectionNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final yearInspections = state
        .where((inspection) => inspection.inspectionNo.startsWith('QI$year'))
        .toList();

    int maxSeq = 0;
    for (var inspection in yearInspections) {
      try {
        final seq = int.parse(inspection.inspectionNo.substring(8));
        if (seq > maxSeq) maxSeq = seq;
      } catch (e) {
        print('Error parsing sequence number: $e');
      }
    }

    final seq = (maxSeq + 1).toString().padLeft(4, '0');
    return 'QI$year$month$day$seq';
  }

  Future<void> addInspection(QualityInspection inspection) async {
    try {
      // Generate inspection number if not provided
      if (inspection.inspectionNo.isEmpty) {
        inspection.inspectionNo = generateInspectionNumber();
      }

      // Add to Firestore first
      final docRef = _firestore.collection('qualityInspections').doc(inspection.inspectionNo);
      final data = _convertToMap(inspection);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(inspection);

      // Update state
      if (mounted) {
        state = [...state, inspection];
      }
      print('Successfully added inspection ${inspection.inspectionNo}');
    } catch (e) {
      print('Error adding inspection: $e');
      rethrow;
    }
  }

  Future<void> updateInspection(QualityInspection inspection) async {
    print('\n=== Debug: Starting Inspection Update ${inspection.inspectionNo} ===');
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

        // Update inspection status and quantities
        for (var item in inspection.items) {
          print('\n--- Processing item: ${item.materialCode} ---');
          try {
            // Process inspection item (existing logic)
            // ... (keep your existing business logic for processing items)

            // After processing each item, update both Firestore and Hive
            final docRef = _firestore.collection('qualityInspections').doc(inspection.inspectionNo);
            final data = _convertToMap(inspection);
            data['lastUpdated'] = FieldValue.serverTimestamp();
            data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
            await docRef.update(data);

            // Update in Hive
            await box.putAt(index, inspection);

            // Update stock maintenance
            await stockMaintenance.updateStockFromInspection(inspection);

            // Update store inward
            await storeInward.updateFromInspection(inspection);
          } catch (e) {
            print('Error processing item ${item.materialCode}: $e');
            rethrow;
          }
        }

        // Update state
        if (mounted) {
          state = box.values.toList();
        }
      } else {
        throw Exception('Inspection not found: ${inspection.inspectionNo}');
      }
    } catch (e) {
      print('Error updating inspection: $e');
      rethrow;
    }
  }

  // Helper method to convert QualityInspection to Map
  Map<String, dynamic> _convertToMap(QualityInspection inspection) {
    return {
      'inspectionNo': inspection.inspectionNo,
      'inspectionDate': inspection.inspectionDate,
      'status': inspection.status,
      'requiresCapa': inspection.requiresCapa,
      'capaNo': inspection.capaNo,
      'capaStatus': inspection.capaStatus,
      'items': inspection.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'acceptedQty': item.acceptedQty,
        'rejectedQty': item.rejectedQty,
        'usageDecision': item.usageDecision,
        'parameters': item.parameters.map((param) => {
          'parameter': param.parameter,
          'isAcceptable': param.isAcceptable,
          'observation': param.observation,
          'result': param.result,
        }).toList(),
        'grnQuantities': item.grnQuantities.map((key, value) => MapEntry(key, {
          'receivedQty': value.receivedQty,
          'acceptedQty': value.acceptedQty,
          'rejectedQty': value.rejectedQty,
          'isSelected': value.isSelected,
          'usageDecision': value.usageDecision,
          'recheckType': value.recheckType,
          'poNo': value.poNo,
          'poDate': value.poDate,
        })),
      }).toList(),
    };
  }

  Future<void> deleteInspection(QualityInspection inspection) async {
    try {
      // Find the index of the inspection to delete
      final index = box.values.toList().indexWhere(
            (insp) => insp.inspectionNo == inspection.inspectionNo,
          );

      if (index != -1) {
        // Delete from Firestore first
        final docRef = _firestore.collection('qualityInspections').doc(inspection.inspectionNo);
        await docRef.delete();

        // Then delete from Hive
        await box.deleteAt(index);

        // Update state
        state = box.values.toList();
      }
    } catch (e) {
      print('Error deleting inspection: $e');
      rethrow;
    }
  }

  Future<void> updateInspectionStatus(
      String inspectionNo, String newStatus) async {
    print(
        '\n=== Debug: Updating Inspection Status for $inspectionNo to $newStatus ===');

    try {
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

          // Update in Firestore first
          final docRef = _firestore.collection('qualityInspections').doc(inspectionNo);
          final data = _convertToMap(inspection);
          data['lastUpdated'] = FieldValue.serverTimestamp();
          data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
          await docRef.update(data);

          // Then update in Hive
          await box.putAt(index, inspection);

          // Update state
          state = box.values.toList();
        }
      }
    } catch (e) {
      print('Error updating inspection status: $e');
      rethrow;
    }
  }

  Future<void> updateCapaDetails(
    String inspectionNo, {
    String? description,
    String? assignedTo,
    String? targetDate,
    String? completionDate,
    List<String>? actions,
  }) async {
    try {
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

        // Update in Firestore first
        final docRef = _firestore.collection('qualityInspections').doc(inspectionNo);
        final data = _convertToMap(inspection);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);

        // Then update in Hive
        await box.putAt(index, inspection);

        // Update state
        state = box.values.toList();
      }
    } catch (e) {
      print('Error updating CAPA details: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      await loadInspections();
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
}
