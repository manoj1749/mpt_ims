// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class SectionPage extends StatelessWidget {
  final String title;
  final List<String> subsections;

  const SectionPage({
    super.key,
    required this.title,
    required this.subsections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: Text(title),
      ),
      body: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3.5,
        children: subsections.map((title) {
          return GestureDetector(
            onTap: () {
              // Handle tap on subsection
              print('Tapped on $title');
            },
            child: SizedBox(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
