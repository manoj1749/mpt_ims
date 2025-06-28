import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SaleOrderNotifier(this.box, this._syncService) : super(box.values.toList()) {
    // Listen to box changes
    box.listenable().addListener(() {
      if (mounted) {
        state = box.values.toList();
      }
    });
  }

  @override
  void dispose() {
    box.listenable().removeListener(() {
      if (mounted) {
        state = box.values.toList();
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

  // Load sale orders when entering the sale orders page
  Future<void> loadSaleOrders() async {
    try {
      print('Loading sale orders from Firestore...');
      final querySnapshot = await _firestore.collection('saleOrders').get();
      print('Found ${querySnapshot.docs.length} sale orders in Firestore');

      // Clear existing sale orders from Hive
      await box.clear();

      // Add new sale orders to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final saleOrder = _syncService.saleOrderFromMap(data);
        await box.add(saleOrder);
      }

      // Update state
      if (mounted) {
        state = box.values.toList();
      }
      print('Successfully loaded sale orders');
    } catch (e) {
      print('Error loading sale orders: $e');
      rethrow;
    }
  }

  Future<void> addOrder(SaleOrder order) async {
    try {
      print('Adding sale order: ${order.orderNo}');
      
      // Add to Firestore first
      final docRef = _firestore.collection('saleOrders').doc();
      final data = _convertToMap(order);
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
      await docRef.set(data);

      // Then add to Hive
      await box.add(order);
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Sale order added successfully');
    } catch (e) {
      print('Error adding sale order: $e');
      rethrow;
    }
  }

  Future<void> updateOrder(SaleOrder order) async {
    try {
      print('Updating sale order: ${order.orderNo}');

      // Update in Firestore first
      final querySnapshot = await _firestore
          .collection('saleOrders')
          .where('orderNo', isEqualTo: order.orderNo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        final data = _convertToMap(order);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        await docRef.update(data);
      }

      // Then update in Hive
      final index = box.values.toList().indexWhere((o) => o.orderNo == order.orderNo);
      if (index != -1) {
        await box.putAt(index, order);
        if (mounted) {
          state = box.values.toList();
        }
      }
      print('Sale order updated successfully');
    } catch (e) {
      print('Error updating sale order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(SaleOrder order) async {
    try {
      print('Deleting sale order: ${order.orderNo}');

      // Delete from Firestore first
      final querySnapshot = await _firestore
          .collection('saleOrders')
          .where('orderNo', isEqualTo: order.orderNo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      // Then delete from Hive
      await order.delete();
      
      if (mounted) {
        state = box.values.toList();
      }
      print('Sale order deleted successfully');
    } catch (e) {
      print('Error deleting sale order: $e');
      rethrow;
    }
  }

  // Helper method to convert SaleOrder to Map
  Map<String, dynamic> _convertToMap(SaleOrder order) {
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
}
