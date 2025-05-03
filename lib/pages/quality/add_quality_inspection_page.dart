import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/quality_inspection.dart';
import '../../models/store_inward.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../provider/store_inward_provider.dart';

class AddQualityInspectionPage extends ConsumerStatefulWidget {
  const AddQualityInspectionPage({super.key});

  @override
  ConsumerState<AddQualityInspectionPage> createState() => _AddQualityInspectionPageState();
}

class _AddQualityInspectionPageState extends ConsumerState<AddQualityInspectionPage> {
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
    _inspectionDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    setState(() {
      selectedGRN = grn;
      _items = grn.items.map((item) {
        final costPerUnit = double.tryParse(item.costPerUnit) ?? 0.0;
        return InspectionItem(
          materialCode: item.materialCode,
          materialDescription: item.materialDescription,
          unit: item.unit,
          category: 'General', // Default category
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
          manufacturingDate: '',
          expiryDate: '',
          parameters: [],
        );
      }).toList();
    });
  }

  void _showAddParametersDialog(InspectionItem item) {
    final parameterController = TextEditingController();
    final specificationController = TextEditingController();
    final observationController = TextEditingController();
    final remarksController = TextEditingController();
    String selectedParameter = QualityParameter.standardParameters[0];
    bool isAcceptable = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inspection Parameter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Parameter',
                  border: OutlineInputBorder(),
                ),
                value: selectedParameter,
                items: QualityParameter.standardParameters.map((param) {
                  return DropdownMenuItem(
                    value: param,
                    child: Text(param),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedParameter = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specificationController,
                decoration: const InputDecoration(
                  labelText: 'Specification',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: observationController,
                decoration: const InputDecoration(
                  labelText: 'Observation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Acceptable'),
                value: isAcceptable,
                onChanged: (value) {
                  setState(() {
                    isAcceptable = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                item.parameters.add(
                  QualityParameter(
                    parameter: selectedParameter,
                    specification: specificationController.text,
                    observation: observationController.text,
                    isAcceptable: isAcceptable,
                    remarks: remarksController.text,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
              buildTextField(_inspectionDateController, 'Inspection Date', isDate: true),
              
              // GRN Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<StoreInward>(
                  value: selectedGRN,
                  decoration: const InputDecoration(
                    labelText: 'Select GRN',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: pendingInwards.map((grn) {
                    return DropdownMenuItem(
                      value: grn,
                      child: Text('${grn.grnNo} (${grn.supplierName})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onGRNSelected(value);
                    }
                  },
                  validator: (value) => value == null ? 'Required' : null,
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
                        ..._items.map((item) => Card(
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
                                          labelText: 'Manufacturing Date/Shelf Life',
                                          border: OutlineInputBorder(),
                                        ),
                                        readOnly: true,
                                        controller: TextEditingController(text: item.manufacturingDate),
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              item.manufacturingDate = DateFormat('yyyy-MM-dd').format(date);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Quality Parameters Section
                                const Text(
                                  'Quality Parameters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...QualityParameter.standardParameters.map((param) {
                                  final existingParam = item.parameters.firstWhere(
                                    (p) => p.parameter == param,
                                    orElse: () => QualityParameter(
                                      parameter: param,
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
                                            param,
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
                                              Container(
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
                                }).toList(),
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
                                          final qty = double.tryParse(value) ?? 0;
                                          setState(() {
                                            item.inspectedQty = qty;
                                          });
                                        },
                                        validator: (value) {
                                          final qty = double.tryParse(value ?? '') ?? 0;
                                          if (qty <= 0) {
                                            return 'Required';
                                          }
                                          if (qty > item.receivedQty) {
                                            return 'Cannot exceed received qty';
                                          }
                                          return null;
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
                                          final accepted = double.tryParse(value) ?? 0;
                                          setState(() {
                                            item.acceptedQty = accepted;
                                            item.rejectedQty = item.inspectedQty - accepted;
                                          });
                                        },
                                        validator: (value) {
                                          final qty = double.tryParse(value ?? '') ?? 0;
                                          if (qty < 0) return 'Invalid quantity';
                                          if (qty > item.inspectedQty) {
                                            return 'Cannot exceed inspected qty';
                                          }
                                          return null;
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
                                          final rejected = double.tryParse(value) ?? 0;
                                          setState(() {
                                            item.rejectedQty = rejected;
                                            item.acceptedQty = item.inspectedQty - rejected;
                                          });
                                        },
                                        validator: (value) {
                                          final qty = double.tryParse(value ?? '') ?? 0;
                                          if (qty < 0) return 'Invalid quantity';
                                          if (qty > item.inspectedQty) {
                                            return 'Cannot exceed inspected qty';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
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
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Usage Decision',
                                          border: OutlineInputBorder(),
                                        ),
                                        value: item.usageDecision == 'Pending' ? 'Lot Accepted' : item.usageDecision,
                                        items: const [
                                          DropdownMenuItem(value: 'Lot Accepted', child: Text('Lot Accepted')),
                                          DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                                          DropdownMenuItem(value: '100% Recheck', child: Text('100% Recheck')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              item.usageDecision = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && selectedGRN != null) {
                    // Create quality inspection record
                    final inspection = QualityInspection(
                      inspectionNo: ref.read(qualityInspectionProvider.notifier).generateInspectionNumber(),
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

                    ref.read(qualityInspectionProvider.notifier).addInspection(inspection);
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
} 