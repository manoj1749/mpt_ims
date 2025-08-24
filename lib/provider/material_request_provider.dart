// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/material_request.dart';
import '../models/material_request_item.dart';
import 'base_provider.dart';

final materialRequestBoxProvider = Provider<Box<MaterialRequest>>((ref) {
  return Hive.box<MaterialRequest>('material_requests');
});

final materialRequestListProvider = Provider<List<MaterialRequest>>((ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return box.values.toList();
});

// StateNotifier provider for backward compatibility
final materialRequestProvider =
    StateNotifierProvider<MaterialRequestProvider, List<MaterialRequest>>(
        (ref) {
  final box = ref.watch(materialRequestBoxProvider);
  return MaterialRequestProvider(box);
});

class MaterialRequestProvider extends BaseProvider<MaterialRequest> {
  MaterialRequestProvider(Box<MaterialRequest> box)
      : super(box, 'material_requests');

  @override
  Map<String, dynamic> modelToMap(MaterialRequest request) {
    return {
      'issueNo': request.issueNo,
      'date': request.date,
      'issuedBy': request.issuedBy,
      'status': request.status,
      'jobNo': request.jobNo,
      'items': request.items
          .map((item) => {
                'materialCode': item.materialCode,
                'materialDescription': item.materialDescription,
                'unit': item.unit,
                'quantity': item.quantity,
                'issueNo': item.issueNo,
                'issuedQuantities': item.issuedQuantities,
              })
          .toList(),
    };
  }

  @override
  MaterialRequest mapToModel(Map<String, dynamic> map) {
    return MaterialRequest(
      issueNo: map['issueNo'] ?? '',
      date: map['date'] ?? '',
      issuedBy: map['issuedBy'] ?? '',
      status: map['status'] ?? 'Draft',
      jobNo: map['jobNo'],
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => MaterialRequestItem(
                    materialCode: item['materialCode'] ?? '',
                    materialDescription: item['materialDescription'] ?? '',
                    unit: item['unit'] ?? '',
                    quantity: item['quantity'] ?? '',
                    issueNo: item['issueNo'] ?? '',
                    issuedQuantities: Map<String, double>.from(
                        item['issuedQuantities'] ?? {}),
                  ))
              .toList() ??
          [],
    );
  }

  @override
  String getModelId(MaterialRequest request) => request.issueNo;

  // Backward compatibility methods
  Future<void> loadMaterialRequests() => loadData();
  Future<void> addRequest(MaterialRequest request) => add(request);
  Future<void> addMaterialRequest(MaterialRequest request) => add(request);
  Future<void> updateRequest(MaterialRequest request) => update(request);
  Future<void> updateMaterialRequest(MaterialRequest request) =>
      update(request);
  Future<bool> deleteRequest(MaterialRequest request) => delete(request);
  Future<bool> deleteMaterialRequest(String issueNo) async {
    final request = getRequestByIssueNo(issueNo);
    if (request != null) {
      return await delete(request);
    }
    return false;
  }

  // Getter for backward compatibility
  List<MaterialRequest> get requests => state;

  // Search and filter methods
  List<MaterialRequest> searchRequests(String query) {
    return search(
        query,
        (request, query) =>
            request.issueNo.toLowerCase().contains(query) ||
            request.issuedBy.toLowerCase().contains(query) ||
            (request.jobNo?.toLowerCase().contains(query) ?? false));
  }

  List<MaterialRequest> getRequestsByStatus(String status) {
    return state.where((request) => request.status == status).toList();
  }

  List<MaterialRequest> getRequestsByJobNo(String jobNo) {
    return state.where((request) => request.jobNo == jobNo).toList();
  }

  List<MaterialRequest> getRequestsByDateRange(
      DateTime startDate, DateTime endDate) {
    return state.where((request) {
      try {
        final requestDate = DateTime.parse(request.date);
        return requestDate
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            requestDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  MaterialRequest? getRequestByIssueNo(String issueNo) {
    try {
      return state.firstWhere((request) => request.issueNo == issueNo);
    } catch (e) {
      return null;
    }
  }

  // Request number generation
  String generateIssueNo() => generateRequestNumber();

  String generateRequestNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');

    // Find existing requests for current month
    final existingRequests = state.where((request) {
      return request.issueNo.startsWith('MR$year$month');
    }).toList();

    final nextNumber = existingRequests.length + 1;
    return 'MR$year$month${nextNumber.toString().padLeft(3, '0')}';
  }

  // Status management
  List<MaterialRequest> getPendingRequests() {
    return state
        .where((request) =>
            request.status == 'Active' || request.status == 'Draft')
        .toList();
  }

  List<MaterialRequest> getCompletedRequests() {
    return state.where((request) => request.status == 'Completed').toList();
  }

  // Analytics methods
  Map<String, double> getMaterialDemandStats() {
    final demand = <String, double>{};

    for (var request in state) {
      for (var item in request.items) {
        final quantity = double.tryParse(item.quantity) ?? 0.0;
        demand[item.materialCode] =
            (demand[item.materialCode] ?? 0.0) + quantity;
      }
    }

    return demand;
  }

  Map<String, int> getJobWiseRequestCount() {
    final jobCount = <String, int>{};

    for (var request in state) {
      if (request.jobNo != null) {
        jobCount[request.jobNo!] = (jobCount[request.jobNo!] ?? 0) + 1;
      }
    }

    return jobCount;
  }

  Map<String, double> getPendingQuantitiesByMaterial() {
    final pending = <String, double>{};

    for (var request in state) {
      if (request.status != 'Completed') {
        for (var item in request.items) {
          pending[item.materialCode] =
              (pending[item.materialCode] ?? 0.0) + item.pendingQuantity;
        }
      }
    }

    return pending;
  }

  // Validation methods
  bool canDeleteRequest(MaterialRequest request) {
    // Can't delete if any items have been partially or fully issued
    return request.items.every((item) => item.totalIssuedQuantity == 0);
  }

  List<String> validateRequest(MaterialRequest request) {
    final errors = <String>[];

    // Check if request number already exists
    if (state
        .any((existingRequest) => existingRequest.issueNo == request.issueNo)) {
      errors.add('Request number ${request.issueNo} already exists');
    }

    // Check if all items have valid quantities
    for (var item in request.items) {
      final quantity = double.tryParse(item.quantity);
      if (quantity == null || quantity <= 0) {
        errors.add('Invalid quantity for ${item.materialDescription}');
      }
    }

    return errors;
  }

  // Issue tracking
  void updateIssuedQuantity(String requestIssueNo, String materialCode,
      String materialIssueNo, double quantity) {
    final request = getRequestByIssueNo(requestIssueNo);
    if (request != null) {
      final item = request.items
          .where((item) => item.materialCode == materialCode)
          .firstOrNull;
      if (item != null) {
        item.addIssuedQuantity(materialIssueNo, quantity);

        // Update request status if all items are fully issued
        final allItemsIssued =
            request.items.every((item) => item.pendingQuantity <= 0);
        if (allItemsIssued) {
          request.status = 'Completed';
        } else if (request.items.any((item) => item.totalIssuedQuantity > 0)) {
          request.status = 'Active';
        }

        // Save the updated request
        update(request);
      }
    }
  }
}
