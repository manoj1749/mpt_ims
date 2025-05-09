import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
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
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);

    // Get all orders from today
    final todayOrders = state.where((order) {
      return order.orderNo.startsWith('SO$dateStr');
    }).toList();

    // Get the next sequence number
    final nextSeq = (todayOrders.length + 1).toString().padLeft(3, '0');

    return 'SO$dateStr$nextSeq';
  }

  void addOrder(SaleOrder order) {
    box.add(order);
    state = box.values.toList();
  }

  void updateOrder(SaleOrder order) {
    order.save();
    state = box.values.toList();
  }

  void deleteOrder(SaleOrder order) {
    order.delete();
    state = box.values.toList();
  }

  // Get orders by status
  List<SaleOrder> getOrdersByStatus(String status) {
    return state.where((order) => order.status == status).toList();
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