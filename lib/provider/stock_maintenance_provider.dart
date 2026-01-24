// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;
import '../models/stock_maintenance.dart';
import '../models/store_inward.dart';
import '../models/quality_inspection.dart';
import '../models/material_item.dart';
import 'base_provider.dart';

final stockMaintenanceBoxProvider = Provider<Box<StockMaintenance>>((ref) {
  throw UnimplementedError();
});

final stockMaintenanceProvider =
    StateNotifierProvider<StockMaintenanceNotifier, List<StockMaintenance>>(
  (ref) => StockMaintenanceNotifier(
    ref.watch(stockMaintenanceBoxProvider),
    ref,
  ),
);

class StockMaintenanceNotifier extends BaseProvider<StockMaintenance> {
  StockMaintenanceNotifier(Box<StockMaintenance> stockBox, Ref ref)
      : super(stockBox, 'stockMaintenance') {
    if (!Hive.isAdapterRegistered(76)) {
      Hive.registerAdapter(StockTransferHistoryEntryAdapter());
    }
  }

  StockMaintenance? _getStockByCode(String materialCode) {
    try {
      return state.firstWhere((s) => s.materialCode == materialCode);
    } catch (_) {
      return null;
    }
  }

  String _transferBucketKey({
    required String basePrNo,
    required String jobNo,
  }) {
    return '$basePrNo|XFER|$jobNo|${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _isTransferBucketKey(String key, String basePrNo, String jobNo) {
    return key.startsWith('$basePrNo|XFER|$jobNo|');
  }

  double _availableForPrBucket(StockPRDetails prDetail) {
    return prDetail.receivedQuantity - prDetail.issuedQuantity;
  }

  double _availableForBasePrInJob(StockMaintenance stock, String basePrNo, String jobNo) {
    double total = 0.0;
    for (final entry in stock.prDetails.entries) {
      final key = entry.key;
      final prDetail = entry.value;
      if (prDetail.jobNo != jobNo) continue;
      if (key == basePrNo || _isTransferBucketKey(key, basePrNo, jobNo)) {
        total += _availableForPrBucket(prDetail);
      }
    }
    return total;
  }

  double _availableForJobTotal(StockMaintenance stock, String jobNo) {
    double total = 0.0;
    for (final prDetail in stock.prDetails.values) {
      if (prDetail.jobNo != jobNo) continue;
      total += _availableForPrBucket(prDetail);
    }
    return total;
  }

  List<String> _sourceKeysForJobTotal(StockMaintenance stock, String jobNo) {
    final keys = stock.prDetails.entries
        .where((e) => e.value.jobNo == jobNo && _availableForPrBucket(e.value) > 0)
        .map((e) => e.key)
        .toList();

    // Prefer stable order: by prDate (if parseable) then key.
    keys.sort((a, b) {
      final pa = stock.prDetails[a];
      final pb = stock.prDetails[b];
      final da = pa?.prDate ?? '';
      final db = pb?.prDate ?? '';
      if (da != db) return da.compareTo(db);
      return a.compareTo(b);
    });
    return keys;
  }

  void _ensureJobDetailsForTransfer(StockMaintenance stock, String jobNo) {
    if (stock.jobDetails.containsKey(jobNo)) return;
    stock.jobDetails[jobNo] = StockJobDetails(
      jobNo: jobNo,
      allocatedQuantity: 0.0,
      consumedQuantity: 0.0,
      prNo: 'General',
    );
  }

  void _recalculateJobAllocatedFromPrDetails(StockMaintenance stock, String jobNo) {
    final jobDetail = stock.jobDetails[jobNo];
    if (jobDetail == null) return;
    double allocated = 0.0;
    for (final pr in stock.prDetails.values) {
      if (pr.jobNo == jobNo) {
        allocated += pr.receivedQuantity;
      }
    }
    jobDetail.allocatedQuantity = allocated;
  }

  /// Partial transfer for a given PR+Material between Board(job) and General.
  ///
  /// This is implemented by moving quantities between PR buckets inside `stock.prDetails`.
  ///
  /// - Source bucket(s): the base PR bucket (key = basePrNo) and any existing transfer buckets
  ///   that belong to `fromJobNo`.
  /// - Destination bucket: a new synthetic PR bucket under `toJobNo`.
  ///
  /// Stock value and GRN/PO traces remain unchanged; this is a classification change for
  /// job-wise availability calculations.
  Future<void> transferStockForPRMaterial({
    required String materialCode,
    required String basePrNo,
    required String boardJobNo,
    required String fromJobNo,
    required String toJobNo,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      throw Exception('Transfer quantity must be > 0');
    }
    if (fromJobNo == toJobNo) {
      throw Exception('From and To cannot be the same');
    }
    if (boardJobNo.trim().isEmpty || boardJobNo == 'General') {
      throw Exception('Invalid board job number');
    }

    final stock = _getStockByCode(materialCode);
    if (stock == null) {
      throw Exception('Stock not found');
    }

    final available = fromJobNo == 'General'
        ? _availableForJobTotal(stock, 'General')
        : _availableForBasePrInJob(stock, basePrNo, fromJobNo);
    if (quantity > available + 0.0001) {
      throw Exception('Insufficient stock for transfer');
    }

    // Source buckets:
    // - If from General: drain from overall General pool.
    // - Else (board/job): drain only from the base PR bucket and its transfer buckets.
    final sourceKeys = <String>[];
    if (fromJobNo == 'General') {
      sourceKeys.addAll(_sourceKeysForJobTotal(stock, 'General'));
    } else {
      if (stock.prDetails.containsKey(basePrNo) &&
          stock.prDetails[basePrNo]!.jobNo == fromJobNo) {
        sourceKeys.add(basePrNo);
      }
      final transferKeys = stock.prDetails.keys
          .where((k) => _isTransferBucketKey(k, basePrNo, fromJobNo))
          .toList()
        ..sort();
      sourceKeys.addAll(transferKeys);
    }

    double remaining = quantity;
    for (final key in sourceKeys) {
      if (remaining <= 0) break;
      final prDetail = stock.prDetails[key];
      if (prDetail == null) continue;
      if (prDetail.jobNo != fromJobNo) continue;
      final availableInBucket = _availableForPrBucket(prDetail);
      if (availableInBucket <= 0) continue;

      final move = math.min(availableInBucket, remaining);

      // Reduce receivedQuantity in source bucket (keep issuedQuantity as-is).
      // Since move <= available, received will stay >= issued.
      prDetail.receivedQuantity = prDetail.receivedQuantity - move;

      // Create destination bucket record.
      // If destination is General, keep it in the pooled General namespace.
      final destKey = toJobNo == 'General'
          ? _transferBucketKey(basePrNo: 'General', jobNo: 'General')
          : _transferBucketKey(basePrNo: basePrNo, jobNo: toJobNo);
      stock.prDetails[destKey] = StockPRDetails(
        prNo: destKey,
        prDate: DateTime.now().toString().split(' ').first,
        requestedQuantity: 0.0,
        orderedQuantity: 0.0,
        receivedQuantity: move,
        issuedQuantity: 0.0,
        jobNo: toJobNo,
      );

      remaining -= move;
    }

    // Clean up empty transfer buckets (optional). Never remove basePrNo or 'General'.
    final keysToRemove = <String>[];
    for (final entry in stock.prDetails.entries) {
      final key = entry.key;
      final pr = entry.value;
      if (key == basePrNo || key == 'General') continue;
      final isFromBucket = fromJobNo == 'General'
          ? pr.jobNo == 'General' && key.startsWith('General|XFER|General|')
          : _isTransferBucketKey(key, basePrNo, fromJobNo);
      if (!isFromBucket) continue;
      if (_availableForPrBucket(pr) <= 0.0000001 && pr.issuedQuantity <= 0.0000001) {
        keysToRemove.add(key);
      }
    }
    for (final k in keysToRemove) {
      stock.prDetails.remove(k);
    }

    // Ensure jobDetails exist and update allocated quantities to match received totals.
    _ensureJobDetailsForTransfer(stock, fromJobNo);
    _ensureJobDetailsForTransfer(stock, toJobNo);
    _recalculateJobAllocatedFromPrDetails(stock, fromJobNo);
    _recalculateJobAllocatedFromPrDetails(stock, toJobNo);

    // Log transfer history (material-level) for audit.
    stock.transferHistory.add(
      StockTransferHistoryEntry(
        dateTime: DateTime.now().toIso8601String(),
        basePrNo: basePrNo,
        boardJobNo: boardJobNo,
        fromJobNo: fromJobNo,
        toJobNo: toJobNo,
        quantity: quantity,
      ),
    );
    // Keep recent entries only to avoid document bloat.
    if (stock.transferHistory.length > 200) {
      stock.transferHistory = stock.transferHistory
          .sublist(stock.transferHistory.length - 200);
    }

    await update(stock);
  }

  @override
  Map<String, dynamic> modelToMap(StockMaintenance stock) {
    return {
      'materialCode': stock.materialCode,
      'materialDescription': stock.materialDescription,
      'unit': stock.unit,
      'storageLocation': stock.storageLocation,
      'rackNumber': stock.rackNumber,
      'currentStock': stock.currentStock,
      'stockUnderInspection': stock.stockUnderInspection,
      'totalStockValue': stock.totalStockValue,
      'transferHistory': stock.transferHistory
          .map((e) => {
                'dateTime': e.dateTime,
                'basePrNo': e.basePrNo,
                'boardJobNo': e.boardJobNo,
                'fromJobNo': e.fromJobNo,
                'toJobNo': e.toJobNo,
                'quantity': e.quantity,
              })
          .toList(),
      'grnDetails': stock.grnDetails.map((key, value) => MapEntry(key, {
            'grnNo': value.grnNo,
            'grnDate': value.grnDate,
            'receivedQuantity': value.receivedQuantity,
            'acceptedQuantity': value.acceptedQuantity,
            'rejectedQuantity': value.rejectedQuantity,
            'vendorId': value.vendorId,
            'rate': value.rate,
            'issuedQuantity': value.issuedQuantity,
            'issuedQuantities': value.issuedQuantities,
          })),
      'poDetails': stock.poDetails.map((key, value) => MapEntry(key, {
            'poNo': value.poNo,
            'poDate': value.poDate,
            'orderedQuantity': value.orderedQuantity,
            'receivedQuantity': value.receivedQuantity,
            'vendorId': value.vendorId,
            'rate': value.rate,
            'receivedQuantities': value.receivedQuantities,
          })),
      'prDetails': stock.prDetails.map((key, value) => MapEntry(key, {
            'prNo': value.prNo,
            'prDate': value.prDate,
            'requestedQuantity': value.requestedQuantity,
            'orderedQuantity': value.orderedQuantity,
            'receivedQuantity': value.receivedQuantity,
            'issuedQuantity': value.issuedQuantity,
            'jobNo': value.jobNo,
          })),
      'jobDetails': stock.jobDetails.map((key, value) => MapEntry(key, {
            'jobNo': value.jobNo,
            'allocatedQuantity': value.allocatedQuantity,
            'consumedQuantity': value.consumedQuantity,
          })),
      'vendorDetails': stock.vendorDetails.map((key, value) => MapEntry(key, {
            'vendorId': value.vendorId,
            'vendorName': value.vendorName,
            'quantity': value.quantity,
            'rate': value.rate,
            'lastPurchaseDate': value.lastPurchaseDate,
          })),
    };
  }

  @override
  StockMaintenance mapToModel(Map<String, dynamic> map) {
    final stock = StockMaintenance(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      storageLocation: map['storageLocation'] ?? '',
      rackNumber: map['rackNumber'] ?? '',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      stockUnderInspection:
          (map['stockUnderInspection'] as num?)?.toDouble() ?? 0.0,
      totalStockValue: (map['totalStockValue'] as num?)?.toDouble() ?? 0.0,
    );

    // Load Transfer history (optional/backward compatible)
    if (map['transferHistory'] is List) {
      for (final entry in (map['transferHistory'] as List)) {
        if (entry is Map) {
          stock.transferHistory.add(
            StockTransferHistoryEntry(
              dateTime: (entry['dateTime'] ?? '').toString(),
              basePrNo: (entry['basePrNo'] ?? '').toString(),
              boardJobNo: (entry['boardJobNo'] ?? '').toString(),
              fromJobNo: (entry['fromJobNo'] ?? '').toString(),
              toJobNo: (entry['toJobNo'] ?? '').toString(),
              quantity: (entry['quantity'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
    }

    // Load GRN details
    if (map['grnDetails'] != null) {
      (map['grnDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.grnDetails[key] = StockGRNDetails(
          grnNo: value['grnNo'] ?? '',
          grnDate: value['grnDate'] ?? '',
          receivedQuantity:
              (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
          acceptedQuantity:
              (value['acceptedQuantity'] as num?)?.toDouble() ?? 0.0,
          rejectedQuantity:
              (value['rejectedQuantity'] as num?)?.toDouble() ?? 0.0,
          vendorId: value['vendorId'] ?? '',
          rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
          issuedQuantity: (value['issuedQuantity'] as num?)?.toDouble() ?? 0.0,
          issuedQuantities:
              (value['issuedQuantities'] as Map<String, dynamic>?)?.map(
                    (key, value) => MapEntry(key, (value as num).toDouble()),
                  ) ??
                  {},
        );
      });
    }

    // Load PO details
    if (map['poDetails'] != null) {
      (map['poDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.poDetails[key] = StockPODetails(
          poNo: value['poNo'] ?? '',
          poDate: value['poDate'] ?? '',
          orderedQuantity:
              (value['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
          receivedQuantity:
              (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
          vendorId: value['vendorId'] ?? '',
          rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
          receivedQuantities:
              (value['receivedQuantities'] as Map<String, dynamic>?)?.map(
                    (key, value) =>
                        MapEntry(key, Map<String, double>.from(value as Map)),
                  ) ??
                  {},
        );
      });
    }

    // Load PR details
    if (map['prDetails'] != null) {
      (map['prDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.prDetails[key] = StockPRDetails(
          prNo: value['prNo'] ?? '',
          prDate: value['prDate'] ?? '',
          requestedQuantity:
              (value['requestedQuantity'] as num?)?.toDouble() ?? 0.0,
          orderedQuantity:
              (value['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
          receivedQuantity:
              (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
          issuedQuantity: (value['issuedQuantity'] as num?)?.toDouble() ?? 0.0,
          jobNo: value['jobNo'] ?? '',
        );
      });
    }

    // Load Job details
    if (map['jobDetails'] != null) {
      (map['jobDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.jobDetails[key] = StockJobDetails(
          jobNo: value['jobNo'] ?? '',
          allocatedQuantity:
              (value['allocatedQuantity'] as num?)?.toDouble() ?? 0.0,
          consumedQuantity:
              (value['consumedQuantity'] as num?)?.toDouble() ?? 0.0,
          prNo: value['prNo'] ?? 'General',
        );
      });
    }

    // Load Vendor details
    if (map['vendorDetails'] != null) {
      (map['vendorDetails'] as Map<String, dynamic>).forEach((key, value) {
        stock.vendorDetails[key] = StockVendorDetails(
          vendorId: value['vendorId'] ?? '',
          vendorName: value['vendorName'] ?? '',
          quantity: (value['quantity'] as num?)?.toDouble() ?? 0.0,
          rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
          lastPurchaseDate: value['lastPurchaseDate'] ?? '',
        );
      });
    }

    return stock;
  }

  @override
  String getModelId(StockMaintenance stock) => stock.materialCode;

  // Backward compatibility methods
  Future<void> loadStock() => loadData();

  @override
  Future<void> loadData() async {
    print('\n=== Debug: Stock Maintenance LoadData ===');
    print('Collection Name: $collectionName');

    // Call parent loadData method
    await super.loadData();

    print('Stock Maintenance State after load: ${state.length} items');
    for (var stock in state) {
      print(
          'Stock: ${stock.materialCode} - Current: ${stock.currentStock} - Under Inspection: ${stock.stockUnderInspection}');
    }
    print('=== End Stock Maintenance LoadData ===\n');
  }

  // All existing functionality preserved below:

  Future<void> initializeStock(MaterialItem material) async {
    try {
      print('\n=== Initializing Stock for Material ${material.slNo} ===');

      // Check if stock already exists
      final existingStock = state
          .where((stock) => stock.materialCode == material.slNo)
          .firstOrNull;
      if (existingStock != null) {
        print('Stock already exists for material ${material.slNo}');
        return;
      }

      // Create new stock entry
      final newStock = StockMaintenance(
        materialCode: material.slNo,
        materialDescription: material.description,
        unit: material.unit,
        storageLocation: material.storageLocation ?? '',
        rackNumber: material.rackNumber ?? '',
        currentStock: 0.0,
        stockUnderInspection: 0.0,
        totalStockValue: 0.0,
      );

      await add(newStock);
      print('Stock initialized for material ${material.slNo}');
    } catch (e) {
      print('Error initializing stock: $e');
      rethrow;
    }
  }

  Future<void> updateStockFromGRN(StoreInward grn) async {
    print('\n=== Debug: Starting Stock Update from GRN ${grn.grnNo} ===');
    print('GRN Number: ${grn.grnNo}');

    try {
      // Process each item in the GRN
      for (var grnItem in grn.items) {
        print('\n--- Processing item: ${grnItem.materialCode} ---');

        // Get or create stock record for this material
        var stock = state.firstWhere(
          (s) => s.materialCode == grnItem.materialCode,
          orElse: () {
            print('Creating new stock record for ${grnItem.materialCode}');
            return StockMaintenance(
              materialCode: grnItem.materialCode,
              materialDescription: grnItem.materialDescription,
              unit: grnItem.unit,
              storageLocation: '',
              rackNumber: '',
            );
          },
        );

        // Check if this is a new stock record (not in state yet)
        bool isNewStock =
            !state.any((s) => s.materialCode == grnItem.materialCode);

        // Update GRN details
        stock.grnDetails[grn.grnNo] = StockGRNDetails(
          grnNo: grn.grnNo,
          grnDate: grn.grnDate,
          receivedQuantity: grnItem.receivedQty,
          acceptedQuantity: grnItem.acceptedQty,
          rejectedQuantity: grnItem.rejectedQty,
          vendorId: grn.supplierName,
          rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
          issuedQuantity: 0.0,
          issuedQuantities: {},
        );

        // Update PR and PO details
        _updatePRDetailsFromGRN(stock, grnItem, grn.grnNo, grn);

        // Calculate total stock quantities
        double totalCurrentStock = 0.0;
        double totalUnderInspection = 0.0;

        for (var grnDetail in stock.grnDetails.values) {
          totalCurrentStock += grnDetail.acceptedQuantity;
          totalUnderInspection += grnDetail.receivedQuantity -
              (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
        }

        print('New Current Stock: $totalCurrentStock');
        print('New Under Inspection: $totalUnderInspection');

        // Update stock quantities
        stock.updateCurrentStock(totalCurrentStock);
        stock.updateStockUnderInspection(totalUnderInspection);

        // Use BaseProvider's add method for new stock, update method for existing stock
        if (isNewStock) {
          await add(stock);
        } else {
          await update(stock);
        }
      }
    } catch (e) {
      print('Error updating stock from GRN: $e');
      rethrow;
    }
  }

  void _updatePRDetailsFromGRN(StockMaintenance stock, InwardItem grnItem,
      String grnNo, StoreInward grn) {
    print('\nUpdating PR details for ${grnItem.materialCode}');

    // Process each PO and its PR quantities
    for (var poEntry in grnItem.prQuantities.entries) {
      final poNo = poEntry.key;
      final prMap = poEntry.value;
      if (prMap.isEmpty) continue;

      print('Processing PO: $poNo');

      // Create or update PO details
      stock.poDetails[poNo] ??= StockPODetails(
        poNo: poNo,
        poDate: '', // This will be updated when we have PO date
        orderedQuantity: grnItem.orderedQty,
        receivedQuantity: 0.0,
        vendorId: grn.supplierName,
        rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
        receivedQuantities: {},
        issuedQuantities: {},
      );

      // Process each PR in this PO
      for (var prEntry in prMap.entries) {
        final prNo = prEntry.key;
        final prQty = prEntry.value;
        final jobNo = grnItem.prJobNumbers[poNo]?[prNo] ?? 'General';

        print('Processing PR: $prNo, Job: $jobNo, Quantity: $prQty');

        // Create or update PR details
        stock.prDetails[prNo] ??= StockPRDetails(
          prNo: prNo,
          prDate: '', // This will be updated when we have PR date
          requestedQuantity: prQty,
          orderedQuantity: prQty,
          receivedQuantity: 0.0,
          issuedQuantity: 0.0,
          jobNo: jobNo,
        );

        // Update job details if it's not a general PR
        if (jobNo != 'General') {
          print('Updating job details for job: $jobNo');
          stock.jobDetails[jobNo] ??= StockJobDetails(
            jobNo: jobNo,
            allocatedQuantity: prQty,
            consumedQuantity: 0.0,
            prNo: prNo,
          );
        }

        // Update PO received quantities
        stock.poDetails[poNo]!.addReceivedQuantity(grnNo, prNo, prQty);

        // Update PR received quantity immediately for accepted quantities
        if (grnItem.acceptedQty > 0) {
          final acceptanceRatio = grnItem.acceptedQty / grnItem.receivedQty;
          final acceptedQty = prQty * acceptanceRatio;
          stock.prDetails[prNo]!.receivedQuantity += acceptedQty;
          print(
              'Updated PR $prNo received quantity to: ${stock.prDetails[prNo]!.receivedQuantity}');
        }
      }

      // Update total received quantity for PO
      stock.poDetails[poNo]!.receivedQuantity = stock
          .poDetails[poNo]!.receivedQuantities.values
          .expand((map) => map.values)
          .fold(0.0, (sum, qty) => sum + qty);
    }

    // Update vendor details (simplified based on actual model)
    _updateVendorDetails(stock, grn.supplierName, grnItem);
  }

  void _updateVendorDetails(
      StockMaintenance stock, String vendorId, InwardItem grnItem) {
    // Create or update vendor details using the actual model fields
    if (stock.vendorDetails.containsKey(vendorId)) {
      final vendorDetails = stock.vendorDetails[vendorId]!;
      vendorDetails.quantity += grnItem.receivedQty;

      // Calculate new average rate
      final totalValue = (vendorDetails.rate *
              (vendorDetails.quantity - grnItem.receivedQty)) +
          (double.tryParse(grnItem.costPerUnit) ?? 0.0) * grnItem.receivedQty;
      vendorDetails.rate = totalValue / vendorDetails.quantity;
      vendorDetails.lastPurchaseDate = DateTime.now().toIso8601String();
    } else {
      stock.vendorDetails[vendorId] = StockVendorDetails(
        vendorId: vendorId,
        vendorName: vendorId, // Using vendorId as name for now
        quantity: grnItem.receivedQty,
        rate: double.tryParse(grnItem.costPerUnit) ?? 0.0,
        lastPurchaseDate: DateTime.now().toIso8601String(),
      );
    }
  }

  void _updatePRReceivedQuantitiesFromInspection(
      StockMaintenance stock, String grnNo, InspectionGRNQuantity grnQty) {
    print('\n=== Updating PR Received Quantities from Inspection ===');
    print(
        'GRN: $grnNo, Accepted: ${grnQty.acceptedQty}, Rejected: ${grnQty.rejectedQty}');

    // Find the GRN details to get the original PR mapping
    final grnDetails = stock.grnDetails[grnNo];
    if (grnDetails == null) {
      print('GRN details not found for $grnNo');
      return;
    }

    // Calculate acceptance ratio
    final totalReceived = grnDetails.receivedQuantity;
    final totalAccepted = grnQty.acceptedQty;
    final acceptanceRatio =
        totalReceived > 0 ? totalAccepted / totalReceived : 0.0;

    print('Acceptance Ratio: $acceptanceRatio');

    // Update PR received quantities based on acceptance ratio
    for (var poEntry in stock.poDetails.entries) {
      final poNo = poEntry.key;
      final poDetails = poEntry.value;

      // Check if this PO has received quantities for this GRN
      if (poDetails.receivedQuantities.containsKey(grnNo)) {
        final prQuantities = poDetails.receivedQuantities[grnNo]!;

        for (var prEntry in prQuantities.entries) {
          final prNo = prEntry.key;
          final originalQty = prEntry.value;
          final acceptedQty = originalQty * acceptanceRatio;

          print('PR: $prNo, Original: $originalQty, Accepted: $acceptedQty');

          // Update PR received quantity
          if (stock.prDetails.containsKey(prNo)) {
            // Reset the received quantity for this PR and add the accepted quantity
            stock.prDetails[prNo]!.receivedQuantity = acceptedQty;
            print('Updated PR $prNo received quantity to: $acceptedQty');
          }
        }
      }
    }
  }

  Future<void> updateStockFromInspection(QualityInspection inspection) async {
    try {
      print(
          '\n=== Updating Stock from Inspection ${inspection.inspectionNo} ===');

      for (var inspectionItem in inspection.items) {
        print('\nProcessing inspection item: ${inspectionItem.materialCode}');

        // Find stock for this material
        final stock = state
            .where((s) => s.materialCode == inspectionItem.materialCode)
            .firstOrNull;

        if (stock != null) {
          print('Found stock record for ${inspectionItem.materialCode}');
          bool stockUpdated = false;
          
          // Update GRN details with inspection results
          for (var grnEntry in inspectionItem.grnQuantities.entries) {
            final grnNo = grnEntry.key;
            final grnQty = grnEntry.value;

            print('Processing GRN: $grnNo, Selected: ${grnQty.isSelected}');
            print('Accepted: ${grnQty.acceptedQty}, Rejected: ${grnQty.rejectedQty}');

            if (stock.grnDetails.containsKey(grnNo) &&
                (grnQty.isSelected ?? false)) {
              print('Updating GRN details for $grnNo');
              
              // Store old values for comparison
              final grnDetail = stock.grnDetails[grnNo];
              if (grnDetail == null) {
                print('Error: GRN detail is null for $grnNo');
                continue;
              }
              
              final oldAccepted = grnDetail.acceptedQuantity;
              final oldRejected = grnDetail.rejectedQuantity;
              
              grnDetail.acceptedQuantity = grnQty.acceptedQty;
              grnDetail.rejectedQuantity = grnQty.rejectedQty;
              
              print('Updated GRN $grnNo: Accepted $oldAccepted -> ${grnQty.acceptedQty}, Rejected $oldRejected -> ${grnQty.rejectedQty}');

              // Update PR received quantities based on acceptance ratio
              _updatePRReceivedQuantitiesFromInspection(stock, grnNo, grnQty);
              stockUpdated = true;
            } else {
              if (!stock.grnDetails.containsKey(grnNo)) {
                print('Warning: GRN $grnNo not found in stock details');
              }
              if (!(grnQty.isSelected ?? false)) {
                print('GRN $grnNo not selected for inspection');
              }
            }
          }

          if (stockUpdated) {
            // Recalculate stock quantities
            double totalCurrentStock = 0.0;
            double totalUnderInspection = 0.0;

            for (var grnDetail in stock.grnDetails.values) {
              totalCurrentStock += grnDetail.acceptedQuantity;
              totalUnderInspection += grnDetail.receivedQuantity -
                  (grnDetail.acceptedQuantity + grnDetail.rejectedQuantity);
            }

            print('Recalculated - Current Stock: $totalCurrentStock, Under Inspection: $totalUnderInspection');

            // Update stock quantities
            stock.updateCurrentStock(totalCurrentStock);
            stock.updateStockUnderInspection(totalUnderInspection);

            // Use BaseProvider's update method to ensure proper persistence
            await update(stock);
            print('Stock successfully updated and persisted for ${inspectionItem.materialCode}');
          } else {
            print('No stock updates needed for ${inspectionItem.materialCode}');
          }
        } else {
          print('Stock not found for material: ${inspectionItem.materialCode}');
          // This should not happen if stock was created during GRN
          print('Warning: Stock should have been created during GRN process');
        }
      }
      
      print('=== Completed Stock Update from Inspection ===');
    } catch (e) {
      print('Error updating stock from inspection: $e');
      rethrow;
    }
  }

  Future<void> updateStockLocation(
      String materialCode, String newLocation, String newRack) async {
    try {
      var stock =
          state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        stock.storageLocation = newLocation;
        stock.rackNumber = newRack;
        await update(stock);
        print('Updated location for material $materialCode');
      }
    } catch (e) {
      print('Error updating stock location: $e');
      rethrow;
    }
  }

  Future<void> cancelPendingDelivery(
      String materialCode, String jobNo, double quantity) async {
    try {
      var stock =
          state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        final jobDetails = stock.jobDetails[jobNo];
        if (jobDetails != null) {
          jobDetails.allocatedQuantity =
              math.max(0, jobDetails.allocatedQuantity - quantity);
          stock.currentStock += quantity; // Return to available stock
          await update(stock);
        }
      }
    } catch (e) {
      print('Error canceling pending delivery: $e');
      rethrow;
    }
  }

  // Method removed - pendingDeliveryQuantity field no longer exists

  Future<void> consumeStockForJob(
      String materialCode, String jobNo, double quantity) async {
    try {
      var stock =
          state.where((s) => s.materialCode == materialCode).firstOrNull;
      if (stock != null) {
        final jobDetails = stock.jobDetails[jobNo];
        if (jobDetails != null) {
          jobDetails.consumedQuantity += quantity;
          await update(stock);
        }
      }
    } catch (e) {
      print('Error consuming stock for job: $e');
      rethrow;
    }
  }

  // Search and filter methods
  List<StockMaintenance> searchStock(String query) {
    return search(
        query,
        (stock, query) =>
            stock.materialCode.toLowerCase().contains(query) ||
            stock.materialDescription.toLowerCase().contains(query));
  }

  List<StockMaintenance> getLowStockItems({double threshold = 10.0}) {
    return state.where((stock) => stock.currentStock <= threshold).toList();
  }

  List<StockMaintenance> getZeroStockItems() {
    return state.where((stock) => stock.currentStock == 0).toList();
  }

  List<StockMaintenance> getStockUnderInspection() {
    return state.where((stock) => stock.stockUnderInspection > 0).toList();
  }

  StockMaintenance? getStockByMaterialCode(String materialCode) {
    return state
        .where((stock) => stock.materialCode == materialCode)
        .firstOrNull;
  }

  // Alias for backward compatibility
  StockMaintenance? getStockForMaterial(String materialCode) {
    return getStockByMaterialCode(materialCode);
  }

  double getTotalStockValue() {
    return state.fold(0.0, (sum, stock) => sum + stock.totalStockValue);
  }

  Map<String, double> getVendorWiseStockValue() {
    final vendorValues = <String, double>{};
    for (var stock in state) {
      for (var vendor in stock.vendorDetails.values) {
        vendorValues[vendor.vendorId] = (vendorValues[vendor.vendorId] ?? 0.0) +
            (vendor.quantity * vendor.rate);
      }
    }
    return vendorValues;
  }
}
