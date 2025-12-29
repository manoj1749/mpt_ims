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
      'items': dc.items
          .map((item) => {
                'materialCode': item.materialCode,
                'materialDescription': item.materialDescription,
                'unit': item.unit,
                'quantity': item.quantity,
                'jobNo': item.jobNo,
                'prNo': item.prNo,
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
              ))
          .toList(),
      isReturnable: map['isReturnable'] ?? false,
      note: map['note'],
      dcType: map['dcType'] ?? 'regular',
      internalFlow: map['internalFlow'] ?? 'outward',
    );
  }

  @override
  String getModelId(DeliveryChallan dc) => dc.dcNo;

  // Map old method names to new base provider methods
  Future<void> loadDeliveryChallans() => loadData();

  Future<void> addDeliveryChallan(DeliveryChallan dc, WidgetRef ref) async {
    try {
      // Update stock maintenance first
      await _updateStockForDeliveryChallan(dc, isAdd: true, ref: ref);

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
      // Get the old DC to revert quantities
      final oldDc = box.getAt(index);
      if (oldDc != null) {
        await _updateStockForDeliveryChallan(oldDc, isAdd: false, ref: ref);
      }

      // Update with new quantities
      await _updateStockForDeliveryChallan(dc, isAdd: true, ref: ref);

      // Update delivery challan
      await update(dc);
    } catch (e) {
      print('Error updating delivery challan: $e');
      rethrow;
    }
  }

  Future<bool> deleteDeliveryChallan(DeliveryChallan dc, WidgetRef ref) async {
    try {
      // Revert stock quantities
      await _updateStockForDeliveryChallan(dc, isAdd: false, ref: ref);

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

  Future<void> _updateStockForDeliveryChallan(DeliveryChallan dc,
      {required bool isAdd, required WidgetRef ref}) async {
    print('=== Updating Stock for Delivery Challan ===');
    print('DC No: ${dc.dcNo}, isAdd: $isAdd');

    for (var item in dc.items) {
      print(
          'Processing item: ${item.materialCode} - Quantity: ${item.quantity}');

      final stockItems = _stockBox.values
          .where((stock) => stock.materialCode == item.materialCode)
          .toList();

      print(
          'Found ${stockItems.length} stock records for ${item.materialCode}');

      for (var stock in stockItems) {
        final jobNo = item.jobNo ?? 'General';
        // CRITICAL FIX: When isAdd=true (creating DC), we DEDUCT stock (negative qty)
        // When isAdd=false (deleting DC), we ADD stock back (positive qty)
        final multiplier = isAdd ? -1.0 : 1.0;
        final qty = item.quantity * multiplier;

        print('Job No: $jobNo, Multiplier: $multiplier, Qty: $qty');
        print('Current job details: ${stock.jobDetails}');

        try {
          if (dc.dcType == 'internal') {
            if (dc.internalFlow == 'inward') {
              // Increase General stock via synthetic GRN (qty is already signed correctly)
              final grnNo = 'IDCIN-${dc.dcNo}';
              stock.receiveToGeneral(grnNo, qty.abs() * (isAdd ? 1.0 : -1.0));
              print('Received to General via $grnNo: ${qty.abs() * (isAdd ? 1.0 : -1.0)}');
            } else {
              // Outward: reduce stock (qty is already negative when isAdd=true)
              stock.deliverStockForJob(jobNo, dc.dcNo, qty.abs());
              print('Delivered stock outward for job $jobNo: ${qty.abs()}');
            }
          } else {
            // Regular/job order/material return flows: deduct stock when creating DC
            stock.deliverStockForJob(jobNo, dc.dcNo, qty.abs());
            print('Delivered stock for non-internal DC: ${qty.abs()}');
          }
        } catch (e) {
          print('Error updating stock: $e');
          // Fallback: adjust currentStock directly for General
          if (jobNo == 'General') {
            stock.currentStock += qty;
            print('Fallback: Updated current stock to: ${stock.currentStock}');
          } else {
            print('Fallback not applied for job-specific stock');
          }
        }

        // Use BaseProvider's update method for Firestore sync
        final stockMaintenanceNotifier =
            ref.read(stockMaintenanceProvider.notifier);
        await stockMaintenanceNotifier.update(stock);
        print('Successfully updated stock for ${stock.materialCode}');
      }
    }
    print('=== End Stock Update for Delivery Challan ===');
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
}
