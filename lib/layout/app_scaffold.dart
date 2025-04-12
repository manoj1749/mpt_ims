import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../pages/section_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  String _selectedSubsection = '';

  final List<String> sectionTitles = [
    'Admin',
    'Accounts',
    'HR',
    'Sales / Customer Management',
    'Design',
    'Planning',
    'Purchase',
    'Stores',
    'Production',
    'Quality',
  ];

  final Map<int, List<String>> _sectionSubpages = {
    0: [], // Admin (no subsections listed)

    1: [
      'Invoice receipt',
      'Supplier Master',
      'Customer Master',
      'Bank statement entry',
      'Expense’s entry',
      'Payment’s entry',
      'Salary & Wages entry',
      'Sales entry',
      'GST entry',
    ],

    2: [
      'Employee Details',
      'Attendance Management',
      'ESI & PF Entry',
    ],

    3: [
      'Sale order Details',
      'Customer Free Issue List',
      'Sale Value Update',
    ],

    4: [
      'Material Master Creation',
      'Brought List',
    ],

    5: [
      'Bill of Material Preparation',
      'PR Creation',
      'Job Order Request',
    ],

    6: [
      'Purchase Order Creation',
    ],

    7: [
      'GR',
      'Material Issue',
      'Stock Maintenance & Display',
      'Delivery Challan',
      'Vendor Delivery Challan',
    ],

    8: [
      'Job Order Entry',
      'Assembly Work Allocation',
    ],

    9: [
      'Incoming Inspection',
      'Final Inspection',
    ],
  };

  void _onSubsectionSelected(String subsection) {
    setState(() {
      _selectedSubsection = subsection;
    });
  }

  bool _isSidebarExpanded = true;
  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isExpanded: _isSidebarExpanded,
            sectionSubpages: _sectionSubpages,
            selectedSubsection: _selectedSubsection,
            onSubsectionSelected: _onSubsectionSelected,
            onToggle: _toggleSidebar,
          ),
          Expanded(
            child: SectionPage(
              title: _selectedSubsection,
            ),
          ),
        ],
      ),
    );
  }
}
