// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unused_local_variable

import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../models/pr_item.dart';
import '../../models/po_item.dart';
import '../../models/purchase_order.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/stock_maintenance_provider.dart';

import 'package:collection/collection.dart';
import '../store/select_jobs_dialog.dart';
import '../../services/pdf_service.dart';
import '../store/stock_transfer_page.dart';

class AddPurchaseOrderPage extends ConsumerStatefulWidget {
  final PurchaseOrder? existingPO;
  final int? index;
  final String? foreClosedPONo;

  const AddPurchaseOrderPage({
    super.key,
    this.existingPO,
    this.index,
    this.foreClosedPONo,
  });

  @override
  ConsumerState<AddPurchaseOrderPage> createState() =>
      _AddPurchaseOrderPageState();
}

class _LeadingZeroDecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    String? normalized;
    if (text.startsWith('.')) {
      normalized = '0$text';
    } else if (text.startsWith('-.')) {
      normalized = text.replaceFirst('-.', '-0.');
    }

    if (normalized == null || normalized == text) {
      return newValue;
    }

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }
}

class _AddPurchaseOrderPageState extends ConsumerState<AddPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? selectedSupplier;
  List<String> selectedJobs = ['All'];
  List<POItem> poItems = [];
  final Map<String, Map<String, TextEditingController>> qtyControllers = {};
  final Map<String, Map<String, TextEditingController>> maxQtyControllers = {};
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _deliveryRequirementsController =
      TextEditingController();
  final TextEditingController _termsAndConditionsController =
      TextEditingController();

  bool _showL1 = true;
  bool _showL2 = true;
  bool _showL3 = true;
  Map<String, Map<String, TextEditingController>> prQtyControllers = {};

  String _getPriceLevel(MaterialItem material) {
    final rates = material.vendorRates
        .where((r) => double.tryParse(r.purchaseRate) != null)
        .toList();

    if (rates.isEmpty || selectedSupplier == null) {
      return 'L2';
    }

    rates.sort((a, b) =>
        double.parse(a.purchaseRate).compareTo(double.parse(b.purchaseRate)));

    final selectedRate = rates.firstWhere(
      (r) => r.vendorId == selectedSupplier!.name,
      orElse: () => rates.first,
    );

    final lowestPrice = double.parse(rates.first.purchaseRate);
    final highestPrice = double.parse(rates.last.purchaseRate);

    final existingPOItem = widget.existingPO?.items
        .firstWhereOrNull((i) => i.materialCode == material.partNo);
    final selectedPrice = existingPOItem != null
        ? double.tryParse(existingPOItem.costPerUnit) ??
            double.parse(selectedRate.purchaseRate)
        : double.parse(selectedRate.purchaseRate);

    const eps = 0.0001;
    final isLowest = (selectedPrice - lowestPrice).abs() <= eps;
    final isHighest = (selectedPrice - highestPrice).abs() <= eps &&
        selectedPrice > lowestPrice;

    if (isLowest) return 'L1';
    if (isHighest) return 'L3';
    return 'L2';
  }

  // Track per-line price edits for amendment
  final Map<String, TextEditingController> priceControllers = {};

  // Track selected PRs with a map of materialCode -> Map of prNo -> bool
  Map<String, Map<String, bool>> selectedPRs = {};

  // Store Job Numbers from PRs
  Set<String> jobNumbers = {};

  // Store materials with their PR items
  Map<String, List<PRItem>> materialPRItems = {};

  // Track visibility of General Stock row per material
  Map<String, bool> showGeneralStock = {};
  
  // Supplier search controller
  final TextEditingController _supplierSearchController = TextEditingController();

  String? _poNo;

  bool _isRefreshing = false;

  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });

    try {
      await ref.read(supplierListProvider.notifier).loadSuppliers();
      await ref.read(materialListProvider.notifier).loadMaterials();
      await ref.read(purchaseRequestListProvider.notifier).loadPurchaseRequests();
      await ref.read(stockMaintenanceProvider.notifier).loadStock();

      // Rebind selected supplier to refreshed list (instances may change)
      if (selectedSupplier != null) {
        final suppliers = ref.read(supplierListProvider);
        final prev = selectedSupplier!;
        selectedSupplier = suppliers.firstWhereOrNull(
          (s) => s.vendorCode == prev.vendorCode || s.name == prev.name,
        );
      }

      _updateMaterialPRItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Get unique job numbers from PRs
  Set<String> _getUniqueJobNumbers() {
    final Set<String> jobNos = {'All'}; // Include 'All' as default option
    final purchaseRequests = ref
        .read(purchaseRequestListProvider)
        .where((pr) => pr.status != 'Completed')
        .toList();

    for (var pr in purchaseRequests) {
      if (pr.jobNo != null && pr.jobNo!.isNotEmpty) {
        jobNos.add(pr.jobNo!);
      }
    }
    jobNos.add('General'); // Add General option
    return jobNos;
  }

  @override
  // Store a deep copy of the original PO to prevent it from being mutated by provider updates
  PurchaseOrder? _originalPO;

  @override
  void initState() {
    super.initState();
    if (widget.existingPO != null) {
      _poNo = widget.existingPO!.poNo;
      // Create a deep copy of the existing PO to preserve original values for amendment tracking
      _originalPO = widget.existingPO!.copyWith(
        items: widget.existingPO!.items.map((item) => item.copyWith()).toList(),
      );
      
      selectedSupplier = ref
          .read(supplierListProvider)
          .firstWhereOrNull((s) => s.name == widget.existingPO!.supplierName);
      _transportController.text = widget.existingPO!.transport;
      _deliveryRequirementsController.text =
          widget.existingPO!.deliveryRequirements;

      final existingTerms = widget.existingPO!.items
          .map((i) => (i.termsAndConditions ?? '').trim())
          .firstWhere((t) => t.isNotEmpty, orElse: () => '');
      _termsAndConditionsController.text = existingTerms;

      // Get all PRs and PR items for populating materialPRItems
      final allPRs = ref.read(purchaseRequestListProvider);

      // Initialize PR quantities and selected PRs from existing PO items
      for (var item in widget.existingPO!.items) {
        selectedPRs[item.materialCode] = {};
        prQtyControllers[item.materialCode] = {};

        // Populate materialPRItems with PR items from the existing PO
        materialPRItems[item.materialCode] = [];

        for (var detail in item.prDetails.entries) {
          selectedPRs[item.materialCode]![detail.key] =
              detail.value.quantity > 0;
          prQtyControllers[item.materialCode]![detail.key] =
              TextEditingController(text: detail.value.quantity.toString());

          // Find the corresponding PR item and add it to materialPRItems
          if (detail.key != 'General') {
            final pr = allPRs.firstWhereOrNull((pr) => pr.prNo == detail.value.prNo);
            if (pr != null) {
              final prItem = pr.items.firstWhereOrNull(
                (prItem) => prItem.materialCode == item.materialCode
              );
              if (prItem != null) {
                materialPRItems[item.materialCode]!.add(prItem);
              }
            }
          }
        }

        // Initialize general stock quantities only for legacy items with no PR breakdown
        // If 'General' exists in prDetails it has already been initialized above
        if (item.prDetails.isEmpty) {
          selectedPRs[item.materialCode]!['General'] = true;
          prQtyControllers[item.materialCode]!['General'] =
              TextEditingController(text: item.quantity);
        }

        // Initialize job numbers from existing PO if editing
        for (var detail in item.prDetails.values) {
          if (detail.jobNo.isNotEmpty && detail.jobNo != 'General') {
            jobNumbers.add(detail.jobNo);
          }
        }

        // Initialize price controllers for existing PO items
        priceControllers[item.materialCode] =
            TextEditingController(text: item.costPerUnit);
        
        // Show General Stock row if it's already selected in existing PO
        if (item.prDetails.containsKey('General') && 
            item.prDetails['General']!.quantity > 0) {
          showGeneralStock[item.materialCode] = true;
        }
      }

      setState(() {
        poItems = List<POItem>.from(widget.existingPO!.items);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _poNo ??= ref.read(purchaseOrderListProvider.notifier).generateOrderNumber();
        });
      });
    }
  }

  @override
  void dispose() {
    _transportController.dispose();
    _deliveryRequirementsController.dispose();
    _termsAndConditionsController.dispose();
    _supplierSearchController.dispose();
    for (final c in priceControllers.values) {
      c.dispose();
    }
    for (var materialControllers in prQtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateMaterialPRItems() {
    if (selectedSupplier == null) return;

    final materials = ref.read(materialListProvider);
    final purchaseRequests = ref
        .read(purchaseRequestListProvider)
        .where((pr) => pr.status != 'Completed')
        .toList();

    // When editing an existing PO, preserve existing materialPRItems
    // Only clear if this is a new PO
    if (widget.existingPO == null) {
      materialPRItems.clear();
    }

    for (var pr in purchaseRequests) {
      // Skip if PR's job doesn't match selected jobs
      if (!selectedJobs.contains('All') && !selectedJobs.contains(pr.jobNo)) {
        continue;
      }

      for (var item in pr.items.where((item) => !item.isFullyOrdered)) {
        final material = materials.firstWhereOrNull(
          (m) => m.partNo == item.materialCode,
        );

        // Skip if material not found (may have been deleted)
        if (material == null) {
          continue;
        }

        // Check if the material has a rate for the selected supplier
        final vendorRate = material.getRateForVendor(selectedSupplier!.name);

        if (vendorRate != null) {
          // Only add if not already present (to avoid duplicates when editing)
          final existingItems = materialPRItems[item.materialCode] ?? [];
          if (!existingItems.any((existing) => existing.prNo == item.prNo)) {
            materialPRItems.putIfAbsent(item.materialCode, () => []).add(item);
          }
        }
      }
    }
  }

  POItem _createPOItem(MaterialItem material, List<PRItem> prItems) {
    // Get the vendor rate for the selected supplier
    final vendorRate = material.getRateForVendor(selectedSupplier!.name);

    if (vendorRate == null) {
      throw Exception('Rate not found for ${selectedSupplier!.name}');
    }

    // Base purchase rate from Material Master
    double costPerUnit = double.parse(vendorRate.purchaseRate);
    // If editing, prefer amended price from UI controller when available
    if (widget.existingPO != null) {
      final ctrl = priceControllers[material.partNo];
      print('Looking for price controller for: ${material.partNo}');
      print('Controller found: ${ctrl != null}');
      print('Controller text: ${ctrl?.text}');
      final edited = double.tryParse(ctrl?.text ?? '');
      print('Parsed price: $edited');
      if (edited != null && edited > 0) {
        costPerUnit = edited;
        print('Using edited price: $costPerUnit');
      } else {
        print('Using vendor rate: $costPerUnit');
      }
    }
    final saleRate = material.saleRateAsDouble; // Material's own sale rate
    final marginPerUnit = saleRate - costPerUnit;

    // Calculate total quantity from PR-wise quantities and general stock
    final prDetails = <String, ItemPRDetails>{};
    double totalQty = 0;

    // If this is a general stock item (no PR items), handle it separately
    if (prItems.isEmpty && selectedPRs[material.partNo]?['General'] == true) {
      final controller = prQtyControllers[material.partNo]?['General'];
      if (controller != null) {
        final orderQty = double.tryParse(controller.text) ?? 0;
        if (orderQty > 0) {
          prDetails['General'] = ItemPRDetails(
            prNo: 'General',
            jobNo: 'General',
            quantity: orderQty,
          );
          totalQty = orderQty;
        }
      }
    } else {
      // Handle PR-based items
      for (var prItem in prItems) {
        if (selectedPRs[material.partNo]?[prItem.prNo] == true) {
          final controller = prQtyControllers[material.partNo]?[prItem.prNo];
          if (controller != null) {
            final orderQty = double.tryParse(controller.text) ?? 0;
            if (orderQty > 0) {
              // Get the parent PR to access its job number
              final pr = ref
                  .read(purchaseRequestListProvider)
                  .firstWhere((pr) => pr.prNo == prItem.prNo);

              prDetails[prItem.prNo] = ItemPRDetails(
                prNo: prItem.prNo,
                jobNo: pr.jobNo ?? 'General',
                quantity: orderQty,
              );
              totalQty += orderQty;
            }
          }
        }
      }

      // Add general stock for PR-based items if selected
      if (selectedPRs[material.partNo]?['General'] == true) {
        final controller = prQtyControllers[material.partNo]?['General'];
        if (controller != null) {
          final orderQty = double.tryParse(controller.text) ?? 0;
          if (orderQty > 0) {
            prDetails['General'] = ItemPRDetails(
              prNo: 'General',
              jobNo: 'General',
              quantity: orderQty,
            );
            totalQty += orderQty;
          }
        }
      }
    }

    // Compare against the ORIGINAL saved PO item from the deep copy, not the mutable widget.existingPO
    final originalPOItem = _originalPO?.items.firstWhereOrNull((i) => i.materialCode == material.partNo);

    print('Creating POItem for material: ${material.partNo}');
    print('Total quantity: $totalQty');
    print('PR Details: ${prDetails.keys.join(", ")}');

    // Track amendment history when editing existing PO
    List<AmendmentEntry> amendmentHistory = originalPOItem?.amendmentHistory ?? [];
    double? originalCost = originalPOItem?.originalCostPerUnit;
    double? amendedCost;

    if (widget.existingPO != null && originalPOItem != null) {
      // Previous effective price (use amended if present, else saved cost)
      final previousEffectivePrice = originalPOItem.amendedCostPerUnit ??
          (double.tryParse(originalPOItem.costPerUnit) ?? 0.0);

      // Set original cost - preserve from first amendment, or use previous price
      originalCost = originalPOItem.originalCostPerUnit ?? previousEffectivePrice;

      print('=== Amendment Check for ${material.partNo} ===');
      print('widget.existingPO.poNo: ${widget.existingPO!.poNo}');
      print('widget.existingPO.hasAmendments: ${widget.existingPO!.hasAmendments}');
      print('originalPOItem.originalCostPerUnit: ${originalPOItem.originalCostPerUnit}');
      print('originalPOItem.amendedCostPerUnit: ${originalPOItem.amendedCostPerUnit}');
      print('originalPOItem.costPerUnit: ${originalPOItem.costPerUnit}');
      print('originalPOItem.amendmentHistory.length: ${originalPOItem.amendmentHistory.length}');
      print('Previous effective price: $previousEffectivePrice');
      print('Current price from controller: $costPerUnit');
      print('Price difference: ${(costPerUnit - previousEffectivePrice).abs()}');

      // Check if price has changed
      if ((costPerUnit - previousEffectivePrice).abs() > 0.0001) {
        // Price has changed - add to amendment history
        amendedCost = costPerUnit;
        amendmentHistory = List<AmendmentEntry>.from(amendmentHistory);
        amendmentHistory.add(AmendmentEntry(
          dateTime: DateTime.now().toIso8601String(),
          oldPrice: previousEffectivePrice,
          newPrice: costPerUnit,
        ));
        print('✓✓✓ AMENDMENT ADDED: ₹${previousEffectivePrice.toStringAsFixed(2)} → ₹${costPerUnit.toStringAsFixed(2)}');
        print('✓✓✓ New amendment history length: ${amendmentHistory.length}');
      } else {
        // No change - preserve existing amended cost
        amendedCost = originalPOItem.amendedCostPerUnit;
        print('✗✗✗ NO PRICE CHANGE - prices are identical');
      }
    } else if (widget.existingPO == null) {
      // New PO - set original cost
      originalCost = costPerUnit;
      print('New PO - setting original cost to: $costPerUnit');
    } else {
      print('WARNING: widget.existingPO is not null but originalPOItem is null for ${material.partNo}');
    }
    
    // Use PO-level terms and conditions for every item
    final termsText = _termsAndConditionsController.text.trim();
    final terms = termsText.isNotEmpty ? termsText : null;
    
    return POItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalQty.toString(),
      costPerUnit: costPerUnit.toString(),
      totalCost: (costPerUnit * totalQty).toString(),
      saleRate: saleRate.toString(),
      marginPerUnit: marginPerUnit.toString(),
      totalMargin: (marginPerUnit * totalQty).toString(),
      prDetails: prDetails,
      originalCostPerUnit: originalCost,
      amendedCostPerUnit: amendedCost,
      amendmentHistory: amendmentHistory,
      // Use terms from controller, or null if empty
      termsAndConditions: terms,
    );
  }

  // Method to get job number display text for a material
  String _getJobNumberDisplay(MaterialItem material, List<PRItem> prItems) {
    // If this is a general stock item (no PR items)
    if (prItems.isEmpty && selectedPRs[material.partNo]?['General'] == true) {
      return 'General Stock';
    }

    // Get all selected PR job numbers
    final jobNumbers = <String>{};
    for (var prItem in prItems) {
      if (selectedPRs[material.partNo]?[prItem.prNo] == true) {
        final controller = prQtyControllers[material.partNo]?[prItem.prNo];
        if (controller != null &&
            double.tryParse(controller.text) != null &&
            double.tryParse(controller.text)! > 0) {
          final pr = ref
              .read(purchaseRequestListProvider)
              .firstWhere((pr) => pr.prNo == prItem.prNo);
          if (pr.jobNo != null && pr.jobNo!.isNotEmpty) {
            jobNumbers.add(pr.jobNo!);
          }
        }
      }
    }

    // If no PR job numbers and general stock is selected
    if (jobNumbers.isEmpty &&
        selectedPRs[material.partNo]?['General'] == true) {
      return 'General Stock';
    }

    // If we have PR job numbers
    if (jobNumbers.isNotEmpty) {
      return jobNumbers.join(', ');
    }

    return 'General Stock';
  }

  Widget _buildItemCard(MaterialItem material, List<PRItem> prItems) {
    // Initialize selectedPRs for this material if not already done
    if (!selectedPRs.containsKey(material.partNo)) {
      selectedPRs[material.partNo] = {};
      prQtyControllers[material.partNo] = {};
      for (var prItem in prItems) {
        selectedPRs[material.partNo]![prItem.prNo] = false;
        prQtyControllers[material.partNo]![prItem.prNo] =
            TextEditingController();
      }
      // Add general stock option
      selectedPRs[material.partNo]!['General'] = false;
      prQtyControllers[material.partNo]!['General'] = TextEditingController();
    }

    // Get all vendor rates for this material
    final rates = material.vendorRates
        .where((r) => double.tryParse(r.purchaseRate) != null)
        .toList();

    // Sort rates by purchase price (lowest first)
    rates.sort((a, b) =>
        double.parse(a.purchaseRate).compareTo(double.parse(b.purchaseRate)));

    // Find selected supplier's rate
    final selectedRate = rates.firstWhere(
      (r) => r.vendorId == selectedSupplier!.name,
      orElse: () => throw Exception('Rate not found'),
    );

    // Get lowest and highest prices
    final lowestPrice =
        rates.isNotEmpty ? double.parse(rates.first.purchaseRate) : 0.0;
    final highestPrice =
        rates.isNotEmpty ? double.parse(rates.last.purchaseRate) : 0.0;
    // If editing an existing PO and this material exists in it, use the PO item's cost as selected price display
    // Use widget.existingPO.items to get the original saved data with amendment history
    final existingPOItem = widget.existingPO?.items.firstWhereOrNull((i) => i.materialCode == material.partNo);
    final selectedPrice = existingPOItem != null
        ? double.tryParse(existingPOItem.costPerUnit) ?? double.parse(selectedRate.purchaseRate)
        : double.parse(selectedRate.purchaseRate);

    // Determine color based on rate comparison
    Color priceColor;
    Color textColor = Colors.black;

    if (selectedPrice == lowestPrice) {
      priceColor = Colors.green.shade200;
    } else if (selectedPrice == highestPrice && selectedPrice > lowestPrice) {
      priceColor = Colors.red.shade200;
      textColor = Colors.white;
    } else {
      priceColor = Colors.yellow.shade200;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: priceColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          material.description,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Text(
                        'Code: ${material.partNo}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Text(
                        'Unit: ${material.unit}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Text(
                        'Rate: ₹${selectedRate.purchaseRate}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Per-line price amendment controls (only when editing existing PO)
                if (widget.existingPO != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Builder(builder: (context) {
                      final hasGRs = widget.existingPO == null
                          ? false
                          : ref.read(storeInwardProvider.notifier)
                              .getInwardsForPO(widget.existingPO!.poNo)
                              .isNotEmpty;
                      final existingController = priceControllers[material.partNo];
                      final controller = existingController ??
                          TextEditingController(text: selectedPrice.toStringAsFixed(2));
                      if (existingController == null) {
                        print('Creating NEW price controller for ${material.partNo} with price: ${selectedPrice.toStringAsFixed(2)}');
                        priceControllers[material.partNo] = controller;
                      } else {
                        print('Using EXISTING price controller for ${material.partNo} with value: ${existingController.text}');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'PO Rate: ',
                                style: TextStyle(color: Colors.black),
                              ),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  style: const TextStyle(color: Colors.black),
                                  controller: controller,
                                  enabled: !hasGRs,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    _LeadingZeroDecimalTextInputFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    border: const OutlineInputBorder(),
                                    hintText: 'Rate',
                                    suffixText: '₹',
                                    hintStyle: const TextStyle(color: Colors.black),
                                  ),
                                  onChanged: (val) {
                                    final v = double.tryParse(val);
                                    setState(() {
                                      final item = poItems.firstWhereOrNull((i) => i.materialCode == material.partNo);
                                      if (item != null && v != null) {
                                        item.updateCostPerUnit(v.toString());
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (existingPOItem?.originalCostPerUnit != null)
                                Text('Original: ₹${existingPOItem!.originalCostPerUnit!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          // Always-visible amendments summary
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 2),
                            child: Builder(
                              builder: (context) {
                                // Calculate if there's a pending amendment
                                int amendmentCount = existingPOItem?.amendmentHistory.length ?? 0;
                                double? currentPrice = double.tryParse(priceControllers[material.partNo]?.text ?? '');
                                double? savedPrice = existingPOItem?.amendedCostPerUnit ?? 
                                    (existingPOItem != null ? double.tryParse(existingPOItem.costPerUnit) : null);
                                
                                bool hasPendingAmendment = false;
                                if (widget.existingPO != null && currentPrice != null && savedPrice != null) {
                                  hasPendingAmendment = (currentPrice - savedPrice).abs() > 0.0001;
                                  if (hasPendingAmendment) {
                                    amendmentCount++; // Count the pending amendment
                                  }
                                }
                                
                                return Row(
                                  children: [
                                    Text(
                                      'Amendments: $amendmentCount${hasPendingAmendment ? ' (1 pending)' : ''}',
                                      style: TextStyle(
                                        fontSize: 11, 
                                        color: hasPendingAmendment ? Colors.orange[900] : Colors.black, 
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                    if (existingPOItem?.amendedCostPerUnit != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        'Last Amended: ₹${existingPOItem!.amendedCostPerUnit!.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black),
                                      ),
                                    ],
                                    if (hasPendingAmendment && currentPrice != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        'New: ₹${currentPrice.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 11, color: Colors.orange[900], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                );
                              }
                            ),
                          ),
                          if ((existingPOItem?.amendmentHistory.isNotEmpty ?? false) || 
                              (widget.existingPO != null && 
                               double.tryParse(priceControllers[material.partNo]?.text ?? '') != null &&
                               (existingPOItem?.amendedCostPerUnit ?? double.tryParse(existingPOItem?.costPerUnit ?? '0')) != null &&
                               ((double.tryParse(priceControllers[material.partNo]?.text ?? '') ?? 0) - 
                                (existingPOItem?.amendedCostPerUnit ?? double.tryParse(existingPOItem?.costPerUnit ?? '0') ?? 0)).abs() > 0.0001)) ...[
                            const SizedBox(height: 6),
                            const Text('Amendment History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Builder(
                                builder: (context) {
                                  final savedHistory = existingPOItem?.amendmentHistory ?? [];
                                  final currentPrice = double.tryParse(priceControllers[material.partNo]?.text ?? '');
                                  final savedPrice = existingPOItem?.amendedCostPerUnit ?? 
                                      (existingPOItem != null ? double.tryParse(existingPOItem.costPerUnit) : null);
                                  
                                  final hasPendingAmendment = widget.existingPO != null && 
                                      currentPrice != null && 
                                      savedPrice != null && 
                                      (currentPrice - savedPrice).abs() > 0.0001;
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...savedHistory.map((e) =>
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            '${e.dateTime.split('T')[0]} ${e.dateTime.split('T')[1].substring(0, 8)}: ₹${e.oldPrice.toStringAsFixed(2)} → ₹${e.newPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 11, color: Colors.black)
                                          ),
                                        )
                                      ),
                                      if (hasPendingAmendment && currentPrice != null && savedPrice != null) ...[
                                        if (savedHistory.isNotEmpty) const Divider(height: 8, thickness: 1),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Pending: ₹${savedPrice.toStringAsFixed(2)} → ₹${currentPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 11, 
                                              color: Colors.orange[900], 
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic
                                            )
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                }
                              ),
                            ),
                          ],
                          if (widget.existingPO != null && (ref.read(storeInwardProvider.notifier).getInwardsForPO(widget.existingPO!.poNo).isNotEmpty))
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('Locked after GR', style: TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                        ],
                      );
                    }),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = MediaQuery.of(context).size.width;
                final tableWidth = viewportWidth > 1000 ? viewportWidth : 1000.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                    SizedBox(
                      width: tableWidth,
                      child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(0.3), // Checkbox column
                        1: FlexColumnWidth(0.9), // PR No
                        2: FlexColumnWidth(0.9), // Job No
                        3: FlexColumnWidth(0.7), // Need
                        4: FlexColumnWidth(0.7), // Ordered
                        5: FlexColumnWidth(0.8), // Order Qty
                        6: FlexColumnWidth(0.9), // Available (Board/PR)
                        7: FlexColumnWidth(0.9), // Available (General)
                        8: FlexColumnWidth(0.9), // Stock Transfer
                      },
                      children: [
                        TableRow(
                          children: [
                            // Add Select All checkbox
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Checkbox(
                                  value: ((showGeneralStock[material.partNo] ?? false)
                                          ? (selectedPRs[material.partNo]?['General'] == true)
                                          : true) &&
                                      prItems.every((prItem) =>
                                          selectedPRs[material.partNo]?[prItem.prNo] ==
                                          true),
                                  tristate: true,
                                  side:
                                      const BorderSide(color: Colors.black, width: 1.5),
                                  onChanged: (_) {
                                    setState(() {
                                      // Check if all items (including General Stock if visible) are currently selected
                                      final allSelected =
                                          ((showGeneralStock[material.partNo] ?? false)
                                                  ? (selectedPRs[material.partNo]?['General'] ==
                                                      true)
                                                  : true) &&
                                              prItems.every((prItem) =>
                                                  selectedPRs[material.partNo]?[prItem.prNo] ==
                                                  true);

                                      // If all are selected, deselect all. Otherwise, select all
                                      final newValue = !allSelected;

                                      // Update General Stock only if visible
                                      if (showGeneralStock[material.partNo] ?? false) {
                                        selectedPRs[material.partNo]!['General'] =
                                            newValue;
                                        if (newValue) {
                                          prQtyControllers[material.partNo]!['General']
                                              ?.text = '0';
                                        } else {
                                          prQtyControllers[material.partNo]!['General']
                                              ?.text = '';
                                        }
                                      }

                                      // Update PR items
                                      for (var prItem in prItems) {
                                        selectedPRs[material.partNo]![prItem.prNo] =
                                            newValue;

                                        // Update quantity
                                        if (newValue) {
                                          final totalQty =
                                              double.parse(prItem.quantity);
                                          final orderedQty = prItem
                                              .orderedQuantities.entries
                                              .where((e) =>
                                                  e.key != widget.existingPO?.poNo)
                                              .fold(0.0, (sum, e) => sum + e.value);
                                          final remainingQty = totalQty - orderedQty;

                                          prQtyControllers[material.partNo]![prItem.prNo]
                                              ?.text = remainingQty.toString();
                                        } else {
                                          prQtyControllers[material.partNo]![prItem.prNo]
                                              ?.text = '0';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('PR No',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: textColor)),
                                    if (!(showGeneralStock[material.partNo] ?? false)) ...[
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 16),
                                        color: Colors.black,
                                        tooltip: 'Add General Stock',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          setState(() {
                                            showGeneralStock[material.partNo] = true;
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Job No',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Need',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Ordered',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Order Qty',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Available (Board/PR)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Available (General)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('Stock Transfer',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: textColor)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                    const Divider(height: 16),
                    SizedBox(
                      width: tableWidth,
                      child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(0.3), // Checkbox column
                        1: FlexColumnWidth(0.9), // PR No
                        2: FlexColumnWidth(0.9), // Job No
                        3: FlexColumnWidth(0.7), // Need
                        4: FlexColumnWidth(0.7), // Ordered
                        5: FlexColumnWidth(0.8), // Order Qty
                        6: FlexColumnWidth(0.9), // Available (Board/PR)
                        7: FlexColumnWidth(0.9), // Available (General)
                        8: FlexColumnWidth(0.9), // Stock Transfer
                      },
                      children: [
                // Add General Stock row first (conditionally shown)
                if (showGeneralStock[material.partNo] ?? false)
                  TableRow(
                    children: [
                      // Checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Checkbox(
                            value:
                                selectedPRs[material.partNo]?['General'] ?? false,
                            side:
                                const BorderSide(color: Colors.black, width: 1.5),
                            onChanged: (bool? value) {
                              setState(() {
                                selectedPRs[material.partNo]!['General'] =
                                    value ?? false;
                                if (!value!) {
                                  prQtyControllers[material.partNo]!['General']!
                                      .text = '';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // PR No (General Stock)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text('General Stock',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  fontStyle: FontStyle.italic)),
                        ),
                      ),
                      // Job No
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text('General Stock',
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Need
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text('-',
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Ordered
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text('-',
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Order Qty with close button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 32,
                                child: TextFormField(
                                  controller:
                                      prQtyControllers[material.partNo]!['General'],
                                  enabled:
                                      selectedPRs[material.partNo]?['General'] ??
                                          false,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    filled: !(selectedPRs[material.partNo]
                                            ?['General'] ??
                                        false),
                                    fillColor: !(selectedPRs[material.partNo]
                                                ?['General'] ??
                                            false)
                                        ? Colors.grey[200]
                                        : null,
                                  ),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                      fontWeight: FontWeight.w500),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (!(selectedPRs[material.partNo]?['General'] ??
                                        false)) return null;
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final qty = double.tryParse(value);
                                    if (qty == null || qty <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.red,
                                tooltip: 'Remove General Stock',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    showGeneralStock[material.partNo] = false;
                                    selectedPRs[material.partNo]!['General'] =
                                        false;
                                    prQtyControllers[material.partNo]!['General']!
                                        .text = '';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Available (Board/PR)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text('-',
                              style: TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Available (General)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                              (ref
                                          .read(stockMaintenanceProvider.notifier)
                                          .getStockForMaterial(material.partNo)
                                          ?.prDetails
                                          .values
                                          .where((p) => p.jobNo == 'General')
                                          .fold(0.0,
                                              (sum, p) => sum + p.availableQuantity) ??
                                      0.0)
                                  .toStringAsFixed(2),
                              style: TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Transfer
                      const SizedBox(),
                    ],
                  ),
                ...prItems.map((prItem) {
                  final totalQty = double.parse(prItem.quantity);
                  final orderedQty = prItem.orderedQuantities.entries
                      .where((e) => e.key != widget.existingPO?.poNo)
                      .fold(0.0, (sum, e) => sum + e.value);
                  final remainingQty = totalQty - orderedQty;

                  // Get the parent PR to access its job number
                  final parentPR = ref
                      .read(purchaseRequestListProvider)
                      .firstWhereOrNull((pr) => pr.prNo == prItem.prNo);
                  final jobNo = parentPR?.jobNo ?? 'General Stock';

                  final stock = ref
                      .read(stockMaintenanceProvider.notifier)
                      .getStockForMaterial(material.partNo);

                  final generalAvailable = stock == null
                      ? 0.0
                      : stock.prDetails.values
                          .where((p) => p.jobNo == 'General')
                          .fold(0.0, (sum, p) => sum + p.availableQuantity);

                  final boardAvailable = stock == null
                      ? 0.0
                      : stock.prDetails.entries
                          .where((e) {
                            final key = e.key;
                            final p = e.value;
                            if (p.jobNo != jobNo) return false;
                            return key == prItem.prNo ||
                                key.startsWith('${prItem.prNo}|XFER|$jobNo|');
                          })
                          .fold(0.0, (sum, e) => sum + e.value.availableQuantity);

                  final isInExistingPO = widget.existingPO?.items.any(
                          (item) => item.prDetails.containsKey(prItem.prNo)) ??
                      false;

                  if (remainingQty <= 0 && !isInExistingPO) {
                    return const TableRow(children: [
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ]);
                  }

                  final isSelected =
                      selectedPRs[material.partNo]?[prItem.prNo] ?? false;

                  return TableRow(
                    children: [
                      // Checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Checkbox(
                            value: isSelected,
                            side: const BorderSide(
                                color: Colors.black, width: 1.5),
                            onChanged: (bool? value) {
                              setState(() {
                                selectedPRs.putIfAbsent(
                                    material.partNo, () => {});
                                prQtyControllers.putIfAbsent(
                                    material.partNo, () => {});

                                selectedPRs[material.partNo]![prItem.prNo] =
                                    value ?? false;

                                prQtyControllers[material.partNo]!.putIfAbsent(
                                    prItem.prNo,
                                    () => TextEditingController());

                                if (value == true) {
                                  prQtyControllers[material.partNo]![prItem.prNo]!
                                      .text = remainingQty.toString();
                                } else {
                                  prQtyControllers[material.partNo]![prItem.prNo]!
                                      .text = '0';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // PR No
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(prItem.prNo,
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Job No
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(jobNo,
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Need
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(totalQty.toStringAsFixed(2),
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Ordered
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(orderedQty.toStringAsFixed(2),
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Order Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            child: TextFormField(
                              controller: prQtyControllers[material.partNo]![prItem.prNo],
                              enabled: isSelected,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: const OutlineInputBorder(),
                                filled: !isSelected,
                                fillColor: !isSelected ? Colors.grey[200] : null,
                              ),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  fontWeight: FontWeight.w500),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (!isSelected) return null;
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                final qty = double.tryParse(value);
                                if (qty == null) return 'Invalid';
                                if (qty < 0) return 'Invalid';
                                if (qty > remainingQty) return 'Exceeds';
                                return null;
                              },
                              onChanged: (value) {
                                if (!isSelected) return;
                                final qty = double.tryParse(value);
                                if (qty != null) {
                                  if (qty > remainingQty) {
                                    prQtyControllers[material.partNo]?[prItem.prNo]
                                        ?.text = remainingQty.toString();
                                    value = remainingQty.toString();
                                  }
                                  // Find or create the PO item
                                  var poItem = poItems.firstWhere(
                                    (item) => item.materialCode == material.partNo,
                                    orElse: () {
                                      // Create a new PO item if it doesn't exist
                                      final newItem =
                                          _createPOItem(material, [prItem]);
                                      poItems.add(newItem);
                                      return newItem;
                                    },
                                  );
                                  poItem.updateQuantity(value);
                                }
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ),
                      // Available (Board/PR)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(boardAvailable.toStringAsFixed(2),
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Available (General)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(generalAvailable.toStringAsFixed(2),
                              style:
                                  TextStyle(fontSize: 12, color: textColor)),
                        ),
                      ),
                      // Transfer
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                          tooltip: 'Stock Transfer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          color: Colors.black,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StockTransferPage(
                                  prNo: prItem.prNo,
                                  materialCode: material.partNo,
                                ),
                              ),
                            );
                          },
                        ),
                        ),
                      ),
                    ],
                  );
                }).where(
                    (row) => row.children.any((cell) => cell is! SizedBox)),
              ],
                    ),
                    ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Add General Stock button (only show if not already visible)
            if (!(showGeneralStock[material.partNo] ?? false)) ...[
              const SizedBox.shrink(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    final materials = ref.read(materialListProvider);
    bool hasItems = false;

    final updatedPOItems = <POItem>[];

    // Process PR-based and general stock items
    for (var entry in materialPRItems.entries) {
      final material = materials.firstWhereOrNull((m) => m.partNo == entry.key);
      if (material == null) continue;
      final prItems = entry.value;

      // Create POItem only if there are quantities
      final poItem = _createPOItem(material, prItems);
      if (double.parse(poItem.quantity) > 0) {
        updatedPOItems.add(poItem);
        hasItems = true;
      }
    }

    // Process newly added general stock items
    for (var entry in selectedPRs.entries) {
      if (!materialPRItems.containsKey(entry.key) &&
          entry.value['General'] == true) {
        final material = materials.firstWhereOrNull((m) => m.partNo == entry.key);
        if (material == null) continue;
        final poItem = _createPOItem(material, []);
        if (double.parse(poItem.quantity) > 0) {
          updatedPOItems.add(poItem);
          hasItems = true;
        }
      }
    }

    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one item with quantity')),
      );
      return;
    }

    if (_transportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Transport details')),
      );
      return;
    }

    if (_deliveryRequirementsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Delivery Requirements')),
      );
      return;
    }

    // Calculate tax amounts
    final subtotal = updatedPOItems.fold(
        0.0, (sum, item) => sum + double.parse(item.totalCost));

    double parseGstRate(String? value) {
      if (value == null || value.isEmpty) return 0.0;
      value = value.replaceAll('%', '').trim();
      return double.tryParse(value) ?? 0.0;
    }

    final igst = subtotal * (parseGstRate(selectedSupplier!.igst) / 100);
    final cgst = subtotal * (parseGstRate(selectedSupplier!.cgst) / 100);
    final sgst = subtotal * (parseGstRate(selectedSupplier!.sgst) / 100);
    final grandTotal = subtotal + igst + cgst + sgst;

    final poNo = widget.existingPO?.poNo ??
        (_poNo ?? ref.read(purchaseOrderListProvider.notifier).generateOrderNumber());
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check if any items have amendments or if existing PO already had amendments
    bool hasAmendments = (widget.existingPO?.hasAmendments ?? false) || 
      updatedPOItems.any((item) => 
        item.amendmentHistory.isNotEmpty || item.amendedCostPerUnit != null
      );

    print('=== PO Save Debug ===');
    print('PO No: $poNo');
    print('Has Amendments: $hasAmendments');
    print('Total items in PO: ${updatedPOItems.length}');
    for (var item in updatedPOItems) {
      print('Item ${item.materialCode}:');
      print('  costPerUnit: ${item.costPerUnit}');
      print('  originalCostPerUnit: ${item.originalCostPerUnit}');
      print('  amendedCostPerUnit: ${item.amendedCostPerUnit}');
      print('  amendmentHistory.length: ${item.amendmentHistory.length}');
      if (item.amendmentHistory.isNotEmpty) {
        print('  Amendment details:');
        for (var amendment in item.amendmentHistory) {
          print('    ${amendment.dateTime}: ${amendment.oldPrice} → ${amendment.newPrice}');
        }
      }
    }

    final newPO = PurchaseOrder(
      poNo: poNo,
      poDate: widget.existingPO?.poDate ?? now,
      supplierName: selectedSupplier!.name,
      transport: _transportController.text,
      deliveryRequirements: _deliveryRequirementsController.text,
      items: updatedPOItems,
      total: subtotal,
      igst: igst,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
      previousPONo: widget.foreClosedPONo,
      hasAmendments: hasAmendments,
      // Preserve original PO date when amending, or set to current date for new PO
      originalPoDate: widget.existingPO?.originalPoDate ?? 
                      (widget.existingPO != null ? widget.existingPO!.poDate : now),
    );

    // Update PR quantities and status
    final prNotifier = ref.read(purchaseRequestListProvider.notifier);
    final purchaseRequests = ref.read(purchaseRequestListProvider);

    // Only update PR quantities for PR-based items
    for (var poItem in updatedPOItems) {
      for (var prDetail in poItem.prDetails.entries) {
        if (prDetail.key == 'General') continue; // Skip general stock items

        // Find the PR and update its item quantities
        for (var pr in purchaseRequests) {
          if (pr.prNo == prDetail.value.prNo) {
            final prItem = pr.items.firstWhere(
              (item) => item.materialCode == poItem.materialCode,
              orElse: () => throw Exception('PR item not found'),
            );

            if (prDetail.value.quantity > 0) {
              // Clear any existing ordered quantity for this PO if editing
              if (widget.existingPO != null) {
                prItem.orderedQuantities.remove(widget.existingPO!.poNo);
              }

              // Add the new ordered quantity
              prItem.addOrderedQuantity(poNo, prDetail.value.quantity);

              // Update PR status through provider (avoid direct model save)
              if (pr.isFullyOrdered) {
                pr.status = 'Completed';
              } else if (pr.items
                  .any((item) => item.totalOrderedQuantity > 0)) {
                pr.status = 'Partially Ordered';
              } else {
                pr.status = 'Draft';
              }

              final index = purchaseRequests.indexOf(pr);
              prNotifier.updateRequest(index, pr);
            }
          }
        }
      }
    }

    // Save the PO
    if (widget.existingPO != null && widget.index != null) {
      // Check if PO has GRs before attempting update
      if (widget.existingPO!.hasGR) {
        // Show error - cannot amend PO with GRs
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot amend PO - Goods Receipt already created. PO is locked.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      await poNotifier.updateOrder(widget.index!, newPO);
      
      print('✓ PO updated successfully. Amendments saved: $hasAmendments');
    } else {
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      await poNotifier.addOrder(newPO);
    }

    // Show PDF generation options
    _showPDFGenerationDialog(newPO);
  }

  void _navigateBackToPOList() {
    // Ensure we go back to the PO list page
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showPDFGenerationDialog(PurchaseOrder purchaseOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Order Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PO No: ${purchaseOrder.poNo}'),
            const SizedBox(height: 16),
            const Text('Choose how to save the PDF:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _navigateBackToPOList();
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _generateAndSaveToDownloads(purchaseOrder);
              _navigateBackToPOList();
            },
            child: const Text('Quick Save'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _generateAndSavePDF(purchaseOrder);
              _navigateBackToPOList();
            },
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSavePDF(PurchaseOrder purchaseOrder) async {
    try {
      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success =
          await PDFService.savePurchaseOrder(purchaseOrder, selectedSupplier!);

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save cancelled by user'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndSaveToDownloads(PurchaseOrder purchaseOrder) async {
    try {
      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await PDFService.savePurchaseOrderToDownloads(
          purchaseOrder, selectedSupplier!);

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Platform.isMacOS || Platform.isIOS
                  ? 'PDF saved to Documents folder successfully!'
                  : 'PDF saved to Downloads folder successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save PDF to Downloads'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final materials = ref.watch(materialListProvider);
    final purchaseRequests = ref
        .watch(purchaseRequestListProvider)
        .where((pr) => pr.status != 'Completed')
        .toList();

    // Get unique job numbers for filter dropdown
    final availableJobs = _getUniqueJobNumbers();

    // Update material PR items when supplier or job number changes
    _updateMaterialPRItems();

    // Get all materials that have general stock items (skip missing materials)
    final generalStockMaterials = selectedPRs.entries
        .where((entry) =>
            entry.value['General'] == true &&
            !materialPRItems.containsKey(entry.key))
        .map((entry) =>
            materials.firstWhereOrNull((m) => m.partNo == entry.key))
        .whereType<MaterialItem>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Order Creation"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : _refreshAllData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField2<Supplier>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Supplier',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        hint: const Text("Select Supplier"),
                        value: selectedSupplier,
                        items: suppliers
                            .map((supplier) => DropdownMenuItem<Supplier>(
                                  value: supplier,
                                  child: Text(
                                    supplier.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedSupplier = val;
                            selectedPRs.clear();
                            prQtyControllers.clear();
                            selectedJobs = [
                              'All'
                            ]; // Reset job filter when supplier changes
                          });
                        },
                        dropdownSearchData: DropdownSearchData(
                          searchController: _supplierSearchController,
                          searchInnerWidgetHeight: 50,
                          searchInnerWidget: Container(
                            height: 50,
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 4,
                              right: 8,
                              left: 8,
                            ),
                            child: TextFormField(
                              controller: _supplierSearchController,
                              expands: true,
                              maxLines: null,
                              autofocus: true,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Search Supplier',
                                hintStyle: const TextStyle(fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            return item.value!.name
                                .toLowerCase()
                                .contains(searchValue.toLowerCase());
                          },
                        ),
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            // Clear search when dropdown closes
                            _supplierSearchController.clear();
                          }
                        },
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          height: 56,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Job Filter (dropdown-like field)
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final result = await showDialog<List<String>>(
                            context: context,
                            builder: (context) => SelectJobsDialog(
                              selectedJobs: selectedJobs,
                              availableJobs: availableJobs.toList(),
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              selectedJobs = result;
                              // If no jobs selected, default to 'All'
                              if (selectedJobs.isEmpty) {
                                selectedJobs = ['All'];
                              }
                              // If 'All' is selected, clear other selections
                              if (selectedJobs.contains('All')) {
                                selectedJobs = ['All'];
                              }
                              selectedPRs.clear();
                              prQtyControllers.clear();
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Job Filter',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 20,
                            ),
                          ),
                          child: Text(
                            selectedJobs.contains('All')
                                ? 'All Jobs'
                                : '${selectedJobs.length} Jobs Selected',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "PO No: ${_poNo ?? ""}",
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Date: ${DateFormat('dd/MMM/yy').format(DateTime.now())}",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Text(
                            'PR-Based Items',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _showL1,
                            onChanged: (v) => setState(() => _showL1 = v ?? true),
                          ),
                          const Text('Green (L1)'),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _showL2,
                            onChanged: (v) => setState(() => _showL2 = v ?? true),
                          ),
                          const Text('Yellow (L2)'),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _showL3,
                            onChanged: (v) => setState(() => _showL3 = v ?? true),
                          ),
                          const Text('Red (L3)'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedSupplier != null) ...[
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...materialPRItems.entries.where((entry) {
                        final material = materials
                            .firstWhereOrNull((m) => m.partNo == entry.key);
                        if (material == null) return false;
                        final level = _getPriceLevel(material);
                        if (!_showL1 && !_showL2 && !_showL3) return false;
                        if (level == 'L1' && !_showL1) return false;
                        if (level == 'L2' && !_showL2) return false;
                        if (level == 'L3' && !_showL3) return false;
                        return true;
                      }).map((entry) {
                        final materialCode = entry.key;
                        final prItems = entry.value;
                        final material =
                            materials.firstWhereOrNull((m) => m.partNo == materialCode);
                        if (material == null) {
                          return const SizedBox.shrink();
                        }
                        return _buildItemCard(material, prItems);
                      }),
                      if (generalStockMaterials.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'General Stock Items',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ...generalStockMaterials
                            .map((material) => _buildItemCard(material, [])),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showAddNewItemDialog(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Item'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _transportController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Transport',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _deliveryRequirementsController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Requirements',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _termsAndConditionsController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 2,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'PO Terms & Conditions (Optional)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        ...qtyControllers.values
                            .expand((controllers) => controllers.values),
                        ...prQtyControllers.values
                            .expand((controllers) => controllers.values),
                      ]),
                      builder: (context, _) {
                        double total = 0;

                        // Calculate total for PR-based items and general stock items
                        for (var entry in selectedPRs.entries) {
                          final material =
                              materials.firstWhereOrNull((m) => m.partNo == entry.key);
                          if (material == null) {
                            continue; // skip missing materials
                          }

                          // Get the vendor rate for this material; fallback to existing PO item cost when missing
                          final vendorRate =
                              material.getRateForVendor(selectedSupplier!.name);
                          double costPerUnit;
                          if (vendorRate != null) {
                            costPerUnit = double.parse(vendorRate.purchaseRate);
                          } else {
                            final existingItem = poItems.firstWhereOrNull(
                                (i) => i.materialCode == material.partNo);
                            costPerUnit =
                                double.tryParse(existingItem?.costPerUnit ?? '') ?? 0.0;
                          }

                          // Calculate total for general stock
                          if (entry.value['General'] == true) {
                            final controller =
                                prQtyControllers[entry.key]?['General'];
                            if (controller != null) {
                              final qty = double.tryParse(controller.text) ?? 0;
                              total += costPerUnit * qty;
                            }
                          }

                          // Calculate total for PR items
                          final prItems = materialPRItems[entry.key] ?? [];
                          for (var prItem in prItems) {
                            if (entry.value[prItem.prNo] == true) {
                              final controller =
                                  prQtyControllers[entry.key]?[prItem.prNo];
                              if (controller != null) {
                                final qty = double.tryParse(controller.text) ?? 0;
                                total += costPerUnit * qty;
                              }
                            }
                          }
                        }

                        // Calculate GST
                        final igst = total *
                            (double.tryParse(
                                    selectedSupplier!.igst.replaceAll('%', '')) ??
                                0) /
                            100;
                        final cgst = total *
                            (double.tryParse(
                                    selectedSupplier!.cgst.replaceAll('%', '')) ??
                                0) /
                            100;
                        final sgst = total *
                            (double.tryParse(
                                    selectedSupplier!.sgst.replaceAll('%', '')) ??
                                0) /
                            100;
                        final grandTotal = total + igst + cgst + sgst;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Sub Total: ₹${total.toStringAsFixed(2)}'),
                            if (igst > 0)
                              Text(
                                  'IGST (${selectedSupplier!.igst}): ₹${igst.toStringAsFixed(2)}'),
                            if (cgst > 0)
                              Text(
                                  'CGST (${selectedSupplier!.cgst}): ₹${cgst.toStringAsFixed(2)}'),
                            if (sgst > 0)
                              Text(
                                  'SGST (${selectedSupplier!.sgst}): ₹${sgst.toStringAsFixed(2)}'),
                            const Divider(),
                            Text(
                              'Grand Total: ₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Purchase Order",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddNewItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _showSingleItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Single Item'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showBulkEntryDialog(context),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add Multiple Items'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSingleItemDialog(BuildContext context) {
    MaterialItem? selectedMaterial;
    final qtyController = TextEditingController();
    final materials = ref.read(materialListProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Single Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<MaterialItem>(
              decoration: const InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              items: materials
                  .where((m) {
                    // Only show materials that:
                    // 1. Have rates for the selected supplier
                    // 2. Are not already in the PR list
                    final hasRate =
                        m.getRateForVendor(selectedSupplier!.name) != null;
                    final notInPRs = !materialPRItems.containsKey(m.partNo);
                    return hasRate && notInPRs;
                  })
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.partNo} - ${m.description}'),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedMaterial = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: qtyController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedMaterial != null && qtyController.text.isNotEmpty) {
                final qty = double.tryParse(qtyController.text);
                if (qty != null && qty > 0) {
                  setState(() {
                    // Add to general stock items
                    selectedPRs.putIfAbsent(
                        selectedMaterial!.partNo, () => {})['General'] = true;
                    prQtyControllers.putIfAbsent(
                            selectedMaterial!.partNo, () => {})['General'] =
                        TextEditingController(text: qty.toString());

                    // Show General Stock row by default for manually added items
                    showGeneralStock[selectedMaterial!.partNo] = true;

                    // Add an empty PR items list for this material
                    materialPRItems[selectedMaterial!.partNo] = [];
                  });
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showBulkEntryDialog(BuildContext context) {
    final materialCodesController = TextEditingController();
    final quantitiesController = TextEditingController();
    bool isQuantityStep = false;
    List<String> materialCodes = [];
    final materials = ref.read(materialListProvider);

    String norm(String s) => s
        .replaceAll('\r', '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
                isQuantityStep ? 'Enter Quantities' : 'Enter Material Codes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isQuantityStep) ...[
                  const Text(
                    'Enter material codes, one per line:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: materialCodesController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g.\nM001\nM002\nM003',
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Enter quantities in the same order:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantitiesController,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText:
                          'Enter quantities for:\n${materialCodes.join('\n')}',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!isQuantityStep) {
                    // Process material codes
                    materialCodes = materialCodesController.text
                        .split(RegExp(r'[\n,]+'))
                        .where((code) => code.trim().isNotEmpty)
                        .map((code) => code.trim())
                        .toList();

                    if (materialCodes.isEmpty) {
                      return;
                    }

                    final invalidCodes = <String>[];
                    final noRateCodes = <String>[];
                    final alreadyAddedCodes = <String>[];
                    final duplicateCodes = <String>[];

                    final seen = <String>{};
                    final canonicalCodes = <String>[];

                    for (final code in materialCodes) {
                      final matched = materials.firstWhereOrNull(
                        (m) => norm(m.partNo) == norm(code),
                      );

                      if (matched == null) {
                        invalidCodes.add(code);
                        continue;
                      }

                      // Prevent duplicates in the pasted list
                      final key = matched.partNo;
                      if (seen.contains(key)) {
                        duplicateCodes.add(key);
                        continue;
                      }
                      seen.add(key);

                      // Prevent adding a material already present in PR-based list or already added manually
                      if (materialPRItems.containsKey(key) ||
                          selectedPRs.containsKey(key)) {
                        alreadyAddedCodes.add(key);
                        continue;
                      }

                      // Ensure supplier has a rate
                      if (matched.getRateForVendor(selectedSupplier!.name) ==
                          null) {
                        noRateCodes.add(key);
                        continue;
                      }

                      canonicalCodes.add(key);
                    }

                    if (invalidCodes.isNotEmpty ||
                        duplicateCodes.isNotEmpty ||
                        alreadyAddedCodes.isNotEmpty ||
                        noRateCodes.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Invalid Material Codes'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (invalidCodes.isNotEmpty) ...[
                                const Text(
                                    'The following codes were not found:'),
                                const SizedBox(height: 8),
                                Text(invalidCodes.join('\n')),
                                const SizedBox(height: 16),
                              ],
                              if (duplicateCodes.isNotEmpty) ...[
                                const Text('Duplicate codes in input:'),
                                const SizedBox(height: 8),
                                Text(duplicateCodes.join('\n')),
                                const SizedBox(height: 16),
                              ],
                              if (alreadyAddedCodes.isNotEmpty) ...[
                                const Text('Already added to this PO:'),
                                const SizedBox(height: 8),
                                Text(alreadyAddedCodes.join('\n')),
                                const SizedBox(height: 16),
                              ],
                              if (noRateCodes.isNotEmpty) ...[
                                const Text('No supplier rates found for:'),
                                const SizedBox(height: 8),
                                Text(noRateCodes.join('\n')),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    materialCodes = canonicalCodes;

                    setState(() {
                      isQuantityStep = true;
                    });
                  } else {
                    // Process quantities
                    final quantities = quantitiesController.text
                        .split(RegExp(r'[\n,]+'))
                        .where((qty) => qty.trim().isNotEmpty)
                        .map((qty) => qty.trim())
                        .toList();

                    if (quantities.length != materialCodes.length) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Quantity Mismatch'),
                          content: Text(
                              'Please enter ${materialCodes.length} quantities, one for each material code.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Validate quantity numbers (positive)
                    final invalidQtyRows = <int>[];
                    for (var i = 0; i < quantities.length; i++) {
                      final q = double.tryParse(quantities[i]);
                      if (q == null || q <= 0) {
                        invalidQtyRows.add(i + 1);
                      }
                    }

                    if (invalidQtyRows.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Invalid Quantities'),
                          content: Text(
                              'Please enter valid quantities (> 0). Invalid rows: ${invalidQtyRows.join(', ')}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Add all items
                    this.setState(() {
                      for (var i = 0; i < materialCodes.length; i++) {
                        final material = materials.firstWhere(
                          (m) => m.partNo == materialCodes[i],
                        );
                        final quantity = quantities[i];

                        // Add to general stock items
                        selectedPRs.putIfAbsent(
                            material.partNo, () => {})['General'] = true;
                        prQtyControllers.putIfAbsent(
                                material.partNo, () => {})['General'] =
                            TextEditingController(text: quantity);

                        // Show General Stock row by default for manually added items
                        showGeneralStock[material.partNo] = true;

                        // Add an empty PR items list for this material
                        materialPRItems[material.partNo] = [];
                      }
                    });

                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: Text(isQuantityStep ? 'Add Items' : 'Next'),
              ),
            ],
          );
        },
      ),
    );
  }
}
