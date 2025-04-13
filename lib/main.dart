import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mpt_ims/db/hive_initializer.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';

import 'firebase_options.dart'; // From Firebase setup
import 'pages/login_page.dart'; // We'll create this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeHive();

  final supplierBox = await Hive.openBox<Supplier>('suppliers');

  runApp(ProviderScope(
    overrides: [
      supplierBoxProvider.overrideWithValue(supplierBox),
    ],
    child: const IMSApp(),
  ));
}

class IMSApp extends StatelessWidget {
  const IMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMS Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const LoginPage(), // start here
    );
  }
}
