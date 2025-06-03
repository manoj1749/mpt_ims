import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/store_inward.dart';
import 'package:intl/intl.dart';

final storeInwardBoxProvider = Provider<Box<StoreInward>>((ref) {
  throw UnimplementedError();
});

final storeInwardProvider =
    StateNotifierProvider<StoreInwardNotifier, List<StoreInward>>((ref) {
  final box = ref.watch(storeInwardBoxProvider);
  return StoreInwardNotifier(box);
});

class StoreInwardNotifier extends StateNotifier<List<StoreInward>> {
  final Box<StoreInward> box;

  StoreInwardNotifier(this.box) : super(box.values.toList()) {
    // Listen to box changes
    box.listenable().addListener(_updateState);
  }

  @override
  void dispose() {
    box.listenable().removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      state = box.values.toList();
    }
  }

  String generateGRNNumber() {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);

    // Get all GRNs from today
    final todayGRNs = state.where((inward) {
      return inward.grnNo.startsWith('GRN$dateStr');
    }).toList();

    // Get the next sequence number
    final nextSeq = (todayGRNs.length + 1).toString().padLeft(3, '0');

    return 'GRN$dateStr$nextSeq';
  }

  Future<void> addInward(StoreInward inward) async {
    await box.add(inward);
    state = box.values.toList();
  }

  Future<void> updateInward(int index, StoreInward inward) async {
    await box.putAt(index, inward);
    state = box.values.toList();
  }

  Future<void> deleteInward(StoreInward inward) async {
    await inward.delete();
    state = box.values.toList();
  }

  // Get inwards by supplier
  List<StoreInward> getInwardsBySupplier(String supplierName) {
    return state
        .where((inward) => inward.supplierName == supplierName)
        .toList();
  }

  // Get inwards by date range
  List<StoreInward> getInwardsByDateRange(DateTime start, DateTime end) {
    return state.where((inward) {
      final inwardDate = DateFormat('yyyy-MM-dd').parse(inward.grnDate);
      return inwardDate.isAfter(start.subtract(const Duration(days: 1))) &&
          inwardDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get inwards by material code
  List<StoreInward> getInwardsByMaterial(String materialCode) {
    return state
        .where((inward) =>
            inward.items.any((item) => item.materialCode == materialCode))
        .toList();
  }

  // Get total received quantity for a material from a specific PO
  double getTotalReceivedQuantity(String materialCode, String poNo) {
    return state
        .where((inward) => inward.items.any((item) =>
            item.materialCode == materialCode &&
            item.prQuantities.containsKey(poNo)))
        .fold(0.0, (sum, inward) {
      final item =
          inward.items.firstWhere((item) => item.materialCode == materialCode);
      return sum + item.getTotalQuantityForPO(poNo);
    });
  }

  // Get total received quantity for a specific PR
  double getTotalReceivedQuantityForPR(
      String materialCode, String poNo, String prNo) {
    return state
        .where((inward) => inward.items.any((item) =>
            item.materialCode == materialCode &&
            item.prQuantities.containsKey(poNo) &&
            item.prQuantities[poNo]?.containsKey(prNo) == true))
        .fold(0.0, (sum, inward) {
      final item =
          inward.items.firstWhere((item) => item.materialCode == materialCode);
      return sum + (item.prQuantities[poNo]?[prNo] ?? 0.0);
    });
  }

  // Get total received quantity for a PO
  double getTotalReceivedQuantityForPO(String materialCode, String poNo) {
    return state
        .where((inward) => inward.items.any((item) =>
            item.materialCode == materialCode &&
            item.prQuantities.containsKey(poNo)))
        .fold(0.0, (sum, inward) {
      final item =
          inward.items.firstWhere((item) => item.materialCode == materialCode);
      return sum +
          item.prQuantities[poNo]!.values.fold(0.0, (sum, qty) => sum + qty);
    });
  }
}
