// main.dart
import 'package:flutter/material.dart';
import 'layout/app_scaffold.dart';

void main() {
  runApp(const IMSApp());
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
      home: const AppScaffold(),
    );
  }
}
