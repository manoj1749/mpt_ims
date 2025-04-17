import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';

Future<void> initializeHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  //  if (!Hive.isAdapterRegistered(0)) {
  Hive.registerAdapter(SupplierAdapter()); // ✅ Adapter ID = 0
  Hive.registerAdapter(MaterialItemAdapter());
  await Hive.openBox<Supplier>('suppliers');
  await Hive.openBox<MaterialItem>('materials');
  // }
}
