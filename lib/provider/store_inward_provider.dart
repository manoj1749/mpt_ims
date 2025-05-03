import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  StoreInwardNotifier(this.box) : super(box.values.toList());

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

  void addInward(StoreInward inward) {
    box.add(inward);
    state = box.values.toList();
  }

  void deleteInward(StoreInward inward) {
    inward.delete();
    state = box.values.toList();
  }
}
