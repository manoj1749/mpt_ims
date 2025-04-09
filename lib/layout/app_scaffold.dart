// main.dart
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedSectionIndex = 0;
  int _selectedSubIndex = 0;
  bool _isSidebarExpanded = true;

  final Map<int, List<String>> _sectionSubpages = {
    0: [
      'Supplier Details',
      'Master Material List',
      'Purchase Request (PR)',
      'PR Material List',
      'Purchase Order Entry',
      'Pending PO Material List',
    ],
    1: [
      'GR / Inward Material Entry',
      'Inward Purchase Material List',
      'Store Outward Material Entry',
      'Store Outward Material List',
      'Store Material Stock',
      'Label / Transporter Bill Entry',
      'Label List',
    ],
    2: [
      'Incoming Inspection',
      'Self Life Item',
      'Sampling Plan',
      'Approved Supplier',
      'Defects Recording Sheet',
      'Incoming Inspection Data',
    ],
    3: [
      'Vendor DC Outward Entry',
      'Vendor DC Outward List',
      'Vendor DC Inward Entry',
      'Vendor DC Inward List',
      'Schneider Material DC Outward Entry',
      'Schneider Material DC Outward List',
    ],
    4: [
      'Outward Invoice Entry',
      'Inward Invoice Details',
      'Outward Invoice Details',
      'SEIPL Job Work Material',
      'SEIPL Panel Labour Billing',
      'SEIPL Material Billing',
      'SEIPL Panel Charges',
    ],
    5: [
      'Daily Expense Entry',
      'Expense Data',
      'Employee Details',
      'Salary Entry',
      'Amount Paid to Magnet Power Tech',
    ],
  };

  void _onSectionSelected(int index) {
    setState(() {
      _selectedSectionIndex = index;
      _selectedSubIndex = 0;
    });
  }

  void _onSubItemSelected(int subIndex) {
    setState(() {
      _selectedSubIndex = subIndex;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentPage = _sectionSubpages[_selectedSectionIndex]![_selectedSubIndex];

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedSectionIndex,
            onItemSelected: _onSectionSelected,
            isExpanded: _isSidebarExpanded,
            onToggle: _toggleSidebar,
            sectionSubpages: _sectionSubpages,
            selectedSubIndex: _selectedSubIndex,
            onSubItemSelected: _onSubItemSelected,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Page: $currentPage',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}