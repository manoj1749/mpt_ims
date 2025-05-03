import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../provider/material_provider.dart';
import '../../models/material_item.dart';

class AddStoreInwardPage extends ConsumerStatefulWidget {
  const AddStoreInwardPage({super.key});

  @override
  ConsumerState<AddStoreInwardPage> createState() => _AddStoreInwardPageState();
}

class _AddStoreInwardPageState extends ConsumerState<AddStoreInwardPage> {
  final _formKey = GlobalKey<FormState>();
  final _grnNoController = TextEditingController();
  final _grnDateController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _poNoController = TextEditingController();
  final _poDateController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();
  final List<InwardItem> _items = [];

  @override
  void dispose() {
    _grnNoController.dispose();
    _grnDateController.dispose();
    _supplierNameController.dispose();
    _poNoController.dispose();
    _poDateController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _invoiceAmountController.dispose();
    _receivedByController.dispose();
    _checkedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inwardNotifier = ref.read(storeInwardProvider.notifier);
    final vendorRateNotifier = ref.read(vendorMaterialRateProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Store Inward')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField(_grnNoController, 'GRN No'),
              buildTextField(_grnDateController, 'GRN Date', isDate: true),
              buildTextField(_supplierNameController, 'Supplier Name'),
              buildTextField(_poNoController, 'PO No'),
              buildTextField(_poDateController, 'PO Date', isDate: true),
              buildTextField(_invoiceNoController, 'Invoice No'),
              buildTextField(_invoiceDateController, 'Invoice Date',
                  isDate: true),
              buildTextField(_invoiceAmountController, 'Invoice Amount'),
              buildTextField(_receivedByController, 'Received By'),
              buildTextField(_checkedByController, 'Checked By'),
              const SizedBox(height: 20),
              // Items list
              ..._items.map((item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Material: ${item.materialDescription}'),
                          Text('Ordered Qty: ${item.orderedQty} ${item.unit}'),
                          Text('Received Qty: ${item.receivedQty} ${item.unit}'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Accepted Qty',
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: item.acceptedQty.toString(),
                                  onChanged: (value) {
                                    final accepted = double.tryParse(value) ?? 0;
                                    setState(() {
                                      item.acceptedQty = accepted;
                                      item.rejectedQty =
                                          item.receivedQty - accepted;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Rejected Qty',
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: item.rejectedQty.toString(),
                                  onChanged: (value) {
                                    final rejected = double.tryParse(value) ?? 0;
                                    setState(() {
                                      item.rejectedQty = rejected;
                                      item.acceptedQty =
                                          item.receivedQty - rejected;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Create store inward record
                    final inward = StoreInward(
                      grnNo: _grnNoController.text,
                      grnDate: _grnDateController.text,
                      supplierName: _supplierNameController.text,
                      poNo: _poNoController.text,
                      poDate: _poDateController.text,
                      invoiceNo: _invoiceNoController.text,
                      invoiceDate: _invoiceDateController.text,
                      invoiceAmount: _invoiceAmountController.text,
                      receivedBy: _receivedByController.text,
                      checkedBy: _checkedByController.text,
                      items: _items,
                    );

                    // Add to inspection stock
                    for (final item in _items) {
                      vendorRateNotifier.addToInspectionStock(
                        item.materialCode,
                        _supplierNameController.text,
                        item.receivedQty,
                      );

                      // If items are accepted/rejected, update stocks accordingly
                      if (item.acceptedQty > 0) {
                        vendorRateNotifier.acceptFromInspectionStock(
                          item.materialCode,
                          _supplierNameController.text,
                          item.acceptedQty,
                        );
                      }

                      if (item.rejectedQty > 0) {
                        vendorRateNotifier.rejectFromInspectionStock(
                          item.materialCode,
                          _supplierNameController.text,
                          item.rejectedQty,
                        );
                      }
                    }

                    inwardNotifier.addInward(inward);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Store Inward'),
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
        readOnly: isDate,
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
            value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final materialCodeController = TextEditingController();
    final materialDescController = TextEditingController();
    final unitController = TextEditingController();
    final orderedQtyController = TextEditingController();
    final receivedQtyController = TextEditingController();
    MaterialItem? selectedMaterial;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final materials = ref.watch(materialListProvider);
                  return DropdownButtonFormField<MaterialItem>(
                    decoration: const InputDecoration(
                      labelText: 'Select Material',
                    ),
                    items: materials.map((material) {
                      return DropdownMenuItem(
                        value: material,
                        child: Text('${material.slNo} - ${material.description}'),
                      );
                    }).toList(),
                    onChanged: (material) {
                      if (material != null) {
                        selectedMaterial = material;
                        materialCodeController.text = material.slNo;
                        materialDescController.text = material.description;
                        unitController.text = material.unit;
                      }
                    },
                  );
                },
              ),
              TextField(
                controller: materialCodeController,
                decoration: const InputDecoration(
                  labelText: 'Material Code',
                ),
                readOnly: true,
              ),
              TextField(
                controller: materialDescController,
                decoration: const InputDecoration(
                  labelText: 'Material Description',
                ),
                readOnly: true,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                ),
                readOnly: true,
              ),
              TextField(
                controller: orderedQtyController,
                decoration: const InputDecoration(
                  labelText: 'Ordered Quantity',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: receivedQtyController,
                decoration: const InputDecoration(
                  labelText: 'Received Quantity',
                ),
                keyboardType: TextInputType.number,
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
              if (selectedMaterial == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a material'),
                  ),
                );
                return;
              }

              final orderedQty = double.tryParse(orderedQtyController.text) ?? 0;
              final receivedQty = double.tryParse(receivedQtyController.text) ?? 0;

              setState(() {
                _items.add(
                  InwardItem(
                    materialCode: materialCodeController.text,
                    materialDescription: materialDescController.text,
                    unit: unitController.text,
                    orderedQty: orderedQty,
                    receivedQty: receivedQty,
                    acceptedQty: receivedQty, // Initially all received qty is accepted
                    rejectedQty: 0, // Initially no qty is rejected
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
}
