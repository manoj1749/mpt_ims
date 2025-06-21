// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, avoid_print, unnecessary_null_comparison

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
import '../../models/category.dart';
import '../../provider/category_provider.dart';
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
  final Map<String, Map<String, TextEditingController>> _prQtyControllers = {};

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

    // Group items by material and GRN
    final materialGRNItems =
        <String, Map<String, List<Map<String, dynamic>>>>{};
    final grnInfo = <String, Map<String, String>>{};

    // Track inspected quantities per material and GRN
    final inspectedQtys = <String, Map<String, double>>{};

    // First, gather all inspected quantities
    for (var inspection in inspections) {
      for (var item in inspection.items) {
        inspectedQtys.putIfAbsent(item.materialCode, () => {});

        for (var grnEntry in item.grnQuantities.entries) {
          final grnNo = grnEntry.key;
          final grnQty = grnEntry.value;
          final inspectedQty = grnQty.acceptedQty + grnQty.rejectedQty;

          inspectedQtys[item.materialCode]![grnNo] =
              (inspectedQtys[item.materialCode]![grnNo] ?? 0.0) + inspectedQty;
        }
      }
    }

    // Now process GRNs and check against inspected quantities
    for (var grn in inwards) {
      // Skip GRNs that are fully inspected
      if (grn.isFullyInspected) continue;

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
        if (!category.requiresQualityCheck) continue;

        // Get inspected quantity for this material and GRN
          final inspectedQty =
            inspectedQtys[inwardItem.materialCode]?[grn.grnNo] ?? 0.0;
        final remainingQty = inwardItem.receivedQty - inspectedQty;

          // Only include if there's remaining quantity to inspect
        if (remainingQty > 0) {
          // Store item data
            final itemData = {
              'materialCode': inwardItem.materialCode,
              'materialDescription': inwardItem.materialDescription,
              'unit': inwardItem.unit,
              'costPerUnit': inwardItem.costPerUnit,
            'quantity': remainingQty,
            'poNo': grn.poNo,
            'poDate': grn.poDate,
          };

          // Group by material and GRN
          materialGRNItems
              .putIfAbsent(inwardItem.materialCode, () => {})
              .putIfAbsent(grn.grnNo, () => [])
                .add(itemData);

            // Store GRN info
          grnInfo[grn.grnNo] = {
              'grnDate': grn.grnDate,
              'invoiceNo': grn.invoiceNo,
              'invoiceDate': grn.invoiceDate,
            'supplierName': grn.supplierName,
          };
        }
      }
    }

    setState(() {
      _items = [];

      // Process each material
      for (var materialEntry in materialGRNItems.entries) {
        final materialCode = materialEntry.key;
        final grnItems = materialEntry.value;

        if (grnItems.isEmpty) continue;

        // Get first item to access common properties
        final firstGRN = grnItems.values.first;
        final firstItemData = firstGRN.first;

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

        // Initialize GRN quantities
        final grnQuantities = <String, InspectionGRNQuantity>{};

        // Process each GRN's items
        for (var grnEntry in grnItems.entries) {
          final grnNo = grnEntry.key;
          final items = grnEntry.value;

          final totalQty = items.fold(
              0.0, (sum, item) => sum + (item['quantity'] as double));

          if (totalQty > 0) {
            grnQuantities[grnNo] = InspectionGRNQuantity(
              receivedQty: totalQty,
              acceptedQty: 0,
              rejectedQty: 0,
              usageDecision: 'Lot Accepted',
              poNo: items.first['poNo'],
              poDate: items.first['poDate'],
            );
          }
        }

        // Only create inspection item if there are GRNs with remaining quantities
        if (grnQuantities.isNotEmpty) {
          final inspectionItem = InspectionItem(
            materialCode: materialCode,
            materialDescription: firstItemData['materialDescription'],
            unit: firstItemData['unit'],
            category: material.category,
            receivedQty: grnQuantities.values
                .fold(0.0, (sum, qty) => sum + qty.receivedQty),
            costPerUnit: double.parse(firstItemData['costPerUnit']),
            totalCost: grnQuantities.values.fold(
                0.0,
                (sum, qty) =>
                    sum +
                    qty.receivedQty *
                        (double.tryParse(firstItemData['costPerUnit']) ?? 0.0)),
            sampleSize: 0,
            inspectedQty: 0,
            acceptedQty: 0,
            rejectedQty: 0,
            pendingQty: grnQuantities.values
                .fold(0.0, (sum, qty) => sum + qty.receivedQty),
            usageDecision: 'Lot Accepted',
            receivedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            expirationDate: '',
            parameters: [],
            grnQuantities: grnQuantities,
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
          // Check if any GRN for this item belongs to the selected supplier
          return item.grnQuantities.values.any((grnQty) {
            final inward = ref.read(storeInwardProvider).firstWhere(
                  (inward) => inward.poNo.split(', ').contains(grnQty.poNo),
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
                onPressed: _saveInspection,
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

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Validate that exactly one GR is selected
      for (var item in _items) {
        final selectedGRNs = item.grnQuantities.values.where((grnQty) => grnQty.isSelected == true).length;
        if (selectedGRNs != 1) {
          throw Exception('Please select exactly one GRN for each material');
        }
      }

      // Generate inspection number
      final inspectionNo = ref
          .read(qualityInspectionProvider.notifier)
          .generateInspectionNumber();

      // Create inspection object
      final inspection = QualityInspection(
        inspectionNo: inspectionNo,
        inspectionDate: _inspectionDateController.text,
        grnNo: _items.first.grnQuantities.entries
            .firstWhere((entry) => entry.value.isSelected == true)
            .key,
        supplierName: selectedSupplier!.name,
        poNo: _items.first.grnQuantities.values
            .firstWhere((grnQty) => grnQty.isSelected == true)
            .poNo ?? '',
        billNo: '',
        billDate: '',
        receivedDate: _items.first.receivedDate,
        grnDate: _items.first.grnDate ?? '',
        inspectedBy: _inspectedByController.text,
        approvedBy: _approvedByController.text,
        items: _items,
        status: 'Pending',
      );

      // Add inspection
      ref.read(qualityInspectionProvider.notifier).addInspection(inspection);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving inspection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save inspection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildItemCard(InspectionItem item) {
    // Get standard parameters from provider
    final universalParams = ref.watch(universalParameterProvider);
    final categoryParams = ref.watch(categoryParameterProvider);
    ref.read(purchaseOrderListProvider);
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
              isAcceptable: true,
            )),
        ...categorySpecificParams
            .where((paramName) =>
                !universalParams.any((up) => up.name == paramName))
            .map((paramName) => QualityParameter(
                  parameter: paramName,
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

            // GRN Selection
            Row(
                children: [
                const Text('Select GRN:'),
                ],
            ),
            const SizedBox(height: 16),

            // Individual GRN Inspection
            ...item.grnQuantities.entries.map((entry) {
              final grnNo = entry.key;
              final grnQty = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // GRN Header with Radio button
                    Row(
                            children: [
                        Radio<String>(
                          value: grnNo,
                          groupValue: item.grnQuantities.entries
                              .where((e) => e.value.isSelected == true)
                              .map((e) => e.key)
                              .firstOrNull,
                          onChanged: (value) {
                            setState(() {
                              // Deselect all other GRNs
                              for (var otherGrnQty in item.grnQuantities.values) {
                                otherGrnQty.isSelected = false;
                              }
                              // Select only this GRN
                              grnQty.isSelected = true;
                            });
                          },
                        ),
                        Text('GRN: $grnNo'),
                        const SizedBox(width: 16),
                        Text('Received Qty: ${grnQty.receivedQty}'),
                      ],
                    ),
                    if (grnQty.isSelected == true) ...[
                              const SizedBox(height: 16),
                      // Usage Decision and CAPA in one row
                      Row(
                                  children: [
                                    // Usage Decision Dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: grnQty.usageDecision,
                                      decoration: const InputDecoration(
                                        labelText: 'Usage Decision',
                                        border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Lot Accepted',
                                          child: Text('Lot Accepted'),
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
                              onChanged: (value) async {
                                // Show confirmation dialog for rejection
                                if (value == 'Rejected') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Rejection'),
                                      content: const Text(
                                          'Are you sure you want to reject this lot? This will require CAPA.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                }

                                        setState(() {
                                  grnQty.usageDecision = value!;
                                          if (value != '100% Recheck') {
                                    grnQty.recheckType = null;
                                          }
                                          if (value == 'Rejected' ||
                                              value == '100% Recheck') {
                                            item.capaRequired = true;
                                          }

                                          // Auto-update accepted/rejected quantities
                                          if (value == 'Lot Accepted') {
                                    // Validate parameters before accepting
                                    bool hasInvalidParams = item.parameters
                                        .any((param) => !param.isAcceptable);
                                    if (hasInvalidParams) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Cannot accept lot with failed parameters'),
                                        ),
                                      );
                                      grnQty.usageDecision = 'Rejected';
                                      grnQty.acceptedQty = 0;
                                      grnQty.rejectedQty = grnQty.receivedQty;
                                      return;
                                    }
                                    grnQty.acceptedQty = grnQty.receivedQty;
                                    grnQty.rejectedQty = 0;
                                          } else if (value == 'Rejected') {
                                    grnQty.acceptedQty = 0;
                                    grnQty.rejectedQty = grnQty.receivedQty;
                                          } else if (value == '100% Recheck') {
                                    grnQty.acceptedQty = 0;
                                    grnQty.rejectedQty = 0;
                                  }
                                        });
                                      },
                                    ),
                          ),
                          const SizedBox(width: 16),
                          // CAPA Required Checkbox
                          if (grnQty.usageDecision == 'Rejected' ||
                              grnQty.usageDecision == '100% Recheck')
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('CAPA Required'),
                                value: item.capaRequired ?? false,
                                onChanged: (bool? value) {
                                                  setState(() {
                                    item.capaRequired = value;
                                                  });
                                                },
                                              ),
                                            ),
                        ],
                      ),

                      // Recheck Settings (only if 100% Recheck)
                      if (grnQty.usageDecision == '100% Recheck') ...[
                                      const SizedBox(height: 16),
                        Row(
                                          children: [
                            const Icon(Icons.refresh, size: 16),
                            const SizedBox(width: 8),
                            const Text('Recheck Settings',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                )),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: grnQty.recheckType ?? '100% Acceptance',
                                              decoration: const InputDecoration(
                                                labelText: 'Recheck Type',
                                                border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                                        horizontal: 12,
                                    vertical: 8,
                                              ),
                                ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: '100% Acceptance',
                                    child: Text('100% Acceptance'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'Partial Acceptance',
                                    child: Text('Partial Acceptance'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                    grnQty.recheckType = value;
                                                  item.capaRequired = true;
                                                });
                                              },
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Partial Acceptance Quantities (only if Partial Acceptance)
                      if (grnQty.usageDecision == '100% Recheck' &&
                          grnQty.recheckType == 'Partial Acceptance') ...[
                                      const SizedBox(height: 16),
                        Row(
                                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Accepted Quantity',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  hintText:
                                      'Max: ${grnQty.receivedQty.toString()}',
                                  hintStyle: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                controller: TextEditingController(
                                    text: grnQty.acceptedQty.toString()),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return null;
                                  final qty = double.tryParse(value);
                                  if (qty == null) return 'Invalid number';
                                  if (qty < 0) return 'Cannot be negative';
                                  if (qty > grnQty.receivedQty)
                                    return 'Exceeds received qty';
                                  return null;
                                },
                                onChanged: (value) {
                                  // Allow empty value during editing
                                  if (value.isEmpty) {
                                    setState(() {
                                      grnQty.acceptedQty = 0;
                                      grnQty.rejectedQty = grnQty.receivedQty;
                                    });
                                    return;
                                  }

                                  final qty = double.tryParse(value) ?? 0;
                                  setState(() {
                                    // Auto-adjust if exceeds received quantity
                                    if (qty > grnQty.receivedQty) {
                                      grnQty.acceptedQty = grnQty.receivedQty;
                                      grnQty.rejectedQty = 0;
                                      // Update the text field outside setState
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        final controller =
                                            TextEditingController(
                                                text: grnQty.receivedQty
                                                    .toString());
                                        controller.selection =
                                            TextSelection.fromPosition(
                                                TextPosition(
                                                    offset: controller
                                                        .text.length));
                                        // Find the current focus node
                                        final focusNode =
                                            FocusScope.of(context).focusedChild;
                                        // Update the controller while maintaining focus
                                        setState(() {
                                          controller.text =
                                              grnQty.receivedQty.toString();
                                          if (focusNode != null) {
                                            FocusScope.of(context)
                                                .requestFocus(focusNode);
                                          }
                                        });
                                      });
                                    } else {
                                      grnQty.acceptedQty = qty;
                                      grnQty.rejectedQty =
                                          grnQty.receivedQty - qty;
                                    }
                                  });
                                },
                                onEditingComplete: () {
                                  // Allow zero value when focus is lost
                                  if (grnQty.acceptedQty == 0) {
                                    setState(() {
                                      grnQty.rejectedQty = grnQty.receivedQty;
                                    });
                                  }
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Rejected Quantity',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                readOnly: true,
                                controller: TextEditingController(
                                    text: grnQty.rejectedQty.toString()),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // PR/Job-wise Distribution for Partial Acceptance
                        if (grnQty.acceptedQty > 0) ...[
                          const Text('PR/Job Distribution',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 8),
                          // Get the GRN from store inward provider
                          Builder(builder: (context) {
                            final inwards = ref.watch(storeInwardProvider);
                            final grn = inwards.firstWhere(
                                (g) => g.grnNo == grnNo,
                                orElse: () => StoreInward(
                                    grnNo: '',
                                    grnDate: '',
                                    supplierName: '',
                                    poNo: '',
                                    poDate: '',
                                    invoiceNo: '',
                                    invoiceDate: '',
                                    invoiceAmount: 0,
                                    receivedBy: '',
                                    checkedBy: '',
                                    items: []));

                            if (grn.grnNo.isEmpty)
                              return const SizedBox.shrink();

                            final grnItem = grn.items.firstWhere(
                                (i) => i.materialCode == item.materialCode,
                                orElse: () => InwardItem(
                                    materialCode: '',
                                    materialDescription: '',
                                    unit: '',
                                    orderedQty: 0,
                                    receivedQty: 0,
                                    acceptedQty: 0,
                                    rejectedQty: 0,
                                    costPerUnit: '0'));

                            if (grnItem.materialCode.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              children:
                                  grnItem.prQuantities.entries.map((poEntry) {
                                final poNo = poEntry.key;
                                final prMap = poEntry.value;
                                if (prMap == null)
                                  return const SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PO: $poNo',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    ...prMap.entries.map((prEntry) {
                                              final prNo = prEntry.key;
                                      final originalQty = prEntry.value;
                                      final jobNo = grnItem.prJobNumbers[poNo]
                                              ?[prNo] ??
                                          'General';

                                      // Calculate proportional accepted quantity
                                      final proportion =
                                          originalQty / grnItem.receivedQty;
                                      final suggestedQty =
                                          grnQty.acceptedQty * proportion;

                                      // Initialize controller if not exists
                                      _prQtyControllers[grnNo] ??= {};
                                      _prQtyControllers[grnNo]![
                                              '${poNo}_$prNo'] ??=
                                          TextEditingController(
                                              text: suggestedQty.toString());

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16, bottom: 8),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                              flex: 2,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                        children: [
                                                  Text('PR: $prNo'),
                                                  Text('Job: $jobNo',
                                                            style: TextStyle(
                                                              color: Colors
                                                              .grey[500])),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                            Expanded(
                                                      child: TextFormField(
                                                controller: _prQtyControllers[
                                                    grnNo]!['${poNo}_$prNo'],
                                                decoration: InputDecoration(
                                                  labelText: 'Accepted Qty',
                                                          border:
                                                              const OutlineInputBorder(),
                                                          isDense: true,
                                                  hintText:
                                                      'Max: ${originalQty.toString()}',
                                                        ),
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                        decimal: true),
                                                        validator: (value) {
                                                          if (value == null ||
                                                      value.isEmpty)
                                                    return null;
                                                          final qty =
                                                      double.tryParse(value);
                                                          if (qty == null) {
                                                    return 'Invalid number';
                                                          }
                                                          if (qty < 0) {
                                                    return 'Cannot be negative';
                                                  }
                                                          if (qty > originalQty) {
                                                    return 'Exceeds original qty';
                                                          }
                                                          return null;
                                                        },
                                                        onChanged: (value) {
                                                  // Validate total doesn't exceed accepted qty
                                                  double total = 0;
                                                  _prQtyControllers[grnNo]!
                                                      .forEach(
                                                          (key, controller) {
                                                    if (key !=
                                                        '${poNo}_$prNo') {
                                                      total += double.tryParse(
                                                                        controller
                                                                            .text) ??
                                                          0;
                                                    }
                                                  });
                                                  total +=
                                                      double.tryParse(value) ??
                                                          0;

                                                  if (total >
                                                      grnQty.acceptedQty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Total PR quantities cannot exceed accepted quantity'),
                                                      ),
                                                    );
                                                    _prQtyControllers[grnNo]![
                                                                '${poNo}_$prNo']!
                                                            .text =
                                                        suggestedQty.toString();
                                                  }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                );
                              }).toList(),
                            );
                          }),
                        ],
                      ],

                      // Quality Parameters
                      const SizedBox(height: 16),
                      const Text('Quality Parameters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 8),
                      ...item.parameters.map((param) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(param.parameter),
                              ),
                              const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: param.observation,
                                  decoration: const InputDecoration(
                                    labelText: 'Observation',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      param.observation = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: param.result ?? 'OK',
                                  decoration: const InputDecoration(
                                    labelText: 'Result',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'OK',
                                      child: Text('OK'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'NOT OK',
                                      child: Text('NOT OK'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      param.result = value;
                                      param.isAcceptable = value == 'OK';
                                    });
                                  },
                                ),
                  ),
                ],
              ),
                        );
                      }),
                    ],
                  ],
            ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
