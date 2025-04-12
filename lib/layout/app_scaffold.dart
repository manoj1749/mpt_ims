import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../pages/section_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  String _selectedSubsection = 'Home';
  int _expandedSectionIndex = -1;

  final List<String> sectionTitles = [
    'Home'
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
    0: [],
    1: [],
    2: [
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
    3: [
      'Employee Details',
      'Attendance Management',
      'ESI & PF Entry',
    ],
    4: [
      'Sale order Details',
      'Customer Free Issue List',
      'Sale Value Update',
    ],
    5: [
      'Material Master Creation',
      'Brought List',
    ],
    6: [
      'Bill of Material Preparation',
      'PR Creation',
      'Job Order Request',
    ],
    7: [
      'Purchase Order Creation',
    ],
    8: [
      'GR',
      'Material Issue',
      'Stock Maintenance & Display',
      'Delivery Challan',
      'Vendor Delivery Challan',
    ],
    9: [
      'Job Order Entry',
      'Assembly Work Allocation',
    ],
    10: [
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
      _expandedSectionIndex = -1; // Reset expanded section
    });
  }

  void _handleSectionExpand(int index) {
    setState(() {
      _isSidebarExpanded = true;
      _expandedSectionIndex = index;
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
            onSectionExpand: _handleSectionExpand,
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
