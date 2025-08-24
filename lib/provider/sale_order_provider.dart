import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/sale_order.dart';
import 'base_provider.dart';

final saleOrderBoxProvider = Provider<Box<SaleOrder>>((ref) {
  throw UnimplementedError();
});

final saleOrderProvider =
    StateNotifierProvider<SaleOrderNotifier, List<SaleOrder>>(
  (ref) => SaleOrderNotifier(ref.watch(saleOrderBoxProvider)),
);

class SaleOrderNotifier extends BaseProvider<SaleOrder> {
  SaleOrderNotifier(Box<SaleOrder> box) : super(box, 'saleOrders');

  @override
  Map<String, dynamic> modelToMap(SaleOrder order) {
    return {
      'orderNo': order.orderNo,
      'orderDate': order.orderDate,
      'customerName': order.customerName,
      'boardNo': order.boardNo,
      'jobStartDate': order.jobStartDate,
      'targetDate': order.targetDate,
      'endDate': order.endDate,
    };
  }

  @override
  SaleOrder mapToModel(Map<String, dynamic> map) {
    return SaleOrder(
      orderNo: map['orderNo'] ?? '',
      orderDate: map['orderDate'] ?? '',
      customerName: map['customerName'] ?? '',
      boardNo: map['boardNo'] ?? '',
      jobStartDate: map['jobStartDate'] ?? '',
      targetDate: map['targetDate'] ?? '',
      endDate: map['endDate'],
    );
  }

  @override
  String getModelId(SaleOrder order) => order.orderNo;

  // Backward compatibility methods
  Future<void> loadSaleOrders() => loadData();
  Future<void> addOrder(SaleOrder order) => add(order);
  Future<void> updateOrder(SaleOrder order) => update(order);
  Future<void> updateOrderByIndex(int index, SaleOrder order) => update(order);
  Future<bool> deleteOrder(SaleOrder order) => delete(order);

  // Utility methods
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

  // Search and filter methods
  List<SaleOrder> searchOrders(String query) {
    return search(
        query,
        (order, query) =>
            order.orderNo.toLowerCase().contains(query) ||
            order.customerName.toLowerCase().contains(query) ||
            order.boardNo.toLowerCase().contains(query));
  }

  List<SaleOrder> getActiveOrders() {
    return state.where((order) => !order.isCompleted).toList();
  }

  List<SaleOrder> getCompletedOrders() {
    return state.where((order) => order.isCompleted).toList();
  }

  List<SaleOrder> getOrdersByCustomer(String customerName) {
    return state
        .where((order) =>
            order.customerName.toLowerCase() == customerName.toLowerCase())
        .toList();
  }

  SaleOrder? getOrderByNo(String orderNo) {
    try {
      return state.firstWhere((order) => order.orderNo == orderNo);
    } catch (e) {
      return null;
    }
  }

  // Date-based filtering
  List<SaleOrder> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return state.where((order) {
      try {
        final orderDate = DateFormat('dd/MM/yyyy').parse(order.orderDate);
        return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<SaleOrder> getOverdueOrders() {
    final today = DateTime.now();
    return state.where((order) {
      if (order.isCompleted) return false;
      try {
        final targetDate = DateFormat('dd/MM/yyyy').parse(order.targetDate);
        return targetDate.isBefore(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }
}
