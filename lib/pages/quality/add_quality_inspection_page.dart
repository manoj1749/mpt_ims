// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/quality_inspection.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../provider/material_provider.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/purchase_request_provider.dart';
import 'dart:convert';
import '../../models/category.dart';
import '../../provider/category_provider.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../models/store_inward.dart';

class AddQualityInspectionPage extends ConsumerStatefulWidget {
  const AddQualityInspectionPage({super.key});

  @override
  ConsumerState<AddQualityInspectionPage> createState() =>
      _AddQualityInspectionPageState();
}

class _AddQualityInspectionPageState
    extends ConsumerState<AddQualityInspectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _inspectionDateController = TextEditingController();
  final _inspectedByController = TextEditingController();
  final _approvedByController = TextEditingController();

  Supplier? selectedSupplier;
  List<InspectionItem> _items = [];
  Map<String, Map<String, TextEditingController>> _prQtyControllers = {};

  @override
  void initState() {
    super.initState();
    // Set current date as default inspection date
    _inspectionDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Load all pending items when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllPendingItems();
    });
  }

  @override
  void dispose() {
    _inspectionDateController.dispose();
    _inspectedByController.dispose();
    _approvedByController.dispose();
    super.dispose();
  }

  void _loadAllPendingItems() {
    final materials = ref.read(materialListProvider);
    final inwards = ref.watch(storeInwardProvider);
    final inspections = ref.watch(qualityInspectionProvider);
    final categories = ref.watch(categoryListProvider);
    ref.read(purchaseOrderListProvider);
    ref.read(purchaseRequestListProvider);

    // Group items by material and PO
    final materialPOItems = <String, Map<String, List<Map<String, dynamic>>>>{};
    final grnInfo = <String, Map<String, Map<String, String>>>{};

    // Track inspected quantities per material and PO
    final inspectedQtys = <String, Map<String, double>>{};

    // First, gather all inspected quantities
    for (var inspection in inspections) {
      for (var item in inspection.items) {
        inspectedQtys.putIfAbsent(item.materialCode, () => {});

        for (var poEntry in item.poQuantities.entries) {
          final poNo = poEntry.key;
          final poQty = poEntry.value;
          final inspectedQty = poQty.acceptedQty + poQty.rejectedQty;

          inspectedQtys[item.materialCode]![poNo] =
              (inspectedQtys[item.materialCode]![poNo] ?? 0.0) + inspectedQty;
        }
      }
    }

    // Now process GRNs and check against inspected quantities
    for (var grn in inwards) {
      for (var inwardItem in grn.items) {
        // Find the material to get its category
        final material = materials.firstWhere(
          (m) =>
              m.partNo == inwardItem.materialCode ||
              m.slNo == inwardItem.materialCode,
          orElse: () => MaterialItem(
            slNo: inwardItem.materialCode,
            description: inwardItem.materialDescription,
            partNo: inwardItem.materialCode,
            unit: inwardItem.unit,
            category: 'General',
            subCategory: '',
          ),
        );

        // Get the category settings
        final category = categories.firstWhere(
          (c) => c.name == material.category,
          orElse: () => Category(name: material.category),
        );

        // Skip items that don't require quality inspection
        if (!category.requiresQualityCheck) {
          continue;
        }

        materialPOItems.putIfAbsent(inwardItem.materialCode, () => {});
        grnInfo.putIfAbsent(inwardItem.materialCode, () => {});

        final poNos = grn.poNo.split(', ');
        for (var poNo in poNos) {
          // Get total received quantity for this PO
          final receivedQty = inwardItem.getTotalQuantityForPO(poNo);
          if (receivedQty <= 0) continue;

          // Get inspected quantity for this material and PO
          final inspectedQty =
              inspectedQtys[inwardItem.materialCode]?[poNo] ?? 0.0;

          // Only include if there's remaining quantity to inspect
          if (receivedQty > inspectedQty) {
            // Store item data as a map
            final itemData = {
              'materialCode': inwardItem.materialCode,
              'materialDescription': inwardItem.materialDescription,
              'unit': inwardItem.unit,
              'costPerUnit': inwardItem.costPerUnit,
              'quantity': receivedQty - inspectedQty,
            };

            materialPOItems[inwardItem.materialCode]!
                .putIfAbsent(poNo, () => [])
                .add(itemData);

            // Store GRN info
            grnInfo[inwardItem.materialCode]!.putIfAbsent(poNo, () => {});
            grnInfo[inwardItem.materialCode]![poNo]![grn.grnNo] = json.encode({
              'grnDate': grn.grnDate,
              'invoiceNo': grn.invoiceNo,
              'invoiceDate': grn.invoiceDate,
              'quantity': receivedQty - inspectedQty,
            });
          }
        }
      }
    }

    setState(() {
      _items = [];

      // Process each material
      for (var materialEntry in materialPOItems.entries) {
        final materialCode = materialEntry.key;
        final poItems = materialEntry.value;

        if (poItems.isEmpty) continue;

        // Get first item to access common properties
        final firstItemData = poItems.values.first.first;

        // Find the material to get its category
        final material = materials.firstWhere(
          (m) => m.slNo == materialCode || m.partNo == materialCode,
          orElse: () => materials.firstWhere(
            (m) =>
                m.description.toLowerCase() ==
                firstItemData['materialDescription'].toLowerCase(),
            orElse: () => MaterialItem(
              slNo: materialCode,
              description: firstItemData['materialDescription'],
              partNo: materialCode,
              unit: firstItemData['unit'],
              category: 'General',
              subCategory: '',
            ),
          ),
        );

        // Initialize PO quantities
        final poQuantities = <String, InspectionPOQuantity>{};
        final grnDetails = <String, Map<String, String>>{};

        // Combine quantities for each PO
        for (var poEntry in poItems.entries) {
          final poNo = poEntry.key;
          final items = poEntry.value;

          final totalQty = items.fold(
              0.0, (sum, item) => sum + (item['quantity'] as double));

          if (totalQty > 0) {
            poQuantities[poNo] = InspectionPOQuantity(
              receivedQty: totalQty,
              acceptedQty: 0,
              rejectedQty: 0,
              usageDecision: 'Lot Accepted',
            );

            // Store GRN details for this PO
            grnDetails[poNo] = grnInfo[materialCode]![poNo]!;
          }
        }

        // Only create inspection item if there are POs with remaining quantities
        if (poQuantities.isNotEmpty) {
          final inspectionItem = InspectionItem(
            materialCode: materialCode,
            materialDescription: firstItemData['materialDescription'],
            unit: firstItemData['unit'],
            category: material.category,
            receivedQty: poQuantities.values
                .fold(0.0, (sum, qty) => sum + qty.receivedQty),
            costPerUnit: double.parse(firstItemData['costPerUnit']),
            totalCost: poQuantities.values.fold(
                0.0,
                (sum, qty) =>
                    sum +
                    qty.receivedQty *
                        (double.tryParse(firstItemData['costPerUnit']) ?? 0.0)),
            sampleSize: 0,
            inspectedQty: 0,
            acceptedQty: 0,
            rejectedQty: 0,
            pendingQty: poQuantities.values
                .fold(0.0, (sum, qty) => sum + qty.receivedQty),
            usageDecision: 'Lot Accepted',
            receivedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            expirationDate: '',
            parameters: [],
            isPartialRecheck: false,
            poQuantities: poQuantities,
            grnDetails: grnDetails,
          );

          _items.add(inspectionItem);
        }
      }
    });
  }

  void _onSupplierSelected(Supplier? supplier) {
    setState(() {
      selectedSupplier = supplier;

      if (supplier == null) {
        // If supplier is cleared, show all items
        _loadAllPendingItems();
      } else {
        // Filter items for selected supplier
        _items = _items.where((item) {
          // Check if any PO for this item belongs to the selected supplier
          return item.poQuantities.keys.any((poNo) {
            final inward = ref.read(storeInwardProvider).firstWhere(
                  (inward) => inward.poNo.split(', ').contains(poNo),
                  orElse: () => throw Exception('GRN not found'),
                );
            return inward.supplierName == supplier.name;
          });
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Quality Inspection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField(_inspectionDateController, 'Inspection Date',
                  isDate: true),

              // Optional Supplier Filter Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField2<Supplier?>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Supplier (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  value: selectedSupplier,
                  items: [
                    const DropdownMenuItem<Supplier?>(
                      value: null,
                      child: Text('All Suppliers'),
                    ),
                    ...suppliers.map((supplier) {
                      return DropdownMenuItem<Supplier>(
                        value: supplier,
                        child: Text(
                          supplier.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: _onSupplierSelected,
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              buildTextField(_inspectedByController, 'Inspected By'),
              buildTextField(_approvedByController, 'Approved By'),

              const SizedBox(height: 20),

              // Material Groups
              if (_items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending materials for inspection',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedSupplier != null
                              ? 'No pending items for ${selectedSupplier!.name}'
                              : 'There are no GRNs pending inspection',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._items.map((item) => _buildItemCard(item)),

              const SizedBox(height: 20),
              FilledButton(
                onPressed: _onSavePressed,
                child: const Text('Save Inspection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {bool isDate = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: isDate || readOnly,
        onTap: isDate
            ? () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  controller.text = DateFormat('yyyy-MM-dd').format(date);
                }
              }
            : null,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      print('\n=== Debug: Starting Inspection Save ===');

      if (_items.isEmpty) {
        print('Error: No items to inspect');
        throw Exception('No items to inspect');
      }

      print('Number of items to inspect: ${_items.length}');

      // Get supplier from the first item's first PO's store inward
      final firstItem = _items.first;
      print('First item: ${firstItem.materialCode}');

      if (firstItem.poQuantities.isEmpty) {
        print('Error: No PO quantities found for first item');
        throw Exception('No PO quantities found for inspection');
      }

      print(
          'PO quantities for first item: ${firstItem.poQuantities.keys.join(', ')}');

      final firstPONo = firstItem.poQuantities.keys.first;
      print('First PO number: $firstPONo');

      final inwards = ref.read(storeInwardProvider);
      print('Total inwards available: ${inwards.length}');
      print('Looking for inward with PO: $firstPONo');

      // Debug print all inwards PO numbers
      for (var inward in inwards) {
        print('Inward ${inward.grnNo} has POs: ${inward.poNo}');
      }

      final inward = inwards.firstWhere(
        (inward) {
          final poNos = inward.poNo.split(', ');
          print('Checking inward ${inward.grnNo} with POs: $poNos');
          return poNos.contains(firstPONo);
        },
        orElse: () {
          print('Error: No inward found containing PO: $firstPONo');
          throw Exception('GRN not found for PO: $firstPONo');
        },
      );

      print('Found inward: ${inward.grnNo} for PO: $firstPONo');

      // Create quality inspection record
      final inspection = QualityInspection(
        inspectionNo: ref
            .read(qualityInspectionProvider.notifier)
            .generateInspectionNumber(),
        inspectionDate: _inspectionDateController.text,
        grnNo: '', // Will be populated when saving
        supplierName: selectedSupplier?.name ?? inward.supplierName,
        poNo: '', // Will be populated when saving
        billNo: '', // Will be populated when saving
        billDate: '', // Will be populated when saving
        receivedDate: _inspectionDateController.text,
        grnDate: _inspectionDateController.text,
        inspectedBy: _inspectedByController.text,
        approvedBy: _approvedByController.text,
        items: _items,
        status: 'Pending',
      );

      print('\nProcessing inspection items...');

      // Update GRN status and collect PR/Job numbers
      final purchaseOrders = ref.read(purchaseOrderListProvider);
      final purchaseRequests = ref.read(purchaseRequestListProvider);
      final prNumbers = <String, String>{};
      final jobNumbers = <String, String>{};
      final inwardNotifier = ref.read(storeInwardProvider.notifier);
      final vendorRateNotifier = ref.read(vendorMaterialRateProvider.notifier);

      for (var item in _items) {
        print('\nProcessing item: ${item.materialCode}');
        print('PO quantities: ${item.poQuantities.keys.join(', ')}');

        for (var poEntry in item.poQuantities.entries) {
          final poNo = poEntry.key;
          final poQty = poEntry.value;
          print('\nProcessing PO: $poNo');
          print(
              'Quantities - Accepted: ${poQty.acceptedQty}, Rejected: ${poQty.rejectedQty}');

          // Find the GRN and update its item quantities
          print('Looking for inward with PO: $poNo');
          final inward = inwards.firstWhere(
            (inward) {
              final poNos = inward.poNo.split(', ');
              print('Checking inward ${inward.grnNo} with POs: $poNos');
              return poNos.contains(poNo);
            },
            orElse: () {
              print('Error: No inward found containing PO: $poNo');
              throw Exception('GRN not found for PO: $poNo');
            },
          );

          print('Found inward: ${inward.grnNo}');

          // Find the inward item
          print(
              'Looking for item ${item.materialCode} in inward ${inward.grnNo}');
          print(
              'Available items in inward: ${inward.items.map((i) => i.materialCode).join(', ')}');

          final inwardItem = inward.items.firstWhere(
            (i) => i.materialCode == item.materialCode,
            orElse: () {
              print(
                  'Error: Item ${item.materialCode} not found in inward ${inward.grnNo}');
              throw Exception(
                  'Inward item not found for material: ${item.materialCode}');
            },
          );

          print('Found inward item: ${inwardItem.materialCode}');

          // Create inspection status
          final inspectionStatus = InspectionQuantityStatus(
            inspectedQty: poQty.acceptedQty + poQty.rejectedQty,
            acceptedQty: poQty.acceptedQty,
            rejectedQty: poQty.rejectedQty,
            status: poQty.usageDecision,
          );

          // Update inward item inspection status
          inwardItem.updateInspectionStatus(
              inspection.inspectionNo, inspectionStatus);

          // Update vendor material rate stock
          if (poQty.acceptedQty > 0) {
            await vendorRateNotifier.acceptFromInspectionStock(
              item.materialCode,
              inward.supplierName,
              poQty.acceptedQty,
            );
          }

          if (poQty.rejectedQty > 0) {
            await vendorRateNotifier.rejectFromInspectionStock(
              item.materialCode,
              inward.supplierName,
              poQty.rejectedQty,
            );
          }

          // Find PR numbers and job numbers from PO items
          print('\nLooking for PO: $poNo');
          print(
              'Available POs: ${purchaseOrders.map((po) => po.poNo).join(', ')}');

          final po = purchaseOrders.firstWhere(
            (po) => po.poNo == poNo,
            orElse: () {
              print('Error: PO $poNo not found in purchase orders');
              throw Exception('PO not found: $poNo');
            },
          );

          print('Found PO: ${po.poNo}');
          print('Looking for item ${item.materialCode} in PO ${po.poNo}');
          print(
              'Available items in PO: ${po.items.map((i) => i.materialCode).join(', ')}');

          final poItem = po.items.firstWhere(
            (i) => i.materialCode == item.materialCode,
            orElse: () {
              print(
                  'Error: Item ${item.materialCode} not found in PO ${po.poNo}');
              throw Exception(
                  'PO item not found for material: ${item.materialCode}');
            },
          );

          print('Found PO item: ${poItem.materialCode}');

          // Get PR numbers for this PO item
          final prNos = poItem.prDetails.values
              .map((detail) => detail.prNo)
              .where((prNo) => prNo != 'General')
              .toList();

          print('PR numbers for PO item: ${prNos.join(', ')}');

          // Get job numbers for these PRs
          final jobNos = prNos
              .map((prNo) {
                print('Looking for PR: $prNo');
                print(
                    'Available PRs: ${purchaseRequests.map((pr) => pr.prNo).join(', ')}');

                final pr = purchaseRequests.firstWhere(
                  (pr) => pr.prNo == prNo,
                  orElse: () {
                    print('Error: PR $prNo not found');
                    throw Exception('PR not found: $prNo');
                  },
                );
                return pr.jobNo ?? '';
              })
              .where((jobNo) => jobNo.isNotEmpty)
              .join(', ');

          print('Job numbers: $jobNos');

          // Display job numbers if available, otherwise show 'General Stock'
          final displayText = jobNos.isNotEmpty ? jobNos : 'General Stock';

          // Find the PR to get its job number
          if (prNos.isNotEmpty) {
            final pr = purchaseRequests.firstWhere(
              (pr) => pr.prNo == prNos.first,
              orElse: () {
                print('Error: PR ${prNos.first} not found for job number');
                throw Exception('PR not found: ${prNos.first}');
              },
            );
            prNumbers[poNo] = displayText;
            if (pr.jobNo != null) {
              jobNumbers[poNo] = pr.jobNo!;
            }
          }

          // Update GRN status
          inward.updateStatus();
          final inwardIndex = inwards.indexOf(inward);
          inwardNotifier.updateInward(inwardIndex, inward);
        }
      }

      print('\nUpdating inspection with PR and job numbers');
      print('PR numbers: $prNumbers');
      print('Job numbers: $jobNumbers');

      // Update inspection with PR and job numbers
      inspection.prNumbers = prNumbers;
      inspection.jobNumbers = jobNumbers;

      // Determine inspection status based on items
      bool hasRejectedItems = false;
      bool hasRecheckItems = false;
      bool allItemsAccepted = true;

      for (var item in inspection.items) {
        for (var poQty in item.poQuantities.values) {
          if (poQty.usageDecision == 'Rejected') {
            hasRejectedItems = true;
            allItemsAccepted = false;
          } else if (poQty.usageDecision == '100% Recheck') {
            hasRecheckItems = true;
            allItemsAccepted = false;
          } else if (poQty.usageDecision == 'Lot Accepted') {
            // Check if all quantities are properly inspected
            if (poQty.acceptedQty + poQty.rejectedQty < poQty.receivedQty) {
              allItemsAccepted = false;
            }
          }
        }
      }

      // Update inspection status
      if (hasRejectedItems) {
        inspection.status = 'Rejected';
      } else if (hasRecheckItems) {
        inspection.status = 'Recheck';
      } else if (allItemsAccepted) {
        inspection.status = 'Approved';
      } else {
        inspection.status = 'Pending';
      }

      print('\nSaving inspection with status: ${inspection.status}');

      // Save the inspection
      ref.read(qualityInspectionProvider.notifier).addInspection(inspection);

      print('Inspection saved successfully');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('\nError saving inspection: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving inspection: $e')),
        );
      }
    }
  }

  Widget _buildItemCard(InspectionItem item) {
    // Get standard parameters from provider
    final universalParams = ref.watch(universalParameterProvider);
    final categoryParams = ref.watch(categoryParameterProvider);
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    ref.read(purchaseRequestListProvider);

    // Get category-specific parameters
    final categorySpecificParams = categoryParams
        .where((mapping) => mapping.category == item.category)
        .expand((mapping) => mapping.parameters)
        .toList();

    // Initialize parameters if not already done
    if (item.parameters.isEmpty) {
      item.parameters = [
        ...universalParams.map((param) => QualityParameter(
              parameter: param.name,
              specification: '',
              isAcceptable: true,
            )),
        ...categorySpecificParams
            .where((paramName) =>
                !universalParams.any((up) => up.name == paramName))
            .map((paramName) => QualityParameter(
                  parameter: paramName,
                  specification: '',
                  isAcceptable: true,
                ))
      ];
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Info
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.materialDescription,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Code: ${item.materialCode} | Unit: ${item.unit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    'Cost/Unit: ₹${item.costPerUnit}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // PO-wise Inspection Table
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PO-wise Inspection',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      return Column(
                        children: item.poQuantities.entries.map((entry) {
                          final currentPoNo = entry.key;
                          final currentPoQty = entry.value;

                          // Find PO and PO item
                          final po = ref.watch(purchaseOrderListProvider).firstWhere(
                            (po) => po.poNo == currentPoNo,
                            orElse: () => throw Exception('PO not found'),
                          );

                          final poItem = po.items.firstWhere(
                            (i) => i.materialCode == item.materialCode,
                            orElse: () => throw Exception('PO item not found'),
                          );

                          // Get PR numbers for this PO item
                          final prNos = poItem.prDetails.values
                              .map((detail) => detail.prNo)
                              .where((prNo) => prNo != 'General')
                              .toList();

                          // Get job numbers for these PRs
                          final jobNos = prNos
                              .map((prNo) {
                                final pr = ref
                                    .read(purchaseRequestListProvider)
                                    .firstWhere((pr) => pr.prNo == prNo);
                                return pr.jobNo ?? '';
                              })
                              .where((jobNo) => jobNo.isNotEmpty)
                              .join(', ');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PO Details Table
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1.2),
                                  1: FlexColumnWidth(1.0),
                                  2: FlexColumnWidth(1.0),
                                  3: FlexColumnWidth(0.8),
                                  4: FlexColumnWidth(0.8),
                                  5: FlexColumnWidth(0.8),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      const TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('PO No',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              )),
                                        ),
                                      ),
                                      const TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('PR No',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              )),
                                        ),
                                      ),
                                      const TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Job No',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              )),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Received',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.end),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Accepted',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.end),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Rejected',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.end),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                    ),
                                    children: [
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(currentPoNo,
                                                    style: const TextStyle(fontSize: 12)),
                                              ),
                                              const Icon(Icons.info_outline, size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(prNos.join(', '),
                                              style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(jobNos.isEmpty ? 'General Stock' : jobNos,
                                              style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('${currentPoQty.receivedQty}',
                                              style: const TextStyle(fontSize: 12),
                                              textAlign: TextAlign.end),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('${currentPoQty.acceptedQty}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[400],
                                              ),
                                              textAlign: TextAlign.end),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('${currentPoQty.rejectedQty}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red[400],
                                              ),
                                              textAlign: TextAlign.end),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Usage Decision and Controls
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Usage Decision Dropdown
                                    DropdownButtonFormField<String>(
                                      value: currentPoQty.usageDecision,
                                      decoration: const InputDecoration(
                                        labelText: 'Usage Decision',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Accepted',
                                          child: Text('Accepted'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Rejected',
                                          child: Text('Rejected'),
                                        ),
                                        DropdownMenuItem(
                                          value: '100% Recheck',
                                          child: Text('100% Recheck'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          currentPoQty.usageDecision = value!;
                                          if (value != '100% Recheck') {
                                            currentPoQty.recheckType = null;
                                          }
                                          if (value == 'Rejected' || value == '100% Recheck') {
                                            item.capaRequired = true;
                                          }
                                        });
                                      },
                                    ),
                                    // CAPA Checkbox
                                    if (currentPoQty.usageDecision == 'Rejected' ||
                                        currentPoQty.usageDecision == '100% Recheck') ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[850],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: item.capaRequired,
                                                onChanged: (value) {
                                                  setState(() {
                                                    item.capaRequired = value ?? false;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('CAPA Required',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      )),
                                                  Text('Corrective Action / Preventive Action',
                                                      style: TextStyle(
                                                          fontSize: 11, color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Recheck Type Dropdown
                                    if (currentPoQty.usageDecision == '100% Recheck') ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[850],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Recheck Details',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                            const SizedBox(height: 12),
                                            DropdownButtonFormField<String>(
                                              value: currentPoQty.recheckType ?? '100% Acceptance',
                                              decoration: const InputDecoration(
                                                labelText: 'Recheck Type',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 12),
                                              ),
                                              isExpanded: true,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: '100% Acceptance',
                                                  child: Text('100% Acceptance',
                                                      style: TextStyle(fontSize: 13)),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'Partial Acceptance',
                                                  child: Text('Partial Acceptance',
                                                      style: TextStyle(fontSize: 13)),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  currentPoQty.recheckType = value;
                                                  item.capaRequired = true;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // PR-wise quantity allocation
                                    if (currentPoQty.usageDecision == '100% Recheck' &&
                                        currentPoQty.recheckType == 'Partial Acceptance') ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[850],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.assignment, size: 16),
                                                const SizedBox(width: 8),
                                                const Text('PR-wise Allocation',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    )),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // PR allocation content
                                            ...poItem.prDetails.entries.map((prEntry) {
                                              final prNo = prEntry.key;
                                              final prDetail = prEntry.value;

                                              // Initialize controller for this PR
                                              _prQtyControllers[currentPoNo]![prNo] ??= TextEditingController(
                                                text: '0.0',
                                              );

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[900],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // PR Info
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(prNo,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w500,
                                                              )),
                                                          if (prDetail.jobNo != 'General')
                                                            Text(prDetail.jobNo,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.grey[400],
                                                                )),
                                                          Text(
                                                            'Ordered: ${prDetail.quantity} ${item.unit}',
                                                            style: const TextStyle(fontSize: 11),
                                                          ),
                                                          Text(
                                                            'Received: ${poItem.getReceivedQuantityForPR(prNo)} ${item.unit}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey[400],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Accept Qty Input
                                                    SizedBox(
                                                      width: 100,
                                                      child: TextFormField(
                                                        controller: _prQtyControllers[currentPoNo]![prNo],
                                                        decoration: InputDecoration(
                                                          labelText: 'Accept',
                                                          border: const OutlineInputBorder(),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 8,
                                                          ),
                                                          suffixText: item.unit,
                                                        ),
                                                        keyboardType: const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                        style: const TextStyle(fontSize: 12),
                                                        validator: (value) {
                                                          if (value == null || value.isEmpty) {
                                                            return 'Required';
                                                          }
                                                          final qty = double.tryParse(value);
                                                          if (qty == null) {
                                                            return 'Invalid';
                                                          }
                                                          if (qty < 0) {
                                                            return 'Invalid';
                                                          }
                                                          final totalReceived = poItem.getReceivedQuantityForPR(prNo);
                                                          if (qty > totalReceived) {
                                                            return 'Max ${totalReceived}';
                                                          }
                                                          return null;
                                                        },
                                                        onChanged: (value) {
                                                          // Update accepted quantity
                                                          final qty = double.tryParse(value) ?? 0.0;
                                                          setState(() {
                                                            currentPoQty.acceptedQty = _prQtyControllers[currentPoNo]!.values
                                                                .map((controller) => double.tryParse(controller.text) ?? 0.0)
                                                                .fold(0.0, (sum, qty) => sum + qty);
                                                            currentPoQty.rejectedQty = currentPoQty.receivedQty - currentPoQty.acceptedQty;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildGRNTooltip(Map<String, String> grnInfoMap) {
    final buffer = StringBuffer();
    buffer.writeln('GRN Details:');

    grnInfoMap.forEach((grnNo, infoJson) {
      final info = json.decode(infoJson) as Map<String, dynamic>;
      buffer.writeln('\nGRN: $grnNo');
      buffer.writeln('Date: ${info['grnDate']}');
      buffer.writeln('Invoice: ${info['invoiceNo']} (${info['invoiceDate']})');
      buffer.writeln('Quantity: ${info['quantity']}');
    });

    return buffer.toString();
  }
}
