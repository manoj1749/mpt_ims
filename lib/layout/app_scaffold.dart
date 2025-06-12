// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mpt_ims/pages/accounts/category_settings_page.dart';
import 'package:mpt_ims/pages/accounts/customer_list_page.dart';
import 'package:mpt_ims/pages/accounts/supplier_master.dart';
import 'package:mpt_ims/pages/design/material_master.dart';
import 'package:mpt_ims/pages/hr/employee_list_page.dart';
import 'package:mpt_ims/pages/login_page.dart';
import 'package:mpt_ims/pages/planning/purchase_request_list_page.dart';
import 'package:mpt_ims/pages/section_page.dart';
import 'package:mpt_ims/pages/purchase/purchase_order_list_page.dart';
import 'package:mpt_ims/pages/store/stock_details_page.dart';
import 'package:mpt_ims/pages/store/store_inward_list_page.dart';
import 'package:mpt_ims/pages/quality/quality_inspection_list_page.dart';
import 'package:mpt_ims/pages/quality/capa_status_page.dart';
import 'package:mpt_ims/pages/sales/sale_order_list_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int? _selectedSectionIndex;

  final List<String> sectionTitles = [
    'Home',
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
      'Category Settings',
      'Bank statement entry',
      "Expense's entry",
      "Payment's entry",
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
      'CAPA Status',
    ],
  };

  void _onSectionSelected(int index) {
    setState(() {
      _selectedSectionIndex = index;
    });
  }

  void _onSubsectionSelected(String name) {
    Widget page;
    switch (name) {
      case 'Supplier Master':
        page = const SupplierMasterPage();
        break;
      case 'Category Settings':
        page = const CategorySettingsPage();
        break;
      case 'Material Master Creation':
        page = const MaterialMasterPage();
        break;
      case 'PR Creation':
        page = const PurchaseRequestListPage();
        break;
      case 'Purchase Order Creation':
        page = const PurchaseOrderListPage();
        break;
      case 'Employee Details':
        page = EmployeeListPage();
        break;
      case 'Customer Master':
        page = const CustomerListPage();
        break;
      case 'GR':
        page = const StoreInwardListPage();
        break;
      case 'Incoming Inspection':
        page = const QualityInspectionListPage();
        break;
      case 'CAPA Status':
        page = const CapaStatusPage();
        break;
      case 'Sale order Details':
        page = const SaleOrderListPage();
        break;
      case 'Stock Maintenance & Display':
        page = const StockDetailsPage();
        break;
      default:
        page = SectionPage(title: name);
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedSectionIndex == null
              ? 'IMS Dashboard'
              : sectionTitles[_selectedSectionIndex!],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          )
        ],
        leading: _selectedSectionIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _selectedSectionIndex = null);
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: (_selectedSectionIndex == null
                  ? List.generate(
                      sectionTitles.length,
                      (i) => {
                            'title': sectionTitles[i],
                            'hasSub': _sectionSubpages[i]?.isNotEmpty ?? false,
                            'index': i,
                          })
                  : (_sectionSubpages[_selectedSectionIndex!] ?? [])
                      .map((sub) => {
                            'title': sub,
                            'hasSub': false,
                          }))
              .map((entry) => GestureDetector(
                    onTap: () {
                      if (entry['hasSub'] == true) {
                        _onSectionSelected(entry['index'] as int);
                      } else {
                        _onSubsectionSelected(entry['title'] as String);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
