// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/store_inward.dart';
import '../models/material_item.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';
import '../models/quality_inspection.dart';
import '../provider/base_provider.dart';
import '../provider/stock_maintenance_provider.dart';
import '../provider/customer_scope_stock_maintenance_provider.dart';
import '../provider/purchase_order.dart';
import '../provider/quality_inspection_provider.dart';

final storeInwardBoxProvider = Provider<Box<StoreInward>>((ref) {
  throw UnimplementedError();
});

final storeInwardProvider =
    StateNotifierProvider<StoreInwardNotifier, List<StoreInward>>((ref) {
  final box = ref.watch(storeInwardBoxProvider);
  return StoreInwardNotifier(box, ref);
});

final storeInwardMaterialBoxProvider = Provider<Box<MaterialItem>>((ref) {
  return Hive.box<MaterialItem>('materials');
});

class StoreInwardNotifier extends BaseProvider<StoreInward> {
  final Ref _ref;
  int _lastGRNNumber = 0;

  StoreInwardNotifier(Box<StoreInward> box, this._ref)
      : super(box, 'storeInwards') {
    _initializeLastGRNNumber();
  }

  @override
  Map<String, dynamic> modelToMap(StoreInward inward) {
    return {
      'grnNo': inward.grnNo,
      'grnDate': inward.grnDate,
      'supplierName': inward.supplierName,
      'poNo': inward.poNo,
      'poDate': inward.poDate,
      'invoiceNo': inward.invoiceNo,
      'invoiceDate': inward.invoiceDate,
      'invoiceAmount': inward.invoiceAmount,
      'receivedBy': inward.receivedBy,
      'checkedBy': inward.checkedBy,
      'status': inward.status,
      'isCustomerScope': inward.isCustomerScope,
      'customerId': inward.customerId,
      'customerName': inward.customerName,
      'items': inward.items
          .map((item) => {
                'materialCode': item.materialCode,
                'materialDescription': item.materialDescription,
                'unit': item.unit,
                'orderedQty': item.orderedQty,
                'receivedQty': item.receivedQty,
                'acceptedQty': item.acceptedQty,
                'rejectedQty': item.rejectedQty,
                'costPerUnit': item.costPerUnit,
                'prQuantities': item.prQuantities,
                'inspectionStatus':
                    item.inspectionStatus.map((key, value) => MapEntry(key, {
                          'inspectedQty': value.inspectedQty,
                          'acceptedQty': value.acceptedQty,
                          'rejectedQty': value.rejectedQty,
                          'status': value.status,
                        })),
                'prJobNumbers': item.prJobNumbers,
              })
          .toList(),
    };
  }

  @override
  StoreInward mapToModel(Map<String, dynamic> data) {
    return StoreInward(
      grnNo: data['grnNo'] ?? '',
      grnDate: data['grnDate'] ?? '',
      supplierName: data['supplierName'] ?? '',
      poNo: data['poNo'] ?? '',
      poDate: data['poDate'] ?? '',
      invoiceNo: data['invoiceNo'] ?? '',
      invoiceDate: data['invoiceDate'] ?? '',
      invoiceAmount: (data['invoiceAmount'] as num?)?.toDouble() ?? 0.0,
      receivedBy: data['receivedBy'] ?? '',
      checkedBy: data['checkedBy'] ?? '',
      isCustomerScope: data['isCustomerScope'] ?? false,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => InwardItem(
                    materialCode: item['materialCode'] ?? '',
                    materialDescription: item['materialDescription'] ?? '',
                    unit: item['unit'] ?? '',
                    orderedQty: (item['orderedQty'] as num?)?.toDouble() ?? 0.0,
                    receivedQty:
                        (item['receivedQty'] as num?)?.toDouble() ?? 0.0,
                    acceptedQty:
                        (item['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                    rejectedQty:
                        (item['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                    costPerUnit: item['costPerUnit'] ?? '0',
                    prQuantities: (item['prQuantities']
                                as Map<String, dynamic>?)
                            ?.map((key, value) => MapEntry(
                                key,
                                (value as Map<String, dynamic>).map((k, v) =>
                                    MapEntry(k, (v as num).toDouble())))) ??
                        {},
                    inspectionStatus: (item['inspectionStatus']
                                as Map<String, dynamic>?)
                            ?.map((key, value) => MapEntry(
                                key,
                                InspectionQuantityStatus(
                                  inspectedQty: (value['inspectedQty'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  acceptedQty: (value['acceptedQty'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  rejectedQty: (value['rejectedQty'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  status: value['status'] ?? 'Pending',
                                ))) ??
                        {},
                    prJobNumbers: (item['prJobNumbers']
                                as Map<String, dynamic>?)
                            ?.map((key, value) => MapEntry(
                                key,
                                (value as Map<String, dynamic>).map(
                                    (k, v) => MapEntry(k, v.toString())))) ??
                        {},
                  ))
              .toList() ??
          [],
    );
  }

  @override
  String getModelId(StoreInward inward) => inward.grnNo;

  // Backward compatibility methods
  Future<void> loadInwards() => loadData();
  Future<void> addInward(StoreInward inward) => add(inward);
  Future<void> updateInward(int index, StoreInward inward) => update(inward);
  Future<void> deleteInward(StoreInward inward) => delete(inward);

  void _initializeLastGRNNumber() {
    if (box.isEmpty) {
      _lastGRNNumber = 0;
      return;
    }

    // Find the highest GRN number
    _lastGRNNumber = box.values.fold(0, (maxNum, inward) {
      final grnNum =
          int.tryParse(inward.grnNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return grnNum > maxNum ? grnNum : maxNum;
    });
  }

  String generateGRNNumber() {
    // Get current financial year (April to March)
    final now = DateTime.now();
    int financialYear = now.year;
    if (now.month < 4) {
      financialYear--; // If before April, use previous financial year
    }
    final nextFinancialYear = financialYear + 1;

    // Get last 2 digits of current and next financial year
    final currentYearStr = financialYear.toString().substring(2);
    final nextYearStr = nextFinancialYear.toString().substring(2);
    final yearPrefix = '$currentYearStr$nextYearStr';

    // Find all VALID sequential GRN numbers for the current financial year
    final validSequentialGRNs = state.where((inward) {
      // Check if GRN number matches the expected format: GR + YYYY + 6 digits
      if (!inward.grnNo.startsWith('GR$yearPrefix') || inward.grnNo.length != 12) {
        return false;
      }

      // Check if the last 6 characters are all digits
      final sequencePart = inward.grnNo.substring(6);
      return RegExp(r'^\d{6}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential GRNs exist for this financial year, start from 1
    if (validSequentialGRNs.isEmpty) {
      return 'GR${yearPrefix}000001';
    }

    // Extract and parse sequence numbers from valid GRNs only
    final sequenceNumbers = validSequentialGRNs.map((inward) {
      return int.parse(inward.grnNo.substring(6));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 6-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(6, '0');

    return 'GR$yearPrefix$sequenceStr'; // e.g., GR25260001, GR25260002, etc.
  }

  @override
  Future<void> add(StoreInward inward) async {
    print('\nAdding new inward: ${inward.grnNo}');

    // Get all POs
    final poList = _ref.read(purchaseOrderListProvider);

    // Process each item
    for (var item in inward.items) {
      print('\nProcessing item: ${item.materialCode}');

      // For each PO in the item
      for (var poNo in item.prQuantities.keys.toList()) {
        print('\nChecking PO: $poNo');
        final prQuantities = item.prQuantities[poNo];

        // Only auto-distribute if no PR quantities are manually set
        if (prQuantities == null || prQuantities.isEmpty) {
          print('No PR quantities found for PO, checking PR details');

          // Find the PO
          final po = poList.firstWhere(
            (p) => p.poNo == poNo,
            orElse: () => PurchaseOrder(
              poNo: poNo,
              poDate: '',
              supplierName: '',
              transport: '',
              deliveryRequirements: '',
              items: [],
              total: 0.0,
              igst: 0.0,
              cgst: 0.0,
              sgst: 0.0,
              grandTotal: 0.0,
            ),
          );

          // Find the corresponding PO item
          final poItem = po.items.firstWhere(
            (i) => i.materialCode == item.materialCode,
            orElse: () => POItem(
              materialCode: item.materialCode,
              materialDescription: item.materialDescription,
              unit: item.unit,
              quantity: '0',
              costPerUnit: '0',
              totalCost: '0',
              saleRate: '0',
              marginPerUnit: '0',
              totalMargin: '0',
            ),
          );

          if (poItem.prDetails.isNotEmpty) {
            print('Found PR details in PO:');
            // Calculate total PR quantity
            double totalPRQty = poItem.prDetails.values
                .fold(0.0, (sum, detail) => sum + detail.quantity);

            // Distribute received quantity proportionally
            for (var prDetail in poItem.prDetails.entries) {
              final prNo = prDetail.key;
              final jobNo = prDetail.value.jobNo;
              final prQty = prDetail.value.quantity;

              // Calculate proportional quantity
              double proportion = prQty / totalPRQty;
              double allocatedQty = item.receivedQty * proportion;

              if (!item.prQuantities.containsKey(poNo)) {
                item.prQuantities[poNo] = {};
              }
              item.prQuantities[poNo]![prNo] = allocatedQty;

              if (!item.prJobNumbers.containsKey(poNo)) {
                item.prJobNumbers[poNo] = {};
              }
              item.prJobNumbers[poNo]![prNo] = jobNo;
            }
          } else {
            // If no PR details found, assign to General PR
            print('No PR details found in PO, assigning to General PR');
            if (!item.prQuantities.containsKey(poNo)) {
              item.prQuantities[poNo] = {};
            }
            item.prQuantities[poNo]!['General'] = item.receivedQty;

            if (!item.prJobNumbers.containsKey(poNo)) {
              item.prJobNumbers[poNo] = {};
            }
            item.prJobNumbers[poNo]!['General'] = 'General';
          }
        }
      }
    }

    // Call parent add method which handles Hive and Firestore
    await super.add(inward);

    // Mark PO as having GR
    await _markPOAsHavingGR(inward);

    // Update stock maintenance based on type
    if (inward.isCustomerScope) {
      // Update customer scope stock maintenance
      await _ref
          .read(customerScopeStockMaintenanceProvider.notifier)
          .updateStockFromGRN(inward, inward.customerId, inward.customerName);
    } else {
      // Update regular stock maintenance
      await _ref
          .read(stockMaintenanceProvider.notifier)
          .updateStockFromGRN(inward);
    }

    print('Successfully added inward ${inward.grnNo}');
  }

  @override
  Future<void> update(StoreInward inward) async {
    // Call parent update method which handles Hive and Firestore
    await super.update(inward);

    // Update stock maintenance based on type
    if (inward.isCustomerScope) {
      // Update customer scope stock maintenance
      await _ref
          .read(customerScopeStockMaintenanceProvider.notifier)
          .updateStockFromGRN(inward, inward.customerId, inward.customerName);
    } else {
      // Update regular stock maintenance
      await _ref
          .read(stockMaintenanceProvider.notifier)
          .updateStockFromGRN(inward);
    }

    print('Successfully updated inward ${inward.grnNo}');
  }

  @override
  Future<bool> delete(StoreInward inward) async {
    // Check if GR has any Quality Inspections
    final inspectionBox = _ref.read(qualityInspectionBoxProvider);
    bool hasQIs = inspectionBox.values
        .any((inspection) => inspection.grnNo == inward.grnNo);

    if (hasQIs) {
      return false; // Cannot delete GR with quality inspections
    }

    // First reverse the GRN's effect on stock
    await _reverseStockUpdate(inward);

    // Call parent delete method which handles Hive and Firestore
    return await super.delete(inward);
  }

  Future<void> updateFromInspection(QualityInspection inspection) async {
    try {
      // Find the GRN
      final inward = box.values.firstWhere(
        (grn) => grn.grnNo == inspection.grnNo,
        orElse: () => throw Exception('GRN not found: ${inspection.grnNo}'),
      );

      // Update GRN status based on inspection
      inward.status = inspection.status;

      // Update quantities for each item
      for (var inspectionItem in inspection.items) {
        final grnItem = inward.items.firstWhere(
          (item) => item.materialCode == inspectionItem.materialCode,
          orElse: () => throw Exception(
              'Material ${inspectionItem.materialCode} not found in GRN ${inward.grnNo}'),
        );

        grnItem.acceptedQty = inspectionItem.acceptedQty;
        grnItem.rejectedQty = inspectionItem.rejectedQty;
      }

      // Use the BaseProvider update method
      await update(inward);

      print('Successfully updated GRN ${inward.grnNo} from inspection');
    } catch (e) {
      print('Error updating GRN from inspection: $e');
      rethrow;
    }
  }

  // Helper method to reverse a GRN's effect on stock
  Future<void> _reverseStockUpdate(StoreInward inward) async {
    final stockProvider = _ref.read(stockMaintenanceProvider.notifier);

    for (var item in inward.items) {
      final stock = stockProvider.getStockForMaterial(item.materialCode);
      if (stock != null) {
        // Reverse the stock quantities
        stock.updateCurrentStock(stock.currentStock - item.acceptedQty);
        stock.updateStockUnderInspection(stock.stockUnderInspection -
            (item.receivedQty - (item.acceptedQty + item.rejectedQty)));

        // Remove GRN details
        stock.grnDetails.remove(inward.grnNo);

        // Remove PO details if this was the only GR for that PO
        for (var poNo in item.prQuantities.keys) {
          bool hasOtherGRsForPO = box.values
              .where((gr) => gr.grnNo != inward.grnNo)
              .any((gr) => gr.items.any((i) =>
                  i.materialCode == item.materialCode &&
                  i.prQuantities.containsKey(poNo)));

          if (!hasOtherGRsForPO) {
            stock.poDetails.remove(poNo);
          }
        }

        // Remove PR details if this was the only GR for those PRs
        for (var poEntry in item.prQuantities.entries) {
          final poNo = poEntry.key;
          for (var prNo in poEntry.value.keys) {
            bool hasOtherGRsForPR = box.values
                .where((gr) => gr.grnNo != inward.grnNo)
                .any((gr) => gr.items.any((i) =>
                    i.materialCode == item.materialCode &&
                    i.prQuantities[poNo]?.containsKey(prNo) == true));

            if (!hasOtherGRsForPR) {
              stock.prDetails.remove(prNo);
            }
          }
        }

        // Remove job details if this was the only GR for those jobs
        final jobsToCheck = item.getJobNumbers();
        for (var jobNo in jobsToCheck) {
          bool hasOtherGRsForJob = box.values
              .where((gr) => gr.grnNo != inward.grnNo)
              .any((gr) => gr.items.any((i) =>
                  i.materialCode == item.materialCode &&
                  i.getJobNumbers().contains(jobNo)));

          if (!hasOtherGRsForJob) {
            stock.jobDetails.remove(jobNo);
          }
        }

        // Update vendor details
        if (stock.vendorDetails.containsKey(inward.supplierName)) {
          final vendorDetails = stock.vendorDetails[inward.supplierName]!;
          vendorDetails.quantity -= item.receivedQty;
          if (vendorDetails.quantity <= 0) {
            stock.vendorDetails.remove(inward.supplierName);
          }
        }

        // Save the updated stock
        await stock.save();
      }
    }
  }

  // Get all inwards for a specific material
  List<StoreInward> getInwardsForMaterial(String materialCode) {
    return box.values
        .where((inward) =>
            inward.items.any((item) => item.materialCode == materialCode))
        .toList();
  }

  // Get all inwards for a specific supplier
  List<StoreInward> getInwardsForSupplier(String supplierName) {
    return box.values
        .where((inward) => inward.supplierName == supplierName)
        .toList();
  }

  // Get all inwards for a specific PO
  List<StoreInward> getInwardsForPO(String poNo) {
    return box.values.where((inward) => inward.poNo == poNo).toList();
  }

  // Get all inwards between two dates
  List<StoreInward> getInwardsBetweenDates(DateTime start, DateTime end) {
    return box.values.where((inward) {
      final grnDate = DateTime.tryParse(inward.grnDate);
      return grnDate != null &&
          grnDate.isAfter(start.subtract(const Duration(days: 1))) &&
          grnDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get total received quantity for a material from a specific PO
  double getTotalReceivedQuantityForPO(String materialCode, String poNo) {
    return box.values
        .where((inward) => inward.items.any((item) =>
            item.materialCode == materialCode &&
            item.prQuantities.containsKey(poNo)))
        .fold(0.0, (sum, inward) {
      final item =
          inward.items.firstWhere((item) => item.materialCode == materialCode);
      return sum +
          item.prQuantities[poNo]!.values.fold(0.0, (sum, qty) => sum + qty);
    });
  }

  // Get total received quantity for a specific PR
  double? getReceivedQuantityForPR(
      String materialCode, String poNo, String prNo) {
    double total = 0;
    for (var inward in state) {
      for (var item in inward.items) {
        if (item.materialCode == materialCode) {
          final prQty = item.prQuantities[poNo]?[prNo] ?? 0;
          total += prQty;
        }
      }
    }
    return total;
  }

  // Check and delete PO if no GRs exist for it
  Future<void> deletePOIfNoGRs(String poNo) async {
    // Check if any GR exists for this PO
    bool hasGRs = false;
    for (var inward in box.values) {
      for (var item in inward.items) {
        if (item.prQuantities.containsKey(poNo)) {
          hasGRs = true;
          break;
        }
      }
      if (hasGRs) break;
    }

    // If no GRs exist, delete the PO
    if (!hasGRs) {
      final poBox = _ref.read(purchaseOrderBoxProvider);
      try {
        final po = poBox.values.firstWhere((po) => po.poNo == poNo);
        await po.delete();
      } catch (e) {
        // PO not found, which is fine in this case
      }

      // Also update stock maintenance
      final stockBox = _ref.read(stockMaintenanceBoxProvider);
      final stocks = stockBox.values.toList();
      for (var stock in stocks) {
        stock.poDetails.remove(poNo);
        stock.save();
      }
    }
  }

  // Delete GR and update related data
  Future<void> deleteGR(String grnNo) async {
    try {
      final inward = box.values.firstWhere((gr) => gr.grnNo == grnNo);

      // Get all PO numbers from this GR
      final poNumbers = <String>{};
      for (var item in inward.items) {
        poNumbers.addAll(item.prQuantities.keys);
      }

      // First reverse the stock updates
      await _reverseStockUpdate(inward);

      // Delete the GR
      await inward.delete();

      // Check and delete POs that might have no more GRs
      for (var poNo in poNumbers) {
        await deletePOIfNoGRs(poNo);
      }

      state = box.values.toList();
    } catch (e) {
      // GR not found
      return;
    }
  }

  // Update GRN status based on inspection status
  Future<void> updateGRNStatus(String grnNo) async {
    print('\n=== Debug: Updating GRN Status ===');
    print('GRN No: $grnNo');

    final inward = box.values.firstWhere(
      (gr) => gr.grnNo == grnNo,
      orElse: () => throw Exception('GRN not found'),
    );

    print('Current Status: ${inward.status}');

    // Get all inspections for this GRN
    final inspectionBox = _ref.read(qualityInspectionBoxProvider);
    final inspections =
        inspectionBox.values.where((insp) => insp.grnNo == grnNo).toList();

    // Process each item in the GRN
    for (var item in inward.items) {
      print('\nChecking Item: ${item.materialCode}');
      print('Received Qty: ${item.receivedQty}');

      // Calculate total accepted and rejected quantities from all inspections
      double totalAcceptedQty = 0.0;
      double totalRejectedQty = 0.0;

      for (var inspection in inspections) {
        var inspectionItem = inspection.items
            .where((i) => i.materialCode == item.materialCode)
            .firstOrNull;

        if (inspectionItem != null) {
          // Get the GRN quantities from the inspection item
          var grnQty = inspectionItem.grnQuantities[grnNo];
          if (grnQty?.isSelected == true) {
            print('\nFound inspection: ${inspection.inspectionNo}');
            print('Accepted Qty: ${grnQty!.acceptedQty}');
            print('Rejected Qty: ${grnQty.rejectedQty}');

            totalAcceptedQty += grnQty.acceptedQty;
            totalRejectedQty += grnQty.rejectedQty;
          }
        }
      }

      print('Total Accepted Qty: $totalAcceptedQty');
      print('Total Rejected Qty: $totalRejectedQty');

      // Update item quantities
      item.acceptedQty = totalAcceptedQty;
      item.rejectedQty = totalRejectedQty;

      // Update PR-wise quantities based on acceptance ratio
      if (item.receivedQty > 0) {
        double acceptanceRatio = totalAcceptedQty / item.receivedQty;
        for (var poEntry in item.prQuantities.entries) {
          final prMap = poEntry.value;
          if (prMap != null) {
            for (var prEntry in prMap.entries) {
              final prNo = prEntry.key;
              final originalQty = prEntry.value;
              prMap[prNo] = originalQty * acceptanceRatio;
            }
          }
        }
      }
    }

    // Determine GRN status based on all items
    bool allItemsInspected = inward.items.every((item) {
      double totalProcessedQty = item.acceptedQty + item.rejectedQty;
      bool isFullyProcessed =
          (totalProcessedQty - item.receivedQty).abs() < 0.001;
      print('\nItem: ${item.materialCode}');
      print('Received: ${item.receivedQty}');
      print('Processed: $totalProcessedQty');
      print('Fully Processed: $isFullyProcessed');
      return isFullyProcessed;
    });

    bool hasAcceptedItems = inward.items.any((item) => item.acceptedQty > 0);
    bool hasRejectedItems = inward.items.any((item) => item.rejectedQty > 0);

    String newStatus;
    if (allItemsInspected) {
      if (hasRejectedItems && !hasAcceptedItems) {
        newStatus = 'Rejected';
      } else if (hasRejectedItems && hasAcceptedItems) {
        newStatus = 'Partially Accepted';
      } else {
        newStatus = 'Accepted';
      }
    } else {
      newStatus = 'Under Inspection';
    }

    print('New Status: $newStatus');
    inward.status = newStatus;

    // Use BaseProvider's update method to ensure proper persistence
    await update(inward);

    // Update stock maintenance
    await _ref
        .read(stockMaintenanceProvider.notifier)
        .updateStockFromGRN(inward);
  }

  // Helper method to mark PO as having GR
  Future<void> _markPOAsHavingGR(StoreInward inward) async {
    try {
      final poNotifier = _ref.read(purchaseOrderListProvider.notifier);
      
      // Get all unique PO numbers from the GR
      final poNumbers = <String>{};
      for (var item in inward.items) {
        poNumbers.addAll(item.prQuantities.keys);
      }
      
      // Mark each PO as having GR
      for (var poNo in poNumbers) {
        final po = poNotifier.getOrderByNo(poNo);
        if (po != null && !po.hasGR) {
          final updatedPO = po.copyWith(hasGR: true);
          await poNotifier.update(updatedPO);
        }
      }
    } catch (e) {
      print('Error marking PO as having GR: $e');
    }
  }
}
