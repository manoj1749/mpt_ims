// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/delivery_challan.dart';
import '../models/stock_maintenance.dart';
import 'base_provider.dart';
import 'stock_maintenance_provider.dart';

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
      // Update stock for internal DCs (both inward and outward)
      if (dc.dcType == 'internal') {
        await _updateStockForInternalDC(dc, isAdd: true, ref: ref);
      }

      // Add delivery challan
      await add(dc);
    } catch (e) {
      print('Error adding delivery challan: $e');
      rethrow;
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
    // Get financial year (April to March)
    final now = DateTime.now();
    final currentYear = now.year;
    final financialYear = now.month >= 4 
        ? '${currentYear.toString().substring(2)}${(currentYear + 1).toString().substring(2)}'
        : '${(currentYear - 1).toString().substring(2)}${currentYear.toString().substring(2)}';
    
    final prefix = 'MPTDC$financialYear';

    final existingNos = state
        .map((dc) => dc.dcNo)
        .where((no) => no.startsWith(prefix))
        .map((no) => int.tryParse(no.substring(prefix.length)) ?? 0)
        .toList();

    final nextNo = existingNos.isEmpty ? 1 : (existingNos.reduce(max) + 1);
    return '$prefix${nextNo.toString().padLeft(4, '0')}';
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
            vendorId: isInward ? (dc.fromVendor ?? 'internal') : (dc.toVendor ?? 'internal'),
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

          print('Updating stock with GRN: $grnNo, Qty: $qty, Rate: ${item.price}');

          try {
            // Update General stock with rate for value calculation
            stock.receiveToGeneral(
              grnNo,
              qty,
              rate: item.price,
              vendorId: isInward ? (dc.fromVendor ?? 'internal') : (dc.toVendor ?? 'internal'),
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

  /// Generate next DC number for new delivery challans (DC prefix)
  /// Format: DC{FY}{6-digit-sequence} e.g., DC2026000001
  String generateNextDCNumber() {
    final financialYear = getCurrentFinancialYear();
    final prefix = 'DC$financialYear';
    
    // Get all DCs with the same prefix and financial year
    final existingDCs = state.where((dc) => 
      dc.dcNo.startsWith(prefix) && dc.dcType != 'job_order'
    ).toList();
    
    if (existingDCs.isEmpty) {
      return '${prefix}000001';
    }
    
    // Extract sequence numbers and find max
    int maxSequence = 0;
    for (final dc in existingDCs) {
      final sequenceStr = dc.dcNo.substring(prefix.length);
      final sequence = int.tryParse(sequenceStr) ?? 0;
      if (sequence > maxSequence) {
        maxSequence = sequence;
      }
    }
    
    // Generate next sequence with 6 digits padding
    final nextSequence = maxSequence + 1;
    return '$prefix${nextSequence.toString().padLeft(6, '0')}';
  }

  /// Generate next JODC number for job order delivery challans
  /// Format: JODC{FY}{6-digit-sequence} e.g., JODC2026000001
  String generateNextJODCNumber() {
    final financialYear = getCurrentFinancialYear();
    final prefix = 'JODC$financialYear';
    
    // Get all job order DCs with the same prefix and financial year
    final existingDCs = state.where((dc) => 
      dc.dcNo.startsWith(prefix) && dc.dcType == 'job_order'
    ).toList();
    
    if (existingDCs.isEmpty) {
      return '${prefix}000001';
    }
    
    // Extract sequence numbers and find max
    int maxSequence = 0;
    for (final dc in existingDCs) {
      final sequenceStr = dc.dcNo.substring(prefix.length);
      final sequence = int.tryParse(sequenceStr) ?? 0;
      if (sequence > maxSequence) {
        maxSequence = sequence;
      }
    }
    
    // Generate next sequence with 6 digits padding
    final nextSequence = maxSequence + 1;
    return '$prefix${nextSequence.toString().padLeft(6, '0')}';
  }
}
