// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
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
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();

  Supplier? selectedSupplier;
  Map<String, Map<String, TextEditingController>> poQtyControllers = {};
  Map<String, Map<String, TextEditingController>> receivedQtyControllers = {};
  Map<String, Map<String, bool>> selectedPOs = {};
  bool _isLoading = false;

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
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _invoiceAmountController.dispose();
    _receivedByController.dispose();
    _checkedByController.dispose();
    for (var materialControllers in poQtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    for (var materialControllers in receivedQtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  InwardItem _createInwardItem(MaterialItem material, List<PurchaseOrder> pos) {
    final poQuantities = <String, double>{};
    double totalQty = 0;

    // Store the material slNo mapping
    _materialSlNoMap[material.partNo] = material.slNo;

    for (var po in pos) {
      final poItem = po.items.firstWhere(
        (item) => item.materialCode == material.partNo,
        orElse: () =>
            throw Exception('Material not found in PO: ${material.partNo}'),
      );

      double.parse(poItem.quantity);
      final inwardController = poQtyControllers[material.partNo]?[po.poNo] ??
          TextEditingController(text: '0');
      poQtyControllers
          .putIfAbsent(material.partNo, () => {})
          .putIfAbsent(po.poNo, () => inwardController);

      final inwardQty = double.tryParse(inwardController.text) ?? 0;
      if (inwardQty > 0) {
        poQuantities[po.poNo] = inwardQty;
        totalQty += inwardQty;
      }
    }

    return InwardItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      orderedQty: totalQty,
      receivedQty: totalQty,
      acceptedQty: totalQty,
      rejectedQty: 0,
      costPerUnit: pos.first.items
          .firstWhere((item) => item.materialCode == material.partNo)
          .costPerUnit,
      poQuantities: poQuantities,
    );
  }

  Widget _buildItemCard(MaterialItem material, List<PurchaseOrder> pos) {
    final inwardItem = _createInwardItem(material, pos);

    // Initialize selectedPOs for this material if not already done
    if (!selectedPOs.containsKey(material.partNo)) {
      selectedPOs[material.partNo] = {};
      for (var po in pos) {
        selectedPOs[material.partNo]![po.poNo] = true; // Default to selected
      }
    }

    // Get all store inwards for this material and supplier from the watched provider
    ref
        .watch(storeInwardProvider.notifier)
        .getInwardsByMaterial(material.partNo)
        .where((inward) => inward.supplierName == selectedSupplier!.name)
        .toList();

    // Calculate total received quantity for each PO
    final poReceivedQty = <String, double>{};
    for (var po in pos) {
      // Use the provider's helper method to get total received quantity
      poReceivedQty[po.poNo] = ref
          .read(storeInwardProvider.notifier)
          .getTotalReceivedQuantity(material.partNo, po.poNo);
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
                        material.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Code: ${material.partNo} | Unit: ${material.unit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    'Rate: ₹${inwardItem.costPerUnit}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(0.5), // Checkbox column
                1: FlexColumnWidth(2), // PO No
                2: FlexColumnWidth(1), // Ordered
                3: FlexColumnWidth(1), // Received
                4: FlexColumnWidth(1.5), // Inward Qty
              },
              children: [
                const TableRow(
                  children: [
                    Text(''), // Checkbox header
                    Text('PO No',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Ordered',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Received',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Inward Qty',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
                ...pos.map((po) {
                  final poItem = po.items.firstWhere(
                    (item) => item.materialCode == material.partNo,
                  );
                  final orderedQty = double.parse(poItem.quantity);
                  final receivedQty = poReceivedQty[po.poNo] ?? 0;
                  final isSelected =
                      selectedPOs[material.partNo]?[po.poNo] ?? true;

                  return TableRow(
                    children: [
                      // Checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPOs[material.partNo]![po.poNo] =
                                  value ?? false;
                              if (value == true) {
                                // When checking, set to remaining quantity
                                final remainingQty = orderedQty - receivedQty;
                                poQtyControllers[material.partNo]?[po.poNo]
                                    ?.text = remainingQty.toString();
                              } else {
                                // When unchecking, set to 0
                                poQtyControllers[material.partNo]?[po.poNo]
                                    ?.text = '0';
                              }
                            });
                          },
                        ),
                      ),
                      // PO No
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child:
                            Text(po.poNo, style: const TextStyle(fontSize: 12)),
                      ),
                      // Ordered
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(orderedQty.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      // Received Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          receivedQty.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Inward Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 32,
                          child: TextFormField(
                            controller:
                                poQtyControllers[material.partNo]![po.poNo],
                            enabled: isSelected,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: const OutlineInputBorder(),
                              filled: !isSelected,
                              fillColor: !isSelected ? Colors.grey[200] : null,
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!isSelected) return null;
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final qty = double.tryParse(value);
                              if (qty == null) return 'Invalid';
                              if (qty < 0) return 'Invalid';
                              final remainingQty = orderedQty - receivedQty;
                              if (qty > remainingQty) {
                                return 'Exceeds remaining';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (!isSelected) return;
                              final qty = double.tryParse(value) ?? 0;
                              final remainingQty = orderedQty - receivedQty;
                              if (qty > remainingQty) {
                                poQtyControllers[material.partNo]?[po.poNo]
                                    ?.text = remainingQty.toString();
                              }
                              setState(() {});
                            },
                          ),
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

    // Validate required fields
    if (_invoiceNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Invoice No')),
      );
      return;
    }

    if (_invoiceDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Invoice Date')),
      );
      return;
    }

    if (_receivedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Received By')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create store inward items
      final items = <InwardItem>[];
      final materials = ref.read(materialListProvider);
      final pos = ref.read(purchaseOrderListProvider);

      for (var entry in selectedPOs.entries) {
        final materialCode = entry.key;
        final material = materials.firstWhere(
          (m) => m.partNo == materialCode,
          orElse: () => throw Exception('Material not found'),
        );

        final poQuantities = <String, double>{};
        double totalQty = 0;

        for (var poEntry in entry.value.entries) {
          final poNo = poEntry.key;
          final isSelected = poEntry.value;

          if (isSelected) {
            final qty = double.tryParse(
                    poQtyControllers[materialCode]?[poNo]?.text ?? '0') ??
                0.0;
            if (qty > 0) {
              poQuantities[poNo] = qty;
              totalQty += qty;
            }
          }
        }

        if (totalQty > 0) {
          final po = pos.firstWhere(
            (po) => po.items.any((item) => item.materialCode == materialCode),
            orElse: () => throw Exception('PO not found for material'),
          );

          final poItem = po.items.firstWhere(
            (item) => item.materialCode == materialCode,
          );

          items.add(InwardItem(
            materialCode: materialCode,
            materialDescription: material.description,
            unit: material.unit,
            orderedQty: totalQty,
            receivedQty: totalQty,
            acceptedQty: totalQty,
            rejectedQty: 0,
            costPerUnit: poItem.costPerUnit,
            poQuantities: poQuantities,
          ));
        }
      }

      if (items.isEmpty) {
        throw Exception('No items selected for inward');
      }

      // Create store inward
      final inward = StoreInward(
        grnNo: ref.read(storeInwardProvider.notifier).generateGRNNumber(),
        grnDate: _grnDateController.text,
        poNo: items.first.poQuantities.keys.join(', '),
        supplierName: selectedSupplier!.name,
        poDate: pos
            .firstWhere(
              (po) => po.poNo == items.first.poQuantities.keys.first,
            )
            .poDate,
        invoiceNo: _invoiceNoController.text,
        invoiceDate: _invoiceDateController.text,
        invoiceAmount: _invoiceAmountController.text,
        receivedBy: _receivedByController.text,
        checkedBy: _checkedByController.text,
        items: items,
      );

      // Save the inward and ensure state is updated
      await ref.read(storeInwardProvider.notifier).addInward(inward);

      // Force a rebuild of the page
      if (mounted) {
        setState(() {
          // Clear selections and controllers
          selectedPOs.clear();
          poQtyControllers.clear();
          receivedQtyControllers.clear();

          // Reset form fields
          _invoiceNoController.clear();
          _invoiceDateController.clear();
          _invoiceAmountController.clear();
          _receivedByController.clear();
          _checkedByController.clear();
          selectedSupplier = null;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving store inward: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all providers to ensure rebuilds when data changes
    final suppliers = ref.watch(supplierListProvider);
    final materials = ref.watch(materialListProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    ref.watch(storeInwardProvider); // Add this to watch store inwards

    // Filter POs by selected supplier and group by material
    final materialPOItems = <String, List<PurchaseOrder>>{};
    if (selectedSupplier != null) {
      for (var po in purchaseOrders) {
        if (po.supplierName == selectedSupplier!.name) {
          for (var item in po.items) {
            materialPOItems.putIfAbsent(item.materialCode, () => []).add(po);
          }
        }
      }
    }

    // Get all store inwards for the selected supplier

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Store Inward'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField2<Supplier>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Supplier',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 0),
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
                                // Clear selections when supplier changes
                                selectedPOs.clear();
                                poQtyControllers.clear();
                              });
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
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              height: 60,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "GRN No: GRN${DateTime.now().millisecondsSinceEpoch}"),
                              Text(
                                  "Date: ${DateFormat('dd/MMM/yy').format(DateTime.now())}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                              _invoiceNoController, 'Invoice No'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildTextField(
                              _invoiceDateController, 'Invoice Date',
                              isDate: true),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                              _receivedByController, 'Received By'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildTextField(
                              _checkedByController, 'Checked By'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedSupplier != null) ...[
                      if (materialPOItems.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No Purchase Orders found for this supplier',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Store Inward Items",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: materialPOItems.length,
                                    itemBuilder: (_, index) {
                                      final entry = materialPOItems.entries
                                          .elementAt(index);
                                      final material = materials.firstWhere(
                                        (m) => m.partNo == entry.key,
                                        orElse: () => throw Exception(
                                            'Material not found'),
                                      );
                                      return _buildItemCard(
                                          material, entry.value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 10),
                    if (selectedSupplier != null)
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
                            "Save Store Inward",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
}
