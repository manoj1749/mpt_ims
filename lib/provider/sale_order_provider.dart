import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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
      'jobNo': order.jobNo,
      'planningStartDate': order.planningStartDate,
      'planningEndDate': order.planningEndDate,
      'actualStartDate': order.actualStartDate,
      'customerRequirementDate': order.customerRequirementDate,
      'customerCommitmentDate': order.customerCommitmentDate,
      'actualCustomerDeliveryDate': order.actualCustomerDeliveryDate,
      'jobStatus': order.jobStatus,
      'jobNotes': order.jobNotes,
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
      jobNo: map['jobNo'] ?? '',
      planningStartDate: map['planningStartDate'],
      planningEndDate: map['planningEndDate'],
      actualStartDate: map['actualStartDate'],
      customerRequirementDate: map['customerRequirementDate'],
      customerCommitmentDate: map['customerCommitmentDate'],
      actualCustomerDeliveryDate: map['actualCustomerDeliveryDate'],
      jobStatus: map['jobStatus'],
      jobNotes: map['jobNotes'],
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

    // Find all VALID sequential order numbers for the current financial year
    final validSequentialOrders = state.where((order) {
      // Check if order number matches the expected format: YYYY + 6 digits
      if (!order.orderNo.startsWith(yearPrefix) || order.orderNo.length != 10) {
        return false;
      }

      // Check if the last 6 characters are all digits
      final sequencePart = order.orderNo.substring(4);
      return RegExp(r'^\d{6}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential orders exist for this financial year, start from 1
    if (validSequentialOrders.isEmpty) {
      return '${yearPrefix}000001';
    }

    // Extract and parse sequence numbers from valid orders only
    final sequenceNumbers = validSequentialOrders.map((order) {
      return int.parse(order.orderNo.substring(4));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 6-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(6, '0');

    return '$yearPrefix$sequenceStr'; // e.g., 2526000001, 2526000002, etc.
  }

  String generateJobNumber() {
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
    final yearPrefix =
        'JN$currentYearStr$nextYearStr'; // JN prefix for Job number

    // Find all VALID sequential job numbers for the current financial year
    final validSequentialJobs = state.where((order) {
      // Check if job number matches the expected format: JYY + 5 digits
      if (!order.jobNo.startsWith(yearPrefix) || order.jobNo.length != 8) {
        return false;
      }

      // Check if the last 5 characters are all digits
      final sequencePart = order.jobNo.substring(3);
      return RegExp(r'^\d{5}$').hasMatch(sequencePart);
    }).toList();

    // If no valid sequential jobs exist for this financial year, start from 1
    if (validSequentialJobs.isEmpty) {
      return '${yearPrefix}00001';
    }

    // Extract and parse sequence numbers from valid jobs only
    final sequenceNumbers = validSequentialJobs.map((order) {
      return int.parse(order.jobNo.substring(3));
    }).toList();

    // Find the highest sequence number and increment by 1
    final nextSequence = sequenceNumbers.reduce((a, b) => a > b ? a : b) + 1;

    // Format as 5-digit number with leading zeros
    final sequenceStr = nextSequence.toString().padLeft(5, '0');

    return '$yearPrefix$sequenceStr'; // e.g., J25260001, J25260002, etc.
  }

  // Search and filter methods
  List<SaleOrder> searchOrders(String query) {
    final searchTerm = query.toLowerCase();
    return state
        .where((order) =>
            order.orderNo.toLowerCase().contains(searchTerm) ||
            order.customerName.toLowerCase().contains(searchTerm) ||
            order.boardNo.toLowerCase().contains(searchTerm))
        .toList();
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
