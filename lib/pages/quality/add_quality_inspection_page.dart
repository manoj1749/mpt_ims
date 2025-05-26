// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

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
import '../../models/purchase_request.dart';
import '../../provider/purchase_request_provider.dart';
import 'dart:convert';

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
  Map<String, Map<String, bool>> selectedPOs = {};

  @override
  void initState() {
    super.initState();
    // Set current date as default inspection date
    _inspectionDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _inspectionDateController.dispose();
    _inspectedByController.dispose();
    _approvedByController.dispose();
    super.dispose();
  }

  void _onSupplierSelected(Supplier supplier) {
    final materials = ref.read(materialListProvider);
    final inwards = ref
        .watch(storeInwardProvider)
        .where((inward) => inward.supplierName == supplier.name)
        .toList();
    final inspections = ref.watch(qualityInspectionProvider);
    ref.read(purchaseOrderListProvider);
    ref.read(purchaseRequestListProvider);

    // Group items by material and PO
    final materialPOItems = <String, Map<String, List<Map<String, dynamic>>>>{};
    final grnInfo = <String,
        Map<String,
            Map<String, String>>>{}; // materialCode -> poNo -> grnNo -> grnInfo

    // Track inspected quantities per material and PO
    final inspectedQtys =
        <String, Map<String, double>>{}; // materialCode -> poNo -> inspectedQty

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
        materialPOItems.putIfAbsent(inwardItem.materialCode, () => {});
        grnInfo.putIfAbsent(inwardItem.materialCode, () => {});

        final poNos = grn.poNo.split(', ');
        for (var poNo in poNos) {
          final receivedQty = inwardItem.getReceivedQuantityForPO(poNo);
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
              'quantity':
                  receivedQty - inspectedQty, // Only include remaining quantity
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
      selectedSupplier = supplier;
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
            costPerUnit: double.tryParse(firstItemData['costPerUnit']) ?? 0.0,
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

              // Supplier Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField2<Supplier>(
                  decoration: const InputDecoration(
                    labelText: 'Select Supplier',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  value: selectedSupplier,
                  items: suppliers.map((supplier) {
                    return DropdownMenuItem<Supplier>(
                      value: supplier,
                      child: Text(
                        supplier.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onSupplierSelected(value);
                    }
                  },
                  validator: (value) => value == null ? 'Required' : null,
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
              if (_items.isEmpty && selectedSupplier != null)
                        const Center(
                          child: Padding(
                    padding: EdgeInsets.all(16.0),
                            child: Text(
                      'No pending materials for inspection',
                              style: TextStyle(
                                fontSize: 16,
                        color: Colors.grey,
                              ),
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

    if (selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    try {
      // Validate all items
      bool isValid = true;
      String errorMessage = '';

      for (var item in _items) {
        for (var poEntry in item.poQuantities.entries) {
          final poQty = poEntry.value;

          // Check if quantities are valid for partial recheck
          if (poQty.usageDecision == '100% Recheck' &&
              item.isPartialRecheck == true) {
            if (poQty.acceptedQty + poQty.rejectedQty != poQty.receivedQty) {
              isValid = false;
              errorMessage =
                  'Total of accepted and rejected quantities must equal received quantity for ${item.materialDescription}';
              break;
            }

            // Check if conditional acceptance has remarks
            if (item.conditionalAcceptanceReason != null &&
                item.conditionalAcceptanceReason!.isEmpty) {
              isValid = false;
              errorMessage =
                  'Please enter conditional remarks for ${item.materialDescription}';
              break;
            }
          }

          // For Lot Accepted, ensure accepted qty equals received qty and rejected is 0
          if (poQty.usageDecision == 'Lot Accepted') {
            item.updatePOQuantities(
              poEntry.key,
              acceptedQty: poQty.receivedQty,
              rejectedQty: 0,
            );
          }

          // For Rejected, ensure rejected qty equals received qty and accepted is 0
          if (poQty.usageDecision == 'Rejected') {
            item.updatePOQuantities(
              poEntry.key,
              acceptedQty: 0,
              rejectedQty: poQty.receivedQty,
            );
          }
        }
        if (!isValid) break;
      }

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create quality inspection record
      final inspection = QualityInspection(
        inspectionNo: ref
            .read(qualityInspectionProvider.notifier)
            .generateInspectionNumber(),
        inspectionDate: _inspectionDateController.text,
        grnNo: '', // Will be populated when saving
        supplierName: selectedSupplier!.name,
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

      // Update GRN status and collect PR/Job numbers
      final inwards = ref.read(storeInwardProvider);
      final purchaseOrders = ref.read(purchaseOrderListProvider);
      final purchaseRequests = ref.read(purchaseRequestListProvider);
      final prNumbers = <String, String>{};
      final jobNumbers = <String, String>{};

      for (var item in _items) {
        for (var poEntry in item.poQuantities.entries) {
          final poNo = poEntry.key;
          final inspectedQty =
              poEntry.value.acceptedQty + poEntry.value.rejectedQty;

          // Find the GRN and update its item quantities
          final inward = inwards.firstWhere(
            (inward) => inward.poNo.split(', ').contains(poNo),
            orElse: () => throw Exception('GRN not found'),
          );

          // Find the corresponding PO
          final po = purchaseOrders.firstWhere(
            (po) => po.poNo == poNo,
            orElse: () => throw Exception('PO not found'),
          );

          // Find PR numbers and job numbers from PO items
          for (var poItem in po.items) {
            if (poItem.materialCode == item.materialCode) {
              // Get PR numbers from PO item's prQuantities
              final prNos = poItem.prQuantities.keys.toList();
              if (prNos.isNotEmpty) {
                // Find the PR to get its job number
                final pr = purchaseRequests.firstWhere(
                  (pr) => pr.prNo == prNos.first,
                  orElse: () => throw Exception('PR not found'),
                );
                prNumbers[poNo] = prNos.join(', ');
                if (pr.jobNo != null) {
                  jobNumbers[poNo] = pr.jobNo!;
                }
              }
            }
          }

          final inwardItem = inward.items.firstWhere(
            (i) => i.materialCode == item.materialCode,
            orElse: () => throw Exception('GRN item not found'),
          );

          inwardItem.addInspectedQuantity(
              inspection.inspectionNo, inspectedQty);
          inward.updateStatus();
          final index = inwards.indexOf(inward);
          ref.read(storeInwardProvider.notifier).updateInward(index, inward);

          // Update inspection with GRN info from first item
          if (inspection.grnNo.isEmpty) {
            inspection.grnNo = inward.grnNo;
            inspection.poNo = inward.poNo;
            inspection.billNo = inward.invoiceNo;
            inspection.billDate = inward.invoiceDate;
            inspection.grnDate = inward.grnDate;
          }
        }
      }

      // Update inspection with PR and job numbers
      inspection.prNumbers = prNumbers;
      inspection.jobNumbers = jobNumbers;

      ref.read(qualityInspectionProvider.notifier).addInspection(inspection);

      // Update PRs for rejected quantities
      final prBox = ref.read(purchaseRequestBoxProvider);
      final updatedPRs = <int, PurchaseRequest>{};

      for (var item in inspection.items) {
        for (var poEntry in item.poQuantities.entries) {
          final poNo = poEntry.key;
          final poQty = poEntry.value;

          if (poQty.rejectedQty > 0) {
            // Find the PO to get PR references
            final po = purchaseOrders.firstWhere(
              (po) => po.poNo == poNo,
              orElse: () => throw Exception('PO not found'),
            );

            // Find the PO item
            final poItem = po.items.firstWhere(
              (poItem) => poItem.materialCode == item.materialCode,
              orElse: () => throw Exception('PO item not found'),
            );

            // Get PR numbers from PO item's prQuantities
            for (var prEntry in poItem.prQuantities.entries) {
              final prNo = prEntry.key;
              final originalPRQty = prEntry.value;

              // Find PR index
              final prIndex =
                  purchaseRequests.indexWhere((pr) => pr.prNo == prNo);
              if (prIndex == -1) continue;

              // Get PR from box if not already processed
              final pr = updatedPRs[prIndex] ?? prBox.getAt(prIndex);
              if (pr == null) continue;
              updatedPRs[prIndex] = pr;

              // Find and update PR item
              final prItem = pr.items.firstWhere(
                (item) => item.materialCode == poItem.materialCode,
                orElse: () => throw Exception('PR item not found'),
              );

              // Calculate proportion of rejected quantity for this PR
              final prProportion =
                  originalPRQty / double.parse(poItem.quantity);
              final prRejectedQty = poQty.rejectedQty * prProportion;

              // Reduce ordered quantity by rejected amount
              final currentOrderedQty = prItem.orderedQuantities[poNo] ?? 0.0;
              if (currentOrderedQty > 0) {
                prItem.orderedQuantities[poNo] =
                    currentOrderedQty - prRejectedQty;

                // If ordered quantity becomes 0 or negative, remove the PO entry
                if (prItem.orderedQuantities[poNo]! <= 0) {
                  prItem.orderedQuantities.remove(poNo);
                }
              }
            }
          }
        }
      }

      // Update all modified PRs in the box
      for (var entry in updatedPRs.entries) {
        final pr = entry.value;
        // Update status based on remaining ordered quantities
        if (pr.items.every((item) => item.orderedQuantities.isEmpty)) {
          pr.status = 'Draft';
        } else if (pr.items.any((item) => !item.isFullyOrdered)) {
          pr.status = 'Partially Ordered';
        }
        await prBox.putAt(entry.key, pr);
      }

      // Refresh the provider state
      if (updatedPRs.isNotEmpty) {
        ref.read(purchaseRequestListProvider.notifier).state =
            prBox.values.toList();
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving inspection: $e')),
        );
      }
    } finally {
      if (mounted) {}
    }
  }

  Widget _buildItemCard(InspectionItem item) {
    // Get standard parameters from provider
    final universalParams = ref.watch(universalParameterProvider);
    final categoryParams = ref.watch(categoryParameterProvider);
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    final purchaseRequests = ref.read(purchaseRequestListProvider);

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

            // PO-wise Inspection with GRN details
            const Text(
              'PO-wise Inspection',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2), // PO No
                1: FlexColumnWidth(1.5), // PR No
                2: FlexColumnWidth(1), // Job No
                3: FlexColumnWidth(1), // Received
                4: FlexColumnWidth(1), // Accepted
                5: FlexColumnWidth(1), // Rejected
                6: FlexColumnWidth(1.5), // Usage Decision
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('PO No',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('PR No',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('Job No',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('Received',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('Accepted',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('Rejected',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('Usage Decision',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                  ],
                ),
                ...item.poQuantities.entries.map((entry) {
                  final poNo = entry.key;
                  final poQty = entry.value;
                  final grnInfoMap = item.grnDetails[poNo] ?? {};

                  // Find PR and Job numbers for this PO
                  String prNo = '';
                  String jobNo = '';
                  final po = purchaseOrders.firstWhere(
                    (po) => po.poNo == poNo,
                    orElse: () => throw Exception('PO not found'),
                  );

                  // Get PR numbers from PO item's prQuantities
                  final poItem = po.items.firstWhere(
                    (i) => i.materialCode == item.materialCode,
                    orElse: () => throw Exception('PO item not found'),
                  );

                  final prNos = poItem.prQuantities.keys.toList();
                  if (prNos.isNotEmpty) {
                    prNo = prNos.join(', ');
                    // Find the PR to get its job number
                    final pr = purchaseRequests.firstWhere(
                      (pr) => pr.prNo == prNos.first,
                      orElse: () => throw Exception('PR not found'),
                    );
                    if (pr.jobNo != null) {
                      jobNo = pr.jobNo!;
                    }
                  }

                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.2),
                      ),
                    ),
                    children: [
                      // PO No with GRN tooltip
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Tooltip(
                          message: _buildGRNTooltip(grnInfoMap),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(poNo,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                              const Icon(Icons.info_outline, size: 16),
                            ],
                          ),
                        ),
                      ),
                      // PR No
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Text(prNo, style: const TextStyle(fontSize: 12)),
                      ),
                      // Job No
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child:
                            Text(jobNo, style: const TextStyle(fontSize: 12)),
                      ),
                      // Received Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Text(
                          poQty.receivedQty.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Accepted Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Text(
                          poQty.acceptedQty.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Rejected Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Text(
                          poQty.rejectedQty.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Usage Decision
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 36,
                              child: DropdownButtonFormField2<String>(
              decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
                                value: poQty.usageDecision,
              items: const [
                DropdownMenuItem<String>(
                                    value: 'Lot Accepted',
                                    child: Text('Lot Accepted',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                DropdownMenuItem<String>(
                                    value: 'Rejected',
                                    child: Text('Rejected',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                DropdownMenuItem<String>(
                                    value: '100% Recheck',
                                    child: Text('100% Recheck',
                                        style: TextStyle(fontSize: 12)),
                                  ),
              ],
              onChanged: (value) {
                setState(() {
                                    // Reset partial and conditional acceptance when changing decision
                    item.isPartialRecheck = false;
                                    item.conditionalAcceptanceReason = null;

                                    // Update quantities based on decision
                                    if (value == 'Lot Accepted') {
                                      item.updatePOQuantities(
                                        poNo,
                                        acceptedQty: poQty.receivedQty,
                                        rejectedQty: 0,
                                        usageDecision: value,
                                      );
                                    } else if (value == 'Rejected') {
                                      item.updatePOQuantities(
                                        poNo,
                                        acceptedQty: 0,
                                        rejectedQty: poQty.receivedQty,
                                        usageDecision: value,
                                      );
                                    } else {
                                      // For 100% Recheck, reset quantities
                                      item.updatePOQuantities(
                                        poNo,
                                        acceptedQty: 0,
                                        rejectedQty: 0,
                                        usageDecision: value,
                                      );
                  }
                });
              },
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
                              ),
                            ),
                            if (poQty.usageDecision == '100% Recheck') ...[
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: item.isPartialRecheck,
                onChanged: (value) {
                  setState(() {
                                                item.isPartialRecheck = value;
                                                if (value == false) {
                                                  item.conditionalAcceptanceReason =
                                                      null;
                                                  // Reset quantities
                                                  item.updatePOQuantities(
                                                    poNo,
                                                    acceptedQty: 0,
                                                    rejectedQty: 0,
                                                  );
                                                }
                  });
                },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Partial Acceptance',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    if (item.isPartialRecheck == true) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                decoration: const InputDecoration(
                                                labelText: 'Accepted Qty',
                                                isDense: true,
                  border: OutlineInputBorder(),
                                              ),
                                              initialValue:
                                                  poQty.acceptedQty.toString(),
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              keyboardType:
                                                  TextInputType.number,
                validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Required';
                                                }
                                                final qty =
                                                    double.tryParse(value);
                                                if (qty == null) {
                                                  return 'Invalid number';
                                                }
                                                if (qty < 0 ||
                                                    qty > poQty.receivedQty) {
                                                  return 'Invalid quantity';
                  }
                  return null;
                },
                onChanged: (value) {
                                                final qty =
                                                    double.tryParse(value) ?? 0;
                                                if (qty >= 0 &&
                                                    qty <= poQty.receivedQty) {
                  setState(() {
                                                    item.updatePOQuantities(
                                                      poNo,
                                                      acceptedQty: qty,
                                                      rejectedQty:
                                                          poQty.receivedQty -
                                                              qty,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                                                labelText: 'Rejected Qty',
                                                isDense: true,
                          border: OutlineInputBorder(),
                        ),
                                              initialValue:
                                                  poQty.rejectedQty.toString(),
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Required';
                                                }
                                                final qty =
                                                    double.tryParse(value);
                                                if (qty == null) {
                                                  return 'Invalid number';
                                                }
                                                if (qty < 0 ||
                                                    qty > poQty.receivedQty) {
                                                  return 'Invalid quantity';
                                                }
                                                return null;
                                              },
                        onChanged: (value) {
                                                final qty =
                                                    double.tryParse(value) ?? 0;
                                                if (qty >= 0 &&
                                                    qty <= poQty.receivedQty) {
                          setState(() {
                                                    item.updatePOQuantities(
                                                      poNo,
                                                      rejectedQty: qty,
                                                      acceptedQty:
                                                          poQty.receivedQty -
                                                              qty,
                                                    );
                                                  });
                                                }
                        },
                      ),
                    ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Checkbox(
                                              value:
                                                  item.conditionalAcceptanceReason !=
                                                      null,
                        onChanged: (value) {
                          setState(() {
                                                  if (value == true) {
                                                    item.conditionalAcceptanceReason =
                                                        '';
                                                  } else {
                                                    item.conditionalAcceptanceReason =
                                                        null;
                                                  }
                          });
                        },
                      ),
                    ),
                                          const SizedBox(width: 8),
                                          const Text('Conditional Acceptance',
                                              style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      if (item.conditionalAcceptanceReason !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        TextFormField(
                        decoration: const InputDecoration(
                                            labelText: 'Conditional Remark',
                                            isDense: true,
                          border: OutlineInputBorder(),
                                            hintText:
                                                'Enter conditions for acceptance',
                                          ),
                                          initialValue:
                                              item.conditionalAcceptanceReason,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter conditional remarks';
                                            }
                                            return null;
                                          },
                        onChanged: (value) {
                          setState(() {
                                              item.conditionalAcceptanceReason =
                                                  value;
                          });
                        },
                                        ),
                                      ],
                                    ],
                                  ],
                      ),
                    ),
                            ],
                  ],
                        ),
                ),
              ],
                  );
                }),
            ],
            ),
              const SizedBox(height: 16),

            // Quality Parameters
              const Text(
                'Quality Parameters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3), // Parameter
                1: FlexColumnWidth(1), // Acceptable
              },
                      children: [
                const TableRow(
                  children: [
                    Text('Parameter',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Acceptable',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
                ...item.parameters.map((param) {
                  return TableRow(
                          children: [
                      // Parameter
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(param.parameter,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      // Acceptable
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Checkbox(
                          value: param.isAcceptable,
                                onChanged: (value) {
                                  setState(() {
                              param.isAcceptable = value ?? true;
                                  });
                                },
                              ),
                            ),
                          ],
                );
              }),
            ],
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
