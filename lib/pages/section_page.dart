import 'package:flutter/material.dart';

class SectionPage extends StatelessWidget {
  final String title;

  const SectionPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
