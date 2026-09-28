// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/delivery_challan.dart';
import '../models/stock_maintenance.dart';
import 'base_provider.dart';
import 'stock_maintenance_provider.dart';
import '../utils/company_config.dart';

final deliveryChallanBoxProvider = Provider<Box<DeliveryChallan>>((ref) {
  return Hive.box<DeliveryChallan>('delivery_challans');
});

final stockMaintenanceBoxProvider = Provider<Box<StockMaintenance>>((ref) {
  return Hive.box<StockMaintenance>('stock_maintenance');
});

final deliveryChallanListProvider =
    StateNotifierProvider<DeliveryChallanNotifier, List<DeliveryChallan>>(
        (ref) {
  final dcBox = ref.read(deliveryChallanBoxProvider);
  final stockBox = ref.read(stockMaintenanceBoxProvider);
  return DeliveryChallanNotifier(dcBox, stockBox);
});

class DeliveryChallanNotifier extends BaseProvider<DeliveryChallan> {
  final Box<StockMaintenance> _stockBox;

  DeliveryChallanNotifier(Box<DeliveryChallan> box, this._stockBox)
      : super(box, 'delivery_challans');

  @override
  Map<String, dynamic> modelToMap(DeliveryChallan dc) {
    return {
      'dcNo': dc.dcNo,
      'dcDate': dc.dcDate,
      'vendorName': dc.vendorName,
      'vendorEmail': dc.vendorEmail,
      'vendorGstin': dc.vendorGstin,
      'dcType': dc.dcType,
      'internalFlow': dc.internalFlow,
      'fromVendor': dc.fromVendor,
      'toVendor': dc.toVendor,
      'items': dc.items
          .map((item) => {
                'materialCode': item.materialCode,
                'materialDescription': item.materialDescription,
                'unit': item.unit,
                'quantity': item.quantity,
                'jobNo': item.jobNo,
                'prNo': item.prNo,
                'price': item.price,
              })
          .toList(),
      'isReturnable': dc.isReturnable,
      'note': dc.note,
    };
  }

  @override
  DeliveryChallan mapToModel(Map<String, dynamic> map) {
    return DeliveryChallan(
      dcNo: map['dcNo'] ?? '',
      dcDate: map['dcDate'] ?? '',
      vendorName: map['vendorName'] ?? '',
      vendorEmail: map['vendorEmail'],
      vendorGstin: map['vendorGstin'],
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => DeliveryChallanItem(
                materialCode: item['materialCode'] ?? '',
                materialDescription: item['materialDescription'] ?? '',
                unit: item['unit'] ?? '',
                quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
                jobNo: item['jobNo'],
                prNo: item['prNo'],
                price: (item['price'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList(),
      isReturnable: map['isReturnable'] ?? false,
      note: map['note'],
      dcType: map['dcType'] ?? 'regular',
      internalFlow: map['internalFlow'] ?? 'outward',
      fromVendor: map['fromVendor'],
      toVendor: map['toVendor'],
    );
  }

  @override
  String getModelId(DeliveryChallan dc) => dc.dcNo;

  // Map old method names to new base provider methods
  Future<void> loadDeliveryChallans() => loadData();

  Future<void> addDeliveryChallan(DeliveryChallan dc, WidgetRef ref) async {
    try {
      await _validateStockForDeliveryChallan(dc, ref);

      // Update stock for internal DCs (both inward and outward)
      if (dc.dcType == 'internal') {
        await _updateStockForInternalDC(dc, isAdd: true, ref: ref);
      }

      if (dc.dcType == 'job_order') {
        final stockNotifier = ref.read(stockMaintenanceProvider.notifier);
        for (final entry in _requiredJobStock(dc).entries) {
          await stockNotifier.consumeStockFromJobBucket(
            materialCode: entry.key.$1,
            jobNo: entry.key.$2,
            quantity: entry.value,
          );
        }
      }

      // Add delivery challan
      await add(dc);
    } catch (e) {
      print('Error adding delivery challan: $e');
      rethrow;
    }
  }

  Map<(String, String), double> _requiredJobStock(DeliveryChallan dc) {
    final required = <(String, String), double>{};
    for (final item in dc.items) {
      final jobNo = item.jobNo?.trim() ?? '';
      if (jobNo.isEmpty || jobNo == 'General') continue;
      final key = (item.materialCode.trim(), jobNo);
      required[key] = (required[key] ?? 0.0) + item.quantity;
    }
    return required;
  }

  Future<void> _validateStockForDeliveryChallan(
      DeliveryChallan dc, WidgetRef ref) async {
    // Skip stock validation for internal inward DCs
    if (dc.dcType == 'internal' && dc.internalFlow == 'inward') {
      return;
    }

    final stockNotifier = ref.read(stockMaintenanceProvider.notifier);
    final required = <(String, String), double>{};

    for (final item in dc.items) {
      final materialCode = item.materialCode.trim();
      final jobNo =
          dc.dcType == 'job_order' ? (item.jobNo?.trim() ?? '') : 'General';

      if (dc.dcType == 'job_order' && (jobNo.isEmpty || jobNo == 'General')) {
        throw Exception(
            'Select a Board / Job No with available stock for every job order item');
      }

      if (dc.dcType == 'internal' || dc.dcType == 'job_order') {
        final key = (materialCode, jobNo);
        required[key] = (required[key] ?? 0.0) + item.quantity;
      }
    }

    for (final entry in required.entries) {
      final available = stockNotifier.availableStockForJob(
        entry.key.$1,
        entry.key.$2,
      );
      if (entry.value > available + 0.0001) {
        throw Exception(
            'Insufficient available stock for ${entry.key.$1} in ${entry.key.$2}. Available: ${available.toStringAsFixed(2)}');
      }
    }
  }

  Future<void> updateDeliveryChallan(
      int index, DeliveryChallan dc, WidgetRef ref) async {
    try {
      // Get the old DC to revert stock if it was internal
      final oldDc = box.getAt(index);
      if (oldDc != null && oldDc.dcType == 'internal') {
        await _updateStockForInternalDC(oldDc, isAdd: false, ref: ref);
      }

      // Update stock for new DC if it's internal
      if (dc.dcType == 'internal') {
        await _updateStockForInternalDC(dc, isAdd: true, ref: ref);
      }

      // Update delivery challan
      await update(dc);
    } catch (e) {
      print('Error updating delivery challan: $e');
      rethrow;
    }
  }

  Future<bool> deleteDeliveryChallan(DeliveryChallan dc, WidgetRef ref) async {
    try {
      // Revert stock for internal DCs
      if (dc.dcType == 'internal') {
        await _updateStockForInternalDC(dc, isAdd: false, ref: ref);
      }

      if (dc.dcType == 'job_order') {
        final stockNotifier = ref.read(stockMaintenanceProvider.notifier);
        for (final entry in _requiredJobStock(dc).entries) {
          await stockNotifier.restoreStockToJobBucket(
            materialCode: entry.key.$1,
            jobNo: entry.key.$2,
            quantity: entry.value,
          );
        }
      }

      // Delete delivery challan
      return await delete(dc);
    } catch (e) {
      print('Error deleting delivery challan: $e');
      return false;
    }
  }

  String generateDcNo() {
    final currentYear = DateTime.now().year.toString().substring(2);
    final prefix = 'DC$currentYear';

    final existingNos = state
        .map((dc) => dc.dcNo)
        .where((no) => no.startsWith(prefix))
        .map((no) => int.tryParse(no.substring(prefix.length)) ?? 0)
        .toList();

    final nextNo = existingNos.isEmpty ? 1 : (existingNos.reduce(max) + 1);
    return '$prefix${nextNo.toString().padLeft(4, '0')}';
  }

  String generateInternalOutwardDcNo() {
    // Prefix depends on company configuration:
    // MagnetPowerTech -> 'MD', Aimant Industries -> 'AD'
    final prefix = companyCodePrefix == 'MPT' ? 'MD' : 'AD';

    // Current year (last 2 digits) + current month (2 digits), e.g. 2609
    final now = DateTime.now();
    final yearStr = now.year.toString().substring(2);
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$yearStr$monthStr';

    final fullPrefix = '$prefix$yearMonthPrefix';
    final expectedLength = fullPrefix.length + 2;

    // Find all VALID sequential order numbers for the current prefix+month
    final validSequentialOrders = state.where((order) {
      // Check if DC number matches the expected format: prefix + YYMM + 2 digits
      if (!order.dcNo.startsWith(fullPrefix) ||
          order.dcNo.length != expectedLength) {
        return false;
      }

      // Check if the last 2 characters are all digits
      final sequencePart = order.dcNo.substring(fullPrefix.length);
      return RegExp(r'^\d{2}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this month, start from 1
    if (validSequentialOrders.isEmpty) {
      return '${fullPrefix}01';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((order) {
      return int.parse(order.dcNo.substring(fullPrefix.length));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 2-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(2, '0');

    return '$fullPrefix$sequenceStr'; // e.g., MD260901, AD260901, etc.
  }

  Future<void> _updateStockForInternalDC(DeliveryChallan dc,
      {required bool isAdd, required WidgetRef ref}) async {
    print('=== Updating Stock for Internal DC (${dc.internalFlow}) ===');
    print('DC No: ${dc.dcNo}, isAdd: $isAdd');

    // For inward: increase stock (isAdd=true means add, isAdd=false means revert)
    // For outward: decrease stock (isAdd=true means subtract, isAdd=false means revert/add back)
    final isInward = dc.internalFlow == 'inward';
    final stockMultiplier = isInward ? 1.0 : -1.0;

    for (var item in dc.items) {
      print(
          'Processing item: ${item.materialCode} - Quantity: ${item.quantity}');

      final stockItems = _stockBox.values
          .where((stock) => stock.materialCode == item.materialCode)
          .toList();

      print(
          'Found ${stockItems.length} stock records for ${item.materialCode}');

      if (stockItems.isEmpty) {
        print(
            'No stock record found for ${item.materialCode}, creating new one');
        // Create new stock record if it doesn't exist
        final newStock = StockMaintenance(
          materialCode: item.materialCode,
          materialDescription: item.materialDescription,
          unit: item.unit,
          storageLocation: '',
          rackNumber: '',
          currentStock: isAdd ? item.quantity : 0.0,
        );

        // Add to General job stock
        newStock.jobDetails['General'] = StockJobDetails(
          jobNo: 'General',
          allocatedQuantity: isAdd ? item.quantity : 0.0,
          consumedQuantity: 0.0,
          prNo: '',
        );

        // Add GRN details with price/rate for stock value calculation
        final grnNo = isInward
            ? 'IDCIN-${dc.dcNo}-${item.materialCode}'
            : 'IDCOUT-${dc.dcNo}-${item.materialCode}';
        if (isAdd) {
          newStock.receiveToGeneral(
            grnNo,
            item.quantity * stockMultiplier,
            rate: item.price,
            vendorId: isInward
                ? (dc.fromVendor ?? 'internal')
                : (dc.toVendor ?? 'internal'),
          );
        }

        await _stockBox.add(newStock);

        final stockMaintenanceNotifier =
            ref.read(stockMaintenanceProvider.notifier);
        await stockMaintenanceNotifier.update(newStock);
        print('Created new stock record for ${item.materialCode}');
      } else {
        // Update existing stock record
        for (var stock in stockItems) {
          // Use unique GRN per material to avoid overwriting
          final grnNo = isInward
              ? 'IDCIN-${dc.dcNo}-${item.materialCode}'
              : 'IDCOUT-${dc.dcNo}-${item.materialCode}';
          final qty = item.quantity * stockMultiplier * (isAdd ? 1.0 : -1.0);

          print(
              'Updating stock with GRN: $grnNo, Qty: $qty, Rate: ${item.price}');

          try {
            // Update General stock with rate for value calculation
            stock.receiveToGeneral(
              grnNo,
              qty,
              rate: item.price,
              vendorId: isInward
                  ? (dc.fromVendor ?? 'internal')
                  : (dc.toVendor ?? 'internal'),
            );
            print('Updated General stock: $qty at rate ${item.price}');
          } catch (e) {
            print('Error updating stock: $e');
            // Fallback: adjust currentStock directly
            stock.currentStock += qty;
            print('Fallback: Updated current stock to: ${stock.currentStock}');
          }

          // Use BaseProvider's update method for Firestore sync
          final stockMaintenanceNotifier =
              ref.read(stockMaintenanceProvider.notifier);
          await stockMaintenanceNotifier.update(stock);
          print('Successfully updated stock for ${stock.materialCode}');
        }
      }
    }
    print('=== End Stock Update for Internal Inward DC ===');
  }

  // Helper methods
  List<DeliveryChallan> getDeliveryChallansByVendor(String vendorName) {
    return state.where((dc) => dc.vendorName == vendorName).toList();
  }

  List<DeliveryChallan> getReturnableDeliveryChallans() {
    return state.where((dc) => dc.isReturnable).toList();
  }

  List<DeliveryChallan> searchDeliveryChallans(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((dc) =>
            dc.dcNo.toLowerCase().contains(lowercaseQuery) ||
            dc.vendorName.toLowerCase().contains(lowercaseQuery) ||
            dc.items.any((item) =>
                item.materialCode.toLowerCase().contains(lowercaseQuery) ||
                item.materialDescription
                    .toLowerCase()
                    .contains(lowercaseQuery)))
        .toList();
  }

  // ============== DC NUMBER AUTO-GENERATION ==============

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

  /// Generate next DC number for new delivery challans (MDT/ADT prefix)
  /// Format: MDT/ADT + YYMM + 2-digit sequence e.g., MDT260901, ADT260902
  String generateNextDCNumber() {
    // Prefix depends on company configuration:
    // MagnetPowerTech -> 'MDT', Aimant Industries -> 'ADT'
    final prefix = companyCodePrefix == 'MPT' ? 'MDT' : 'ADT';

    // Current year (last 2 digits) + current month (2 digits), e.g. 2609
    final now = DateTime.now();
    final yearStr = now.year.toString().substring(2);
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$yearStr$monthStr';

    final fullPrefix = '$prefix$yearMonthPrefix';
    final expectedLength = fullPrefix.length + 2;

    // Find all VALID sequential order numbers for the current prefix+month
    final validSequentialOrders = state.where((order) {
      // Check if DC number matches the expected format: prefix + YYMM + 2 digits
      if (!order.dcNo.startsWith(fullPrefix) ||
          order.dcNo.length != expectedLength) {
        return false;
      }

      // Check if the last 2 characters are all digits
      final sequencePart = order.dcNo.substring(fullPrefix.length);
      return RegExp(r'^\d{2}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this month, start from 1
    if (validSequentialOrders.isEmpty) {
      return '${fullPrefix}01';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((order) {
      return int.parse(order.dcNo.substring(fullPrefix.length));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 2-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(2, '0');

    return '$fullPrefix$sequenceStr'; // e.g., MDT260901, ADT260901, etc.
  }

  /// Generate next JODC number for job order delivery challans
  /// Format: MJ/AJ + YYMM + 2-digit sequence e.g., MJ260901, AJ260902
  String generateNextJODCNumber() {
    // Prefix depends on company configuration:
    // MagnetPowerTech -> 'MJ', Aimant Industries -> 'AJ'
    final prefix = companyCodePrefix == 'MPT' ? 'MJ' : 'AJ';

    // Current year (last 2 digits) + current month (2 digits), e.g. 2609
    final now = DateTime.now();
    final yearStr = now.year.toString().substring(2);
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$yearStr$monthStr';

    final fullPrefix = '$prefix$yearMonthPrefix';
    final expectedLength = fullPrefix.length + 2;

    // Find all VALID sequential order numbers for the current prefix+month
    final validSequentialOrders = state.where((order) {
      // Check if DC number matches the expected format: prefix + YYMM + 2 digits
      if (!order.dcNo.startsWith(fullPrefix) ||
          order.dcNo.length != expectedLength) {
        return false;
      }

      // Check if the last 2 characters are all digits
      final sequencePart = order.dcNo.substring(fullPrefix.length);
      return RegExp(r'^\d{2}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this month, start from 1
    if (validSequentialOrders.isEmpty) {
      return '${fullPrefix}01';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((order) {
      return int.parse(order.dcNo.substring(fullPrefix.length));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 2-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(2, '0');

    return '$fullPrefix$sequenceStr'; // e.g., MJ260901, AJ260901, etc.
  }
}
