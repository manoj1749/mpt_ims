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
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../models/universal_parameter.dart';
import '../../models/category_parameter_mapping.dart';

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
    final inwards = ref.watch(storeInwardProvider);
    final inspections = ref.watch(qualityInspectionProvider);

    // Get all GRNs for this supplier that haven't been fully inspected
    final supplierGRNs = inwards.where((inward) {
      if (inward.supplierName != supplier.name) return false;

      // Check if there's no inspection for this GRN
      final existingInspections = inspections
          .where((inspection) => inspection.grnNo == inward.grnNo)
          .toList();
      return existingInspections.isEmpty;
    }).toList();

    // Group items by material
    final materialItems = <String, List<InwardItem>>{};
    for (var grn in supplierGRNs) {
      for (var item in grn.items) {
        materialItems.putIfAbsent(item.materialCode, () => []).add(item);
      }
    }

    setState(() {
      selectedSupplier = supplier;
      _items = materialItems.entries.map((entry) {
        final materialCode = entry.key;
        final items = entry.value;
        final firstItem = items.first;

        // Find the material to get its category
        final material = materials.firstWhere(
          (m) => m.slNo == materialCode || m.partNo == materialCode,
          orElse: () => materials.firstWhere(
            (m) =>
                m.description.toLowerCase() ==
                firstItem.materialDescription.toLowerCase(),
            orElse: () => MaterialItem(
              slNo: materialCode,
              description: firstItem.materialDescription,
              partNo: materialCode,
              unit: firstItem.unit,
              category: 'General',
              subCategory: '',
            ),
          ),
        );

        // Initialize PO quantities
        final poQuantities = <String, InspectionPOQuantity>{};
        for (var item in items) {
          for (var entry in item.poQuantities.entries) {
            poQuantities[entry.key] = InspectionPOQuantity(
              receivedQty: entry.value,
              acceptedQty: 0,
              rejectedQty: 0,
              usageDecision: 'Lot Accepted',
            );
          }
        }

        return InspectionItem(
          materialCode: materialCode,
          materialDescription: firstItem.materialDescription,
          unit: firstItem.unit,
          category: material.category,
          receivedQty: items.fold(0.0, (sum, item) => sum + item.receivedQty),
          costPerUnit: double.tryParse(firstItem.costPerUnit) ?? 0.0,
          totalCost: items.fold(
              0.0,
              (sum, item) =>
                  sum +
                  (double.tryParse(item.costPerUnit) ?? 0.0) *
                      item.receivedQty),
          sampleSize: 0,
          inspectedQty: 0,
          acceptedQty: 0,
          rejectedQty: 0,
          pendingQty: items.fold(0.0, (sum, item) => sum + item.receivedQty),
          usageDecision: 'Lot Accepted',
          receivedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          expirationDate: '',
          parameters: [],
          isPartialRecheck: false,
          poQuantities: poQuantities,
        );
      }).toList();
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
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedSupplier != null) {
                    // Validate all items
                    bool isValid = true;
                    String errorMessage = '';

                    for (var item in _items) {
                      for (var poEntry in item.poQuantities.entries) {
                        final poQty = poEntry.value;

                        // Check if quantities are valid for partial recheck
                        if (poQty.usageDecision == '100% Recheck' &&
                            item.isPartialRecheck == true) {
                          if (poQty.acceptedQty + poQty.rejectedQty !=
                              poQty.receivedQty) {
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

                        // For Lot Accepted, ensure accepted qty equals received qty
                        if (poQty.usageDecision == 'Lot Accepted' &&
                            poQty.acceptedQty != poQty.receivedQty) {
                          item.updatePOQuantities(
                            poEntry.key,
                            acceptedQty: poQty.receivedQty,
                            rejectedQty: 0,
                          );
                        }

                        // For Rejected, ensure rejected qty equals received qty
                        if (poQty.usageDecision == 'Rejected' &&
                            poQty.rejectedQty != poQty.receivedQty) {
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

                    ref
                        .read(qualityInspectionProvider.notifier)
                        .addInspection(inspection);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Inspection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: isDate,
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

  Widget _buildItemCard(InspectionItem item) {
    // Get standard parameters from provider
    final universalParams = ref.watch(universalParameterProvider);
    final categoryParams = ref.watch(categoryParameterProvider);

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
              observation:
                  categorySpecificParams.contains(param.name) ? '' : 'NA',
              isAcceptable: true,
            )),
        ...categorySpecificParams
            .where((paramName) =>
                !universalParams.any((up) => up.name == paramName))
            .map((paramName) => QualityParameter(
                  parameter: paramName,
                  specification: '',
                  observation: '',
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
                1: FlexColumnWidth(1), // Received
                2: FlexColumnWidth(1), // Accepted
                3: FlexColumnWidth(1), // Rejected
                4: FlexColumnWidth(1.5), // Usage Decision
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

                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.2),
                      ),
                    ),
                    children: [
                      // PO No
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Text(poNo, style: const TextStyle(fontSize: 12)),
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
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem<String>(
                                      value: 'Rejected',
                                      child: Text('Rejected',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem<String>(
                                      value: '100% Recheck',
                                      child: Text('100% Recheck',
                                          style: TextStyle(fontSize: 12))),
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
                                      item.updatePOQuantities(
                                        poNo,
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
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),
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
                0: FlexColumnWidth(2), // Parameter
                1: FlexColumnWidth(2), // Observation
                2: FlexColumnWidth(1), // Acceptable
              },
              children: [
                const TableRow(
                  children: [
                    Text('Parameter',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Observation',
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
                      // Observation
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 32,
                          child: TextFormField(
                            initialValue: param.observation,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 12),
                            onChanged: (value) {
                              setState(() {
                                param.observation = value;
                              });
                            },
                          ),
                        ),
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
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
