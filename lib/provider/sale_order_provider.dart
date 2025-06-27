import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/sale_order.dart';
import '../services/sync_service.dart';
import 'supplier_provider.dart';  // Import for syncServiceProvider

final saleOrderBoxProvider = Provider<Box<SaleOrder>>((ref) {
  throw UnimplementedError();
});

final saleOrderProvider =
    StateNotifierProvider<SaleOrderNotifier, List<SaleOrder>>(
  (ref) => SaleOrderNotifier(
    ref.watch(saleOrderBoxProvider),
    ref.watch(syncServiceProvider),
  ),
);

class SaleOrderNotifier extends StateNotifier<List<SaleOrder>> {
  final Box<SaleOrder> box;
  final SyncService _syncService;

  SaleOrderNotifier(this.box, this._syncService) : super(box.values.toList()) {
    // Listen to box changes
    box.listenable().addListener(() async {
      if (mounted) {
        state = box.values.toList();
        await _syncToFirebase();
      }
    });
  }

  @override
  void dispose() {
    box.listenable().removeListener(() async {
      if (mounted) {
        state = box.values.toList();
        await _syncToFirebase();
      }
    });
    super.dispose();
  }

  String generateOrderNumber() {
    // Get current academic year (assuming academic year starts in June)
    final now = DateTime.now();
    int academicYear = now.year;
    if (now.month < 6) {
      academicYear--; // If before June, use previous year
    }

    // Get last 2 digits of current and next year
    final currentYearStr = academicYear.toString().substring(2);
    final nextYearStr = (academicYear + 1).toString().substring(2);

    // Generate 6 random digits
    final random = Random();
    final randomDigits = List.generate(6, (_) => random.nextInt(10)).join();

    // Combine to form order number (e.g., 2425010198)
    return '$currentYearStr$nextYearStr$randomDigits';
  }

  Future<void> addOrder(SaleOrder order) async {
    try {
      print('Adding sale order: ${order.orderNo}');
      await box.add(order);
      if (mounted) {
        state = box.values.toList();
        print('Sale order added successfully, syncing to Firebase...');
        await _syncToFirebase();
        print('Sync completed');
      }
    } catch (e) {
      print('Error adding sale order: $e');
      rethrow;
    }
  }

  Future<void> updateOrder(SaleOrder order) async {
    try {
      print('Updating sale order: ${order.orderNo}');
      final index =
          box.values.toList().indexWhere((o) => o.orderNo == order.orderNo);
      if (index != -1) {
        await box.putAt(index, order);
        if (mounted) {
          state = box.values.toList();
          print('Sale order updated successfully, syncing to Firebase...');
          await _syncToFirebase();
          print('Sync completed');
        }
      }
    } catch (e) {
      print('Error updating sale order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(SaleOrder order) async {
    await order.delete();
    if (mounted) {
      state = box.values.toList();
      await _syncToFirebase();
    }
  }

  // Get orders by customer
  List<SaleOrder> getOrdersByCustomer(String customerName) {
    return state.where((order) => order.customerName == customerName).toList();
  }

  // Get orders by date range
  List<SaleOrder> getOrdersByDateRange(DateTime start, DateTime end) {
    return state.where((order) {
      final orderDate = DateFormat('yyyy-MM-dd').parse(order.orderDate);
      return orderDate.isAfter(start.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> refresh() async {
    try {
      print('Refreshing sale orders...');
      await _syncFromFirebase();
      if (mounted) {
        state = box.values.toList();
        print('Refresh completed, current sale orders: ${state.length}');
      }
    } catch (e) {
      print('Error refreshing sale orders: $e');
      rethrow;
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      print('Starting sync to Firebase...');
      print('Current sale orders in box: ${box.values.length}');
      await _syncService.syncToFirestore('saleOrders', box);
      print('Sync to Firebase completed successfully');
    } catch (e) {
      print('Error syncing sale orders to Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }

  Future<void> _syncFromFirebase() async {
    try {
      print('Starting sync from Firebase...');
      await _syncService.syncFromFirestore(
        'saleOrders',
        box,
        _syncService.saleOrderFromMap,
      );
      print('Sync from Firebase completed successfully');
    } catch (e) {
      print('Error syncing sale orders from Firebase: $e');
      // You might want to show a snackbar or some other UI feedback here
    }
  }
}
