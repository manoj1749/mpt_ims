import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/store_inward.dart';

final storeInwardBoxProvider = Provider<Box<StoreInward>>((ref) {
  throw UnimplementedError();
});

final storeInwardProvider = StateNotifierProvider<StoreInwardNotifier, List<StoreInward>>((ref) {
  final box = ref.watch(storeInwardBoxProvider);
  return StoreInwardNotifier(box);
});

class StoreInwardNotifier extends StateNotifier<List<StoreInward>> {
  final Box<StoreInward> box;

  StoreInwardNotifier(this.box) : super(box.values.toList());

  void addInward(StoreInward inward) {
    box.add(inward);
    state = box.values.toList();
  }

  void deleteInward(StoreInward inward) {
    inward.delete();
    state = box.values.toList();
  }
}
