import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/sale_order.dart';

final saleOrderBoxProvider = Provider<Box<SaleOrder>>((ref) {
  throw UnimplementedError();
});

final saleOrderProvider =
    StateNotifierProvider<SaleOrderNotifier, List<SaleOrder>>(
  (ref) => SaleOrderNotifier(ref.watch(saleOrderBoxProvider)),
);

class SaleOrderNotifier extends StateNotifier<List<SaleOrder>> {
  final Box<SaleOrder> box;

  SaleOrderNotifier(this.box) : super(box.values.toList());

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

  void addOrder(SaleOrder order) {
    box.add(order);
    state = box.values.toList();
  }

  void updateOrder(SaleOrder order) {
    final index = state.indexWhere((o) => o.orderNo == order.orderNo);
    if (index != -1) {
      box.putAt(index, order);
      state = box.values.toList();
    }
  }

  void deleteOrder(SaleOrder order) {
    order.delete();
    state = box.values.toList();
  }

  // Get orders by customer
  List<SaleOrder> getOrdersByCustomer(String customerName) {
    return state
        .where((order) => order.customerName == customerName)
        .toList();
  }

  // Get orders by date range
  List<SaleOrder> getOrdersByDateRange(DateTime start, DateTime end) {
    return state.where((order) {
      final orderDate = DateFormat('yyyy-MM-dd').parse(order.orderDate);
      return orderDate.isAfter(start.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
} 