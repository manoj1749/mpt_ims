// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/quality_inspection.dart';
import '../models/store_inward.dart';
import '../models/purchase_order.dart';
import '../models/quality.dart';
import '../models/category_parameter_mapping.dart';
import 'base_provider.dart';
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
    return QualityInspectionNotifier(box, stockMaintenance, storeInward);
  },
);

class QualityInspectionNotifier extends BaseProvider<QualityInspection> {
  final StockMaintenanceNotifier stockMaintenance;
  final StoreInwardNotifier storeInward;

  QualityInspectionNotifier(Box<QualityInspection> box, this.stockMaintenance, this.storeInward)
      : super(box, 'qualityInspections');

  @override
  Map<String, dynamic> modelToMap(QualityInspection inspection) {
    return {
      'inspectionNo': inspection.inspectionNo,
      'inspectionDate': inspection.inspectionDate,
      'grnNo': inspection.grnNo,
      'supplierName': inspection.supplierName,
      'poNo': inspection.poNo,
      'billNo': inspection.billNo,
      'billDate': inspection.billDate,
      'receivedDate': inspection.receivedDate,
      'grnDate': inspection.grnDate,
      'inspectedBy': inspection.inspectedBy,
      'approvedBy': inspection.approvedBy,
      'status': inspection.status,
      'prNumbers': inspection.prNumbers,
      'jobNumbers': inspection.jobNumbers,
      'capaNo': inspection.capaNo,
      'capaStatus': inspection.capaStatus,
      'capaDescription': inspection.capaDescription,
      'capaAssignedTo': inspection.capaAssignedTo,
      'capaTargetDate': inspection.capaTargetDate,
      'capaCompletionDate': inspection.capaCompletionDate,
      'capaActions': inspection.capaActions,
      'items': inspection.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'category': item.category,
        'receivedQty': item.receivedQty,
        'costPerUnit': item.costPerUnit,
        'totalCost': item.totalCost,
        'sampleSize': item.sampleSize,
        'inspectedQty': item.inspectedQty,
        'acceptedQty': item.acceptedQty,
        'rejectedQty': item.rejectedQty,
        'pendingQty': item.pendingQty,
        'usageDecision': item.usageDecision,
        'receivedDate': item.receivedDate,
        'expirationDate': item.expirationDate,
        'capaRequired': item.capaRequired,
        'inspectionRemark': item.inspectionRemark,
        'parameters': item.parameters.map((param) => {
          'parameter': param.parameter,
          'isAcceptable': param.isAcceptable,
          'observation': param.observation,
          'result': param.result,
        }).toList(),
      }).toList(),
    };
  }

  @override
  QualityInspection mapToModel(Map<String, dynamic> map) {
    return QualityInspection(
      inspectionNo: map['inspectionNo'] ?? '',
      inspectionDate: map['inspectionDate'] ?? '',
      grnNo: map['grnNo'] ?? '',
      supplierName: map['supplierName'] ?? '',
      poNo: map['poNo'] ?? '',
      billNo: map['billNo'] ?? '',
      billDate: map['billDate'] ?? '',
      receivedDate: map['receivedDate'] ?? '',
      grnDate: map['grnDate'] ?? '',
      inspectedBy: map['inspectedBy'] ?? '',
      approvedBy: map['approvedBy'] ?? '',
      status: map['status'] ?? 'Pending',
      prNumbers: Map<String, String>.from(map['prNumbers'] ?? {}),
      jobNumbers: Map<String, String>.from(map['jobNumbers'] ?? {}),
      capaNo: map['capaNo'],
      capaStatus: map['capaStatus'] ?? 'Not Required',
      capaDescription: map['capaDescription'],
      capaAssignedTo: map['capaAssignedTo'],
      capaTargetDate: map['capaTargetDate'],
      capaCompletionDate: map['capaCompletionDate'],
      capaActions: List<String>.from(map['capaActions'] ?? []),
      items: (map['items'] as List<dynamic>?)?.map((item) => InspectionItem(
        materialCode: item['materialCode'] ?? '',
        materialDescription: item['materialDescription'] ?? '',
        unit: item['unit'] ?? '',
        category: item['category'] ?? '',
        receivedQty: (item['receivedQty'] as num?)?.toDouble() ?? 0.0,
        costPerUnit: (item['costPerUnit'] as num?)?.toDouble() ?? 0.0,
        totalCost: (item['totalCost'] as num?)?.toDouble() ?? 0.0,
        sampleSize: (item['sampleSize'] as num?)?.toDouble() ?? 0.0,
        inspectedQty: (item['inspectedQty'] as num?)?.toDouble() ?? 0.0,
        acceptedQty: (item['acceptedQty'] as num?)?.toDouble() ?? 0.0,
        rejectedQty: (item['rejectedQty'] as num?)?.toDouble() ?? 0.0,
        pendingQty: (item['pendingQty'] as num?)?.toDouble() ?? 0.0,
        usageDecision: item['usageDecision'] ?? 'Lot Accepted',
        receivedDate: item['receivedDate'] ?? '',
        expirationDate: item['expirationDate'] ?? '',
        capaRequired: item['capaRequired'] ?? false,
        inspectionRemark: item['inspectionRemark'],
        parameters: (item['parameters'] as List<dynamic>?)?.map((param) => QualityParameter(
          parameter: param['parameter'] ?? '',
          isAcceptable: param['isAcceptable'] ?? true,
          observation: param['observation'] ?? '',
          result: param['result'] ?? 'OK',
        )).toList() ?? [],
      )).toList() ?? [],
    );
  }

  @override
  String getModelId(QualityInspection inspection) => inspection.inspectionNo;

  // Backward compatibility methods
  Future<void> loadInspections() => loadData();
  Future<void> addInspection(QualityInspection inspection) => add(inspection);
  Future<void> updateInspection(QualityInspection inspection) => update(inspection);
  Future<bool> deleteInspection(QualityInspection inspection) => delete(inspection);

  // Search and filter methods
  List<QualityInspection> searchInspections(String query) {
    return search(query, (inspection, query) =>
        inspection.inspectionNo.toLowerCase().contains(query) ||
        inspection.supplierName.toLowerCase().contains(query) ||
        inspection.poNo.toLowerCase().contains(query) ||
        inspection.grnNo.toLowerCase().contains(query));
  }

  List<QualityInspection> getInspectionsByStatus(String status) {
    return state.where((inspection) => inspection.status == status).toList();
  }

  List<QualityInspection> getInspectionsBySupplier(String supplierName) {
    return state.where((inspection) => 
        inspection.supplierName.toLowerCase() == supplierName.toLowerCase()).toList();
  }

  List<QualityInspection> getInspectionsByDateRange(DateTime startDate, DateTime endDate) {
    return state.where((inspection) {
      try {
        final inspectionDate = DateFormat('dd/MM/yyyy').parse(inspection.inspectionDate);
        return inspectionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               inspectionDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  QualityInspection? getInspectionByNo(String inspectionNo) {
    try {
      return state.firstWhere((inspection) => inspection.inspectionNo == inspectionNo);
    } catch (e) {
      return null;
    }
  }

  // Inspection number generation
  String generateInspectionNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    
    // Find existing inspections for current month
    final existingInspections = state.where((inspection) {
      return inspection.inspectionNo.startsWith('QI$year$month');
    }).toList();
    
    final nextNumber = existingInspections.length + 1;
    return 'QI$year$month${nextNumber.toString().padLeft(3, '0')}';
  }

  // Status management
  List<QualityInspection> getPendingInspections() {
    return state.where((inspection) => inspection.status == 'Pending').toList();
  }

  List<QualityInspection> getApprovedInspections() {
    return state.where((inspection) => inspection.status == 'Approved').toList();
  }

  List<QualityInspection> getRejectedInspections() {
    return state.where((inspection) => inspection.status == 'Rejected').toList();
  }

  // CAPA management
  List<QualityInspection> getInspectionsRequiringCapa() {
    return state.where((inspection) => inspection.requiresCapa).toList();
  }

  List<QualityInspection> getCapaByStatus(String capaStatus) {
    return state.where((inspection) => inspection.capaStatus == capaStatus).toList();
  }

  // Analytics methods
  Map<String, int> getInspectionStatusStats() {
    final stats = <String, int>{};
    for (var inspection in state) {
      stats[inspection.status] = (stats[inspection.status] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getSupplierRejectionStats() {
    final stats = <String, int>{};
    for (var inspection in state) {
      if (inspection.status == 'Rejected') {
        stats[inspection.supplierName] = (stats[inspection.supplierName] ?? 0) + 1;
      }
    }
    return stats;
  }

  Map<String, double> getMaterialRejectionRates() {
    final totalInspections = <String, int>{};
    final rejectedInspections = <String, int>{};
    
    for (var inspection in state) {
      for (var item in inspection.items) {
        totalInspections[item.materialCode] = (totalInspections[item.materialCode] ?? 0) + 1;
        if (item.usageDecision == 'Rejected') {
          rejectedInspections[item.materialCode] = (rejectedInspections[item.materialCode] ?? 0) + 1;
        }
      }
    }
    
    final rejectionRates = <String, double>{};
    for (var materialCode in totalInspections.keys) {
      final total = totalInspections[materialCode]!;
      final rejected = rejectedInspections[materialCode] ?? 0;
      rejectionRates[materialCode] = (rejected / total) * 100;
    }
    
    return rejectionRates;
  }

  // Validation methods
  List<String> validateInspection(QualityInspection inspection) {
    final errors = <String>[];
    
    // Check if inspection number already exists
    if (state.any((existingInspection) => existingInspection.inspectionNo == inspection.inspectionNo)) {
      errors.add('Inspection number ${inspection.inspectionNo} already exists');
    }
    
    // Check if all items have valid quantities
    for (var item in inspection.items) {
      if (item.receivedQty <= 0) {
        errors.add('Invalid received quantity for ${item.materialDescription}');
      }
      if (item.acceptedQty + item.rejectedQty > item.receivedQty) {
        errors.add('Total inspected quantity exceeds received quantity for ${item.materialDescription}');
      }
    }
    
    return errors;
  }

  // Stock integration methods
  Future<void> updateStockAfterInspection(QualityInspection inspection) async {
    // This would integrate with stock maintenance
    // Implementation depends on the actual stock management requirements
    print('Updating stock after inspection: ${inspection.inspectionNo}');
  }

  // Update inspection status method for backward compatibility
  Future<void> updateInspectionStatus(String inspectionNo, String newStatus) async {
    final inspection = getInspectionByNo(inspectionNo);
    if (inspection != null) {
      inspection.status = newStatus;
      await update(inspection);
    }
  }

  Future<void> processInspectionApproval(String inspectionNo) async {
    final inspection = getInspectionByNo(inspectionNo);
    if (inspection != null) {
      final updatedInspection = inspection.copyWith(status: 'Approved');
      await update(updatedInspection);
      await updateStockAfterInspection(updatedInspection);
    }
  }

  Future<void> processInspectionRejection(String inspectionNo, String reason) async {
    final inspection = getInspectionByNo(inspectionNo);
    if (inspection != null) {
      final updatedInspection = inspection.copyWith(
        status: 'Rejected',
        capaStatus: inspection.requiresCapa ? 'Pending' : 'Not Required',
      );
      await update(updatedInspection);
    }
  }
}
