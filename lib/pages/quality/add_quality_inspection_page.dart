import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/quality_inspection.dart';
import '../../models/store_inward.dart';
import '../../models/material_item.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
  final _remarksController = TextEditingController();

  StoreInward? selectedGRN;
  List<InspectionItem> _items = [];

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
    _remarksController.dispose();
    super.dispose();
  }

  void _onGRNSelected(StoreInward grn) {
    final materials = ref.read(materialListProvider);

    setState(() {
      selectedGRN = grn;
      _items = grn.items.map((item) {
        final costPerUnit = double.tryParse(item.costPerUnit) ?? 0.0;

        // Find the material to get its category
        final material = materials.firstWhere(
          (m) => m.slNo == item.materialCode || m.partNo == item.materialCode,
          orElse: () => materials.firstWhere(
            (m) =>
                m.description.toLowerCase() ==
                item.materialDescription.toLowerCase(),
            orElse: () => MaterialItem(
              slNo: item.materialCode,
              description: item.materialDescription,
              partNo: item.materialCode,
              unit: item.unit,
              category: 'General',
              subCategory: '',
            ),
          ),
        );

        return InspectionItem(
          materialCode: item.materialCode,
          materialDescription: item.materialDescription,
          unit: item.unit,
          category: material.category,
          receivedQty: item.receivedQty,
          costPerUnit: costPerUnit,
          totalCost: costPerUnit * item.receivedQty,
          sampleSize: 0,
          inspectedQty: 0,
          acceptedQty: 0,
          rejectedQty: 0,
          pendingQty: item.receivedQty,
          remarks: '',
          usageDecision: 'Lot Accepted',
          receivedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          expirationDate: '',
          parameters: [],
          isPartialRecheck: false,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inwards = ref.watch(storeInwardProvider);
    final pendingInwards = inwards.where((inward) {
      // Check if there's no inspection for this GRN
      final existingInspections = ref
          .watch(qualityInspectionProvider)
          .where((inspection) => inspection.grnNo == inward.grnNo)
          .toList();
      return existingInspections.isEmpty;
    }).toList();

    // Reset selectedGRN if it's not in pendingInwards
    if (selectedGRN != null && !pendingInwards.contains(selectedGRN)) {
      setState(() {
        selectedGRN = null;
        _items = [];
      });
    }

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

              // GRN Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField2<StoreInward>(
                  decoration: const InputDecoration(
                    labelText: 'Select GRN',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  value: selectedGRN,
                  items: pendingInwards.map((grn) {
                    return DropdownMenuItem<StoreInward>(
                      value: grn,
                      child: Text(
                        '${grn.grnNo} (${grn.supplierName})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onGRNSelected(value);
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
                  buttonStyleData: const ButtonStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                  ),
                ),
              ),

              buildTextField(_inspectedByController, 'Inspected By'),
              buildTextField(_approvedByController, 'Approved By'),
              buildTextField(_remarksController, 'Remarks', maxLines: 3),
              const SizedBox(height: 20),

              // Items Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No items to inspect.\nSelect a GRN to load items.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._items.map((item) => _buildItemCard(item)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedGRN != null) {
                    // Create quality inspection record
                    final inspection = QualityInspection(
                      inspectionNo: ref
                          .read(qualityInspectionProvider.notifier)
                          .generateInspectionNumber(),
                      inspectionDate: _inspectionDateController.text,
                      grnNo: selectedGRN!.grnNo,
                      supplierName: selectedGRN!.supplierName,
                      poNo: selectedGRN!.poNo,
                      billNo: selectedGRN!.invoiceNo,
                      billDate: selectedGRN!.invoiceDate,
                      receivedDate: selectedGRN!.grnDate,
                      grnDate: selectedGRN!.grnDate,
                      inspectedBy: _inspectedByController.text,
                      approvedBy: _approvedByController.text,
                      remarks: _remarksController.text,
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
      {bool isDate = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isDate,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: isDate
            ? () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  controller.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              }
            : null,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildItemCard(InspectionItem item) {
    // Get the parameter mapping for this item's category
    final mapping = ref
        .watch(categoryParameterProvider.notifier)
        .getMappingForCategory(item.category);

    // Get the universal parameters
    final universalParams = ref.watch(universalParameterProvider);

    // Initialize parameters based on the mapping if not already set
    if (item.parameters.isEmpty) {
      // Initialize parameters with "NA" as default observation for unmapped parameters
      item.parameters = universalParams.map((param) {
        final isMapped = mapping?.parameters.contains(param.name) ?? false;
        return QualityParameter(
          parameter: param.name,
          specification: '',
          observation: isMapped ? '' : 'NA', // Set "NA" for unmapped parameters
          isAcceptable: true,
          remarks: '',
        );
      }).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.materialDescription,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text('Material Code: ${item.materialCode}'),
            Text('Unit: ${item.unit}'),
            Text('Category: ${item.category}'),
            Text('Received Qty: ${item.receivedQty}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Sample Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: item.sampleSize.toString(),
                    onChanged: (value) {
                      final size = double.tryParse(value) ?? 0;
                      setState(() {
                        item.sampleSize = size;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Received Date',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: item.receivedDate),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          item.receivedDate =
                              DateFormat('yyyy-MM-dd').format(date);
                        });
                      }
                    },
                    readOnly: true,
                  ),
                ),
                if (mapping?.requiresExpiryDate ?? false) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Expiration Date',
                        border: OutlineInputBorder(),
                      ),
                      controller:
                          TextEditingController(text: item.expirationDate),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            item.expirationDate =
                                DateFormat('yyyy-MM-dd').format(date);
                          });
                        }
                      },
                      readOnly: true,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField2<String>(
              decoration: const InputDecoration(
                labelText: 'Usage Decision',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              value: item.usageDecision,
              items: const [
                DropdownMenuItem<String>(
                    value: 'Lot Accepted', child: Text('Lot Accepted')),
                DropdownMenuItem<String>(
                    value: 'Rejected', child: Text('Rejected')),
                DropdownMenuItem<String>(
                    value: '100% Recheck', child: Text('100% Recheck')),
                DropdownMenuItem<String>(
                    value: 'Conditionally Accepted',
                    child: Text('Conditionally Accepted')),
              ],
              onChanged: (value) {
                setState(() {
                  item.usageDecision = value!;
                  if (value != '100% Recheck') {
                    item.isPartialRecheck = false;
                  }
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a usage decision' : null,
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 40,
              ),
            ),
            if (item.usageDecision == 'Conditionally Accepted') ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reason for Conditional Acceptance',
                  border: OutlineInputBorder(),
                ),
                initialValue: item.conditionalAcceptanceReason,
                onChanged: (value) {
                  setState(() {
                    item.conditionalAcceptanceReason = value;
                  });
                },
                validator: (value) {
                  if (item.usageDecision == 'Conditionally Accepted' &&
                      (value == null || value.isEmpty)) {
                    return 'Please provide a reason for conditional acceptance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Required Action',
                  border: OutlineInputBorder(),
                ),
                initialValue: item.conditionalAcceptanceAction,
                onChanged: (value) {
                  setState(() {
                    item.conditionalAcceptanceAction = value;
                  });
                },
                validator: (value) {
                  if (item.usageDecision == 'Conditionally Accepted' &&
                      (value == null || value.isEmpty)) {
                    return 'Please specify the required action';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Action Deadline',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                ),
                initialValue: item.conditionalAcceptanceDeadline,
                onChanged: (value) {
                  setState(() {
                    item.conditionalAcceptanceDeadline = value;
                  });
                },
                validator: (value) {
                  if (item.usageDecision == 'Conditionally Accepted') {
                    if (value == null || value.isEmpty) {
                      return 'Please specify the deadline';
                    }
                    try {
                      final date = DateTime.parse(value);
                      if (date.isBefore(DateTime.now())) {
                        return 'Deadline cannot be in the past';
                      }
                    } catch (e) {
                      return 'Please enter a valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ],
            if (item.usageDecision == '100% Recheck') ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Partial Acceptance'),
                value: item.isPartialRecheck ?? false,
                onChanged: (value) {
                  setState(() {
                    item.isPartialRecheck = value;
                    if (!(value ?? false)) {
                      item.inspectedQty = 0;
                      item.acceptedQty = 0;
                      item.rejectedQty = 0;
                    }
                  });
                },
              ),
              if (item.isPartialRecheck ?? false) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Inspected Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: item.inspectedQty.toString(),
                        onChanged: (value) {
                          setState(() {
                            item.inspectedQty = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Accepted Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: item.acceptedQty.toString(),
                        onChanged: (value) {
                          setState(() {
                            item.acceptedQty = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Rejected Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: item.rejectedQty.toString(),
                        onChanged: (value) {
                          setState(() {
                            item.rejectedQty = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (mapping != null && mapping.parameters.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Quality Parameters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...mapping.parameters.map((paramName) {
                final existingParam = item.parameters.firstWhere(
                  (p) => p.parameter == paramName,
                  orElse: () => QualityParameter(
                    parameter: paramName,
                    specification: '',
                    observation: '',
                    isAcceptable: true,
                    remarks: '',
                  ),
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paramName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Observation',
                                  border: OutlineInputBorder(),
                                ),
                                initialValue: existingParam.observation,
                                onChanged: (value) {
                                  setState(() {
                                    existingParam.observation = value;
                                    if (!item.parameters.contains(existingParam)) {
                                      item.parameters.add(existingParam);
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: SwitchListTile(
                                title: const Text('Acceptable'),
                                value: existingParam.isAcceptable,
                                onChanged: (value) {
                                  setState(() {
                                    existingParam.isAcceptable = value;
                                    if (!item.parameters.contains(existingParam)) {
                                      item.parameters.add(existingParam);
                                    }
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: item.remarks,
                    onChanged: (value) {
                      setState(() {
                        item.remarks = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
