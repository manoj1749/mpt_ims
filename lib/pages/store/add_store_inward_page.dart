// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../provider/material_provider.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../provider/supplier_provider.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_order.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AddStoreInwardPage extends ConsumerStatefulWidget {
  const AddStoreInwardPage({super.key});

  @override
  ConsumerState<AddStoreInwardPage> createState() => _AddStoreInwardPageState();
}

class _AddStoreInwardPageState extends ConsumerState<AddStoreInwardPage> {
  final _formKey = GlobalKey<FormState>();
  final _grnDateController = TextEditingController();
  final _poNoController = TextEditingController();
  final _poDateController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();
  final List<InwardItem> _items = [];

  Supplier? selectedSupplier;
  PurchaseOrder? selectedPO;

  // Map to store material slNo for each materialCode
  final Map<String, String> _materialSlNoMap = {};

  @override
  void initState() {
    super.initState();
    // Set current date as default GR date
    _grnDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _grnDateController.dispose();
    _poNoController.dispose();
    _poDateController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _invoiceAmountController.dispose();
    _receivedByController.dispose();
    _checkedByController.dispose();
    super.dispose();
  }

  void _onPOSelected(PurchaseOrder po) {
    setState(() {
      selectedPO = po;
      _poNoController.text = po.poNo;
      _poDateController.text = po.poDate;
      _invoiceAmountController.text = po.grandTotal.toString();

      // Clear existing items
      _items.clear();
      _materialSlNoMap.clear();

      // Add items from PO
      final materials = ref.read(materialListProvider);
      for (final poItem in po.items) {
        // Find the material by partNo to get its slNo
        final material = materials.firstWhere(
          (m) => m.partNo == poItem.materialCode,
          orElse: () =>
              throw Exception('Material not found: ${poItem.materialCode}'),
        );

        // Store the mapping
        _materialSlNoMap[poItem.materialCode] = material.slNo;

        _items.add(
          InwardItem(
            materialCode: poItem.materialCode,
            materialDescription: poItem.materialDescription,
            unit: poItem.unit,
            orderedQty: double.parse(poItem.quantity),
            receivedQty: double.parse(poItem.quantity),
            acceptedQty: double.parse(poItem.quantity),
            rejectedQty: 0,
            costPerUnit: poItem.costPerUnit,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inwardNotifier = ref.read(storeInwardProvider.notifier);
    final vendorRateNotifier = ref.read(vendorMaterialRateProvider.notifier);
    final suppliers = ref.watch(supplierListProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);

    // Filter POs based on selected supplier
    final supplierPOs = selectedSupplier != null
        ? purchaseOrders
            .where((po) => po.supplierName == selectedSupplier!.name)
            .toList()
        : <PurchaseOrder>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Store Inward')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField(_grnDateController, 'GR Date', isDate: true),

              // Supplier Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField2<Supplier>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Supplier',
                    border: OutlineInputBorder(),
                  ),
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
                  onChanged: (val) {
                    setState(() {
                      selectedSupplier = val;
                      selectedPO = null;
                      _poNoController.clear();
                      _poDateController.clear();
                      _invoiceAmountController.clear();
                    });
                  },
                  validator: (val) =>
                      val == null ? 'Please select a supplier' : null,
                ),
              ),

              // PO Dropdown
              if (selectedSupplier != null && supplierPOs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Order',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedPO?.poNo,
                    items: supplierPOs.map((po) {
                      return DropdownMenuItem<String>(
                        value: po.poNo,
                        child: Text(
                          '${po.poNo} (${po.poDate})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final po =
                            supplierPOs.firstWhere((po) => po.poNo == val);
                        _onPOSelected(po);
                      }
                    },
                    validator: (val) =>
                        val == null ? 'Please select a purchase order' : null,
                  ),
                ),

              // Read-only PO fields
              buildTextField(_poNoController, 'PO No', readOnly: true),
              buildTextField(_poDateController, 'PO Date', readOnly: true),

              buildTextField(_invoiceNoController, 'Invoice No'),
              buildTextField(_invoiceDateController, 'Invoice Date',
                  isDate: true),
              buildTextField(_invoiceAmountController, 'Invoice Amount',
                  readOnly: true),
              buildTextField(_receivedByController, 'Received By'),
              buildTextField(_checkedByController, 'Checked By'),
              const SizedBox(height: 20),

              // Items Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showAddItemDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No items added yet.\nClick the Add Item button to add items.',
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
                                    Text('Ordered Qty: ${item.orderedQty}'),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'Accepted Qty',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            initialValue:
                                                item.acceptedQty.toString(),
                                            onChanged: (value) {
                                              final accepted =
                                                  double.tryParse(value) ?? 0;
                                              setState(() {
                                                item.acceptedQty = accepted;
                                                item.rejectedQty =
                                                    item.receivedQty - accepted;
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
                                            initialValue:
                                                item.rejectedQty.toString(),
                                            onChanged: (value) {
                                              final rejected =
                                                  double.tryParse(value) ?? 0;
                                              setState(() {
                                                item.rejectedQty = rejected;
                                                item.acceptedQty =
                                                    item.receivedQty - rejected;
                                              });
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          onPressed: () {
                                            setState(() {
                                              _items.remove(item);
                                            });
                                          },
                                          color: Colors.red[400],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Create store inward record
                    final inward = StoreInward(
                      grnNo: ref
                          .read(storeInwardProvider.notifier)
                          .generateGRNNumber(),
                      grnDate: _grnDateController.text,
                      supplierName: selectedSupplier!.name,
                      poNo: _poNoController.text,
                      poDate: _poDateController.text,
                      invoiceNo: _invoiceNoController.text,
                      invoiceDate: _invoiceDateController.text,
                      invoiceAmount: _invoiceAmountController.text,
                      receivedBy: _receivedByController.text,
                      checkedBy: _checkedByController.text,
                      items: _items,
                    );

                    try {
                      // Add to inspection stock
                      for (final item in _items) {
                        // Get the material slNo from the map
                        final materialSlNo =
                            _materialSlNoMap[item.materialCode];
                        if (materialSlNo == null) {
                          throw Exception(
                              'Material slNo not found for ${item.materialDescription}');
                        }

                        // Check if vendor material rate exists using slNo
                        final rates = ref
                            .read(vendorMaterialRateProvider.notifier)
                            .getRatesForMaterial(materialSlNo);

                        print(
                            'Looking for rates for material ${item.materialCode} (slNo: $materialSlNo)');
                        print('Found ${rates.length} rates');
                        print(
                            'Vendor IDs: ${rates.map((r) => r.vendorId).join(', ')}');
                        print('Looking for vendor: ${selectedSupplier!.name}');

                        final vendorRate = rates
                            .where((r) => r.vendorId == selectedSupplier!.name)
                            .firstOrNull;
                        if (vendorRate == null) {
                          throw Exception(
                              'No rate found for material ${item.materialDescription} for vendor ${selectedSupplier!.name}');
                        }

                        vendorRateNotifier.addToInspectionStock(
                          materialSlNo, // Use slNo instead of materialCode
                          selectedSupplier!.name,
                          item.receivedQty,
                        );

                        // If items are accepted/rejected, update stocks accordingly
                        if (item.acceptedQty > 0) {
                          vendorRateNotifier.acceptFromInspectionStock(
                            materialSlNo, // Use slNo instead of materialCode
                            selectedSupplier!.name,
                            item.acceptedQty,
                          );
                        }

                        if (item.rejectedQty > 0) {
                          vendorRateNotifier.rejectFromInspectionStock(
                            materialSlNo, // Use slNo instead of materialCode
                            selectedSupplier!.name,
                            item.rejectedQty,
                          );
                        }
                      }

                      inwardNotifier.addInward(inward);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
      {bool isDate = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isDate || readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: isDate && !readOnly
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

  void _showAddItemDialog(BuildContext context) {
    final materialCodeController = TextEditingController();
    final materialDescController = TextEditingController();
    final unitController = TextEditingController();
    final orderedQtyController = TextEditingController();
    final receivedQtyController = TextEditingController();
    final costPerUnitController = TextEditingController();
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
                  final availableMaterials = selectedPO != null
                      ? selectedPO!.items
                          .map((item) => materials
                              .firstWhere((m) => m.partNo == item.materialCode))
                          .toList()
                      : materials;

                  return DropdownButtonFormField2<MaterialItem>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Material',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedMaterial,
                    items: availableMaterials.map((material) {
                      return DropdownMenuItem<MaterialItem>(
                        value: material,
                        child: Text(
                          '${material.partNo} - ${material.description}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedMaterial = val;
                        if (val != null) {
                          materialCodeController.text = val.partNo;
                          materialDescController.text = val.description;
                          unitController.text = val.unit;
                        } else {
                          materialCodeController.clear();
                          materialDescController.clear();
                          unitController.clear();
                        }
                      });
                    },
                    validator: (val) =>
                        val == null ? 'Please select a material' : null,
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
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: materialCodeController,
                decoration: const InputDecoration(
                  labelText: 'Material Code',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: materialDescController,
                decoration: const InputDecoration(
                  labelText: 'Material Description',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderedQtyController,
                decoration: const InputDecoration(
                  labelText: 'Ordered Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: receivedQtyController,
                decoration: const InputDecoration(
                  labelText: 'Received Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costPerUnitController,
                decoration: const InputDecoration(
                  labelText: 'Cost per Unit',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
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

              final orderedQty =
                  double.tryParse(orderedQtyController.text) ?? 0;
              final receivedQty =
                  double.tryParse(receivedQtyController.text) ?? 0;

              // Store the mapping
              _materialSlNoMap[materialCodeController.text] =
                  selectedMaterial!.slNo;

              setState(() {
                _items.add(
                  InwardItem(
                    materialCode: materialCodeController.text,
                    materialDescription: materialDescController.text,
                    unit: unitController.text,
                    orderedQty: orderedQty,
                    receivedQty: receivedQty,
                    acceptedQty:
                        receivedQty, // Initially all received qty is accepted
                    rejectedQty: 0, // Initially no qty is rejected
                    costPerUnit: costPerUnitController.text,
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
