// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mpt_ims/pages/accounts/category_settings_page.dart';
import 'package:mpt_ims/pages/accounts/customer_list_page.dart';
import 'package:mpt_ims/pages/accounts/state_master.dart';
import 'package:mpt_ims/pages/accounts/gst_master.dart';
import 'package:mpt_ims/pages/accounts/supplier_master.dart';
import 'package:mpt_ims/pages/accounts/service_supplier_master.dart';
import 'package:mpt_ims/pages/accounts/inventory_classification_page.dart';
import 'package:mpt_ims/pages/accounts/service_master_page.dart';
import 'package:mpt_ims/pages/design/material_master.dart';
import 'package:mpt_ims/pages/hr/employee_list_page.dart';
import 'package:mpt_ims/pages/login_page.dart';
import 'package:mpt_ims/pages/planning/purchase_request_list_page.dart';
import 'package:mpt_ims/pages/planning/bill_of_preparation_list_page.dart';
import 'package:mpt_ims/pages/section_page.dart';
import 'package:mpt_ims/pages/purchase/purchase_order_list_page.dart';
import 'package:mpt_ims/pages/store/store_inward_list_page.dart';
import 'package:mpt_ims/pages/store/stock_maintenance_page.dart';
import 'package:mpt_ims/pages/store/customer_scope_stock_maintenance_page.dart';
import 'package:mpt_ims/pages/store/customer_scope_gr_list_page.dart';
import 'package:mpt_ims/pages/store/customer_scope_issue_list_page.dart';
import 'package:mpt_ims/pages/store/stock_transfer_page.dart';
import 'package:mpt_ims/pages/quality/customer_scope_incoming_inspection_list_page.dart';
import 'package:mpt_ims/pages/store/material_request_list_page.dart';
import 'package:mpt_ims/pages/quality/quality_inspection_list_page.dart';
import 'package:mpt_ims/pages/quality/capa_status_page.dart';
import 'package:mpt_ims/pages/quality/quality_category_settings_page.dart';
import 'package:mpt_ims/pages/sales/customer_scope_material_issue_master_page.dart';
import 'package:mpt_ims/pages/planning/customer_free_issue_list_page.dart';
import 'package:mpt_ims/pages/sales/sale_order_list_page.dart';
import 'package:mpt_ims/pages/store/material_issue_list_page.dart';
import 'package:mpt_ims/pages/store/delivery_challan_list_page.dart';
import 'package:mpt_ims/pages/store/internal_delivery_challan_list_page.dart';
import 'package:mpt_ims/pages/store/job_order_delivery_challan_list_page.dart';
import 'package:mpt_ims/pages/store/material_return_delivery_challan_list_page.dart';
import 'package:mpt_ims/pages/store/invoice_generation_page.dart';
import 'package:mpt_ims/pages/store/internal_inward_delivery_challan_list_page.dart';
import '../widgets/sync_status_widget.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int? _selectedSectionIndex;
  int? _selectedSubsectionIndex;
  String _selectedPage = 'Dashboard';

  // Company configuration - comment/uncomment to switch between companies
  static const bool useMagnetPowerTech = true; // Set to false for Aimant Industries

  // Company configurations
  static const Map<String, String> magnetPowerTech = {
    'logo': 'assets/logo.jpeg',
    'name': 'Magnet Power Tech IMS Dashboard',
  };

  static const Map<String, String> aimantIndustries = {
    'logo': 'assets/aimant_logo.jpg',
    'name': 'Aimant Industries IMS Dashboard',
  };

  // Get current company configuration
  Map<String, String> get currentCompany =>
      useMagnetPowerTech ? magnetPowerTech : aimantIndustries;

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
    'Internal Delivery Challan',
    'Stocks',
  ];

  final Map<int, List<String>> _sectionSubpages = {
    0: [],
    1: [],
    2: [
      'Invoice receipt',
      'Invoice Generation',
      'Master Data',
      'Bank statement entry',
      "Expense's entry",
      "Payment's entry",
      'Salary & Wages entry',
      'Sales entry',
    ],
    3: [
      'Employee Details',
      'Attendance Management',
      'ESI & PF Entry',
    ],
    4: [
      'Sale order Details',
      'Sale Value Update',
    ],
    5: [
      'Material Master Creation',
      'Brought List',
      'Category Settings',
      'Inventory Classification',
      'Customer Scope Material Issue Master',
    ],
    6: [
      'Bill of Material Preparation',
      'PR Creation',
      'Job Order Request',
      'Customer Free Issue List',
    ],
    7: [
      'Purchase Order Creation',
    ],
    8: [
      'GR',
      'Purchased Material Request',
      'Purchased Material Issue',
      'Stock Transfer',
      'Customer Scope GR',
      'Customer Scope Issue',
      'Delivery Challan',
      'Job Order Delivery Challan',
      'Material Return Delivery Challan',
    ],
    9: [
      'Job Order Entry',
      'Assembly Work Allocation',
    ],
    10: [
      'Incoming Inspection',
      'Customer Scope Incoming Inspection',
      'Category Settings (Quality)',
      'Final Inspection',
      'CAPA Status',
    ],
    11: [
      'Outward Delivery Challan',
      'Inward Delivery Challan',
    ],
    12: [
      'Stock Maintenance & Display',
      'Customer Scope Stock Maintenance',
    ],
  };

  void _onSectionSelected(int index) {
    setState(() {
      _selectedSectionIndex = index;
    });
  }

  Widget _buildPageForSubsection(String name) {
    switch (name) {
      case 'Master Data':
        return _MasterDataMenuPage(
          onItemSelected: (selected) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _buildPageForSubsection(selected),
              ),
            );
          },
        );
      case 'Supplier Master':
        return const SupplierMasterPage();
      case 'Service Supplier Master':
        return const ServiceSupplierMasterPage();
      case 'Service Category Master':
        return const ServiceMasterPage();
      case 'Category Settings':
        return const CategorySettingsPage();
      case 'Category Settings (Quality)':
        return const QualityCategorySettingsPage();
      case 'Inventory Classification':
        return const InventoryClassificationPage();
      case 'Material Master Creation':
        return const MaterialMasterPage();
      case 'PR Creation':
        return const PurchaseRequestListPage();
      case 'Bill of Material Preparation':
        return const BillOfPreparationListPage();
      case 'Customer Free Issue List':
        return const CustomerFreeIssueListPage();
      case 'Purchase Order Creation':
        return const PurchaseOrderListPage();
      case 'Employee Details':
        return EmployeeListPage();
      case 'Customer Master':
        return const CustomerListPage();
      case 'State Master':
        return const StateMasterPage();
      case 'GST Master':
        return const GSTMasterPage();
      case 'GR':
        return const StoreInwardListPage();
      case 'Customer Scope GR':
        return const CustomerScopeGRListPage();
      case 'Purchased Material Request':
        return const MaterialRequestListPage();
      case 'Purchased Material Issue':
        return const MaterialIssueListPage();
      case 'Customer Scope Issue':
        return const CustomerScopeIssueListPage();
      case 'Incoming Inspection':
        return const QualityInspectionListPage();
      case 'Customer Scope Incoming Inspection':
        return const CustomerScopeIncomingInspectionListPage();
      case 'CAPA Status':
        return const CapaStatusPage();
      case 'Sale order Details':
        return const SaleOrderListPage();
      case 'Stock Maintenance & Display':
        return const StockMaintenancePage();
      case 'Stock Transfer':
        return const StockTransferHomePage();
      case 'Customer Scope Stock Maintenance':
        return const CustomerScopeStockMaintenancePage();
      case 'Delivery Challan':
        return const DeliveryChallanListPage();
      case 'Internal Delivery Challan':
        return const InternalDeliveryChallanListPage();
      case 'Outward Delivery Challan':
        return const InternalDeliveryChallanListPage();
      case 'Inward Delivery Challan':
        return const InternalInwardDeliveryChallanListPage();
      case 'Job Order Delivery Challan':
        return const JobOrderDeliveryChallanListPage();
      case 'Material Return Delivery Challan':
        return const MaterialReturnDeliveryChallanListPage();
      case 'Invoice Generation':
        return const InvoiceGenerationPage();
      case 'Customer Scope Material Issue Master':
        return const CustomerScopeMaterialIssueMasterPage();
      default:
        return SectionPage(title: name);
    }
  }

  void _onSubsectionSelected(String name) {
    final page = _buildPageForSubsection(name);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              currentCompany['logo']!,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedSectionIndex == null
                  ? currentCompany['name']!
                  : sectionTitles[_selectedSectionIndex!],
            ),
          ],
        ),
        actions: [
          const SyncStatusWidget(),
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
                          fontSize: 20,
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

class _MasterDataMenuPage extends StatelessWidget {
  final ValueChanged<String> onItemSelected;
  const _MasterDataMenuPage({required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      'Supplier Master',
      'Customer Master',
      'Service Supplier Master',
      'Service Category Master',
      'State Master',
      'GST Master',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Master Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: items
              .map(
                (title) => GestureDetector(
                  onTap: () => onItemSelected(title),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
