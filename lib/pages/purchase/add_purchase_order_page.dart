// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unused_local_variable

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/po_item.dart';
import '../../models/supplier.dart';
import '../../models/material_item.dart';
import '../../models/pr_item.dart';
import '../../models/purchase_order.dart' as po;
import '../../provider/supplier_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/vendor_material_rate_provider.dart';
import 'package:collection/collection.dart';

class AddPurchaseOrderPage extends ConsumerStatefulWidget {
  final po.PurchaseOrder? existingPO;
  final int? index;

  const AddPurchaseOrderPage({
    super.key,
    this.existingPO,
    this.index,
  });

  @override
  ConsumerState<AddPurchaseOrderPage> createState() =>
      _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends ConsumerState<AddPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? selectedSupplier;
  List<POItem> poItems = [];
  final Map<String, TextEditingController> qtyControllers = {};
  final Map<String, TextEditingController> maxQtyControllers = {};
  final TextEditingController _boardNoController = TextEditingController();
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _deliveryRequirementsController =
      TextEditingController();
  Map<String, Map<String, TextEditingController>> prQtyControllers = {};

  // Group PRs by material code

  // Calculate total remaining quantity for a material
  double _calculateTotalRemainingQuantity(List<PRItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.remainingQuantity);
  }

  // Allocate ordered quantity across PRs

  @override
  void initState() {
    super.initState();
    if (widget.existingPO != null) {
      selectedSupplier = ref
          .read(supplierListProvider)
          .firstWhere((s) => s.name == widget.existingPO!.supplierName);
      _boardNoController.text = widget.existingPO!.boardNo;
      _transportController.text = widget.existingPO!.transport;
      _deliveryRequirementsController.text =
          widget.existingPO!.deliveryRequirements;
      
      // Initialize PR quantities from existing PO items
      for (var item in widget.existingPO!.items) {
        item.prQuantities.forEach((prNo, qty) {
          prQtyControllers
              .putIfAbsent(item.materialCode, () => {})
              .putIfAbsent(prNo, () => TextEditingController())
              .text = qty.toString();
        });
      }
      
      // Trigger a rebuild to show the items
      setState(() {
        poItems = List<POItem>.from(widget.existingPO!.items);
      });
    }
  }

  @override
  void dispose() {
    _boardNoController.dispose();
    _transportController.dispose();
    _deliveryRequirementsController.dispose();
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in maxQtyControllers.values) {
      controller.dispose();
    }
    for (var materialControllers in prQtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  POItem _createPOItem(MaterialItem material, List<PRItem> prItems) {
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(material.slNo);

    // Check if the supplier has a rate for this material
    final vendorRate =
        rates.where((r) => r.vendorId == selectedSupplier!.name).firstOrNull;
    if (vendorRate == null) {
      throw Exception(
          'Please add rate for ${material.description} for vendor ${selectedSupplier!.name} before creating PO');
    }

    final costPerUnit = double.parse(vendorRate.saleRate);
    final seiplRate = double.parse(vendorRate.seiplRate);
    final marginPerUnit = costPerUnit - seiplRate;

    // Calculate total quantity from PR-wise quantities
    final prQuantities = <String, double>{};
    double totalQty = 0;

    for (var prItem in prItems) {
      final remainingQty =
          double.parse(prItem.quantity) - prItem.totalOrderedQuantity;
      if (remainingQty > 0) {
        final controller = prQtyControllers[material.partNo]?[prItem.prNo] ??
            TextEditingController(text: remainingQty.toString());
        prQtyControllers
            .putIfAbsent(material.partNo, () => {})
            .putIfAbsent(prItem.prNo, () => controller);

        final orderQty = double.tryParse(controller.text) ?? 0;
        if (orderQty > 0) {
          prQuantities[prItem.prNo] = orderQty;
          totalQty += orderQty;
        }
      }
    }

    return POItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalQty.toString(),
      costPerUnit: costPerUnit.toString(),
      totalCost: (totalQty * costPerUnit).toString(),
      seiplRate: seiplRate.toString(),
      marginPerUnit: marginPerUnit.toString(),
      totalMargin: (marginPerUnit * totalQty).toString(),
      prQuantities: prQuantities,
    );
  }

  Widget _buildItemCard(MaterialItem material, List<PRItem> prItems) {
    final poItem = _createPOItem(material, prItems);

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
                    'Rate: ₹${poItem.costPerUnit}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.5),
              },
              children: [
                const TableRow(
                  children: [
                    Text('PR No',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Need',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Ordered',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Order Qty',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
                ...prItems.map((prItem) {
                  final totalQty = double.parse(prItem.quantity);
                  final orderedQty = prItem.totalOrderedQuantity;
                  final remainingQty = totalQty - orderedQty;
                  
                  final isInExistingPO = widget.existingPO?.items
                      .any((item) => item.prQuantities.containsKey(prItem.prNo)) ?? false;
                  
                  if (remainingQty <= 0 && !isInExistingPO) {
                    return const TableRow(children: [SizedBox(), SizedBox(), SizedBox(), SizedBox()]);
                  }

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(prItem.prNo,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(totalQty.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(orderedQty.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 32,
                          child: TextFormField(
                            controller: prQtyControllers[material.partNo]![
                                prItem.prNo],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return null;
                              final qty = double.tryParse(value);
                              if (qty == null) return 'Invalid';
                              if (qty < 0) return 'Invalid';
                              if (qty > remainingQty) return 'Exceeds';
                              return null;
                            },
                            onChanged: (value) {
                              final qty = double.tryParse(value);
                              if (qty != null && qty > remainingQty) {
                                prQtyControllers[material.partNo]
                                        ?[prItem.prNo]
                                    ?.text = remainingQty.toString();
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).where((row) => row.children.any((cell) => cell is! SizedBox)).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSavePressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate supplier selection
    if (selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    final materials = ref.read(materialListProvider);
    final purchaseRequests = ref.read(purchaseRequestListProvider);

    // Group PR items by material code for the selected supplier
    final materialPRItems = <String, List<PRItem>>{};
    for (var pr in purchaseRequests) {
      if (pr.supplierName == selectedSupplier!.name) {
        for (var item in pr.items) {
          materialPRItems.putIfAbsent(item.materialCode, () => []).add(item);
        }
      }
    }

    // Validate if at least one item has quantity
    bool hasItems = false;
    for (var item in poItems) {
      final prItems = materialPRItems[item.materialCode] ?? [];
      for (var prItem in prItems) {
        final qty = double.tryParse(
          prQtyControllers[item.materialCode]?[prItem.prNo]?.text ?? '0'
        ) ?? 0.0;
        if (qty > 0) {
          hasItems = true;
          break;
        }
      }
      if (hasItems) break;
    }

    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item with quantity')),
      );
      return;
    }

    // Validate required fields
    if (_boardNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Job No')),
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

    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Create updated POItems with current quantities
    final updatedPOItems = <POItem>[];

    for (var entry in materialPRItems.entries) {
      final material = materials.firstWhere(
        (m) => m.partNo == entry.key,
        orElse: () => throw Exception('Material not found: ${entry.key}'),
      );
      final prItems = entry.value;

      final poItem = _createPOItem(material, prItems);

      if (double.parse(poItem.quantity) > 0) {
        updatedPOItems.add(poItem);
      }
    }

    // Calculate tax amounts based on updated items
    final subtotal = updatedPOItems.fold(
        0.0, (sum, item) => sum + double.parse(item.totalCost));

    // Safely parse GST rates with fallback to 0
    double parseGstRate(String? value) {
      if (value == null || value.isEmpty) return 0.0;
      value = value.replaceAll('%', '').trim();
      return double.tryParse(value) ?? 0.0;
    }

    // Use supplier's GST rates with safe parsing
    final igst = subtotal * (parseGstRate(selectedSupplier!.igst) / 100);
    final cgst = subtotal * (parseGstRate(selectedSupplier!.cgst) / 100);
    final sgst = subtotal * (parseGstRate(selectedSupplier!.sgst) / 100);
    final grandTotal = subtotal + igst + cgst + sgst;

    final newPO = po.PurchaseOrder(
      poNo: widget.existingPO?.poNo ??
          'PO${DateTime.now().millisecondsSinceEpoch}',
      poDate: widget.existingPO?.poDate ?? now,
      supplierName: selectedSupplier!.name,
      boardNo: _boardNoController.text,
      transport: _transportController.text,
      deliveryRequirements: _deliveryRequirementsController.text,
      items: updatedPOItems,
      total: subtotal,
      igst: igst,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
    );

    // Update PR quantities and status
    final prNotifier = ref.read(purchaseRequestListProvider.notifier);

    for (var poItem in updatedPOItems) {
      for (var entry in poItem.prQuantities.entries) {
        final prNo = entry.key;
        final orderQty = entry.value;

        // Find the PR and update its item quantities
        for (var pr in purchaseRequests) {
          if (pr.prNo == prNo) {
            final prItem = pr.items.firstWhere(
              (item) => item.materialCode == poItem.materialCode,
              orElse: () => throw Exception('PR item not found'),
            );

            if (orderQty > 0) {
              prItem.addOrderedQuantity(newPO.poNo, orderQty);
              pr.updateStatus();
              final index = purchaseRequests.indexOf(pr);
              prNotifier.updateRequest(index, pr);
            }
          }
        }
      }
    }

    // Save the PO
    if (widget.existingPO != null) {
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      poNotifier.updateOrder(widget.index!, newPO);
    } else {
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      poNotifier.addOrder(newPO);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final purchaseRequests = ref.watch(purchaseRequestListProvider);
    final materials = ref.watch(materialListProvider);

    // Group PR items by material code
    final materialPRItems = <String, List<PRItem>>{};

    if (selectedSupplier != null) {
      for (var pr in purchaseRequests) {
        if (pr.supplierName == selectedSupplier!.name) {
          for (var item in pr.items) {
            final existingPOItem = widget.existingPO?.items
                .firstWhereOrNull((poi) => poi.materialCode == item.materialCode);

            // Only add items that are not fully ordered or are part of this PO
            if (!item.isFullyOrdered || existingPOItem != null) {
              materialPRItems.putIfAbsent(item.materialCode, () => []).add(item);
            }
          }
        }
      }
    }

    // Calculate totals
    double subtotal = 0;
    final poItems = <POItem>[];

    for (var entry in materialPRItems.entries) {
      final material = materials.firstWhere(
        (m) => m.partNo == entry.key,
        orElse: () => throw Exception('Material not found: ${entry.key}'),
      );

      final poItem = _createPOItem(material, entry.value);
      if (double.parse(poItem.quantity) > 0) {
        poItems.add(poItem);
        subtotal += double.parse(poItem.totalCost);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Purchase Order Creation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            "PO No: PO${DateTime.now().millisecondsSinceEpoch}"),
                        Text(
                            "Date: ${DateFormat('dd/MMM/yy').format(DateTime.now())}"),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transportController,
                decoration: const InputDecoration(labelText: 'Transport'),
              ),
              TextFormField(
                controller: _deliveryRequirementsController,
                decoration:
                    const InputDecoration(labelText: 'Delivery Requirements'),
              ),
              TextFormField(
                controller: _boardNoController,
                decoration: const InputDecoration(labelText: 'Job No'),
              ),
              const SizedBox(height: 10),
              if (poItems.isNotEmpty)
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
                            "Purchase Order Items",
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
                            itemCount: poItems.length,
                            itemBuilder: (_, index) {
                              final item = poItems.elementAt(index);
                              final prItems =
                                  materialPRItems[item.materialCode] ?? [];
                              final material = materials.firstWhere(
                                (m) => m.partNo == item.materialCode,
                                orElse: () =>
                                    throw Exception('Material not found'),
                              );
                              return _buildItemCard(material, prItems);
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: ListenableBuilder(
                            listenable: Listenable.merge([
                              ...qtyControllers.values,
                              ...prQtyControllers.values
                                  .expand((controllers) => controllers.values),
                            ]),
                            builder: (context, _) {
                              double total = 0;
                              for (var item in poItems) {
                                final material = materials.firstWhere(
                                  (m) => m.partNo == item.materialCode,
                                  orElse: () =>
                                      throw Exception('Material not found'),
                                );
                                final prItems =
                                    materialPRItems[item.materialCode] ?? [];

                                double itemTotal = 0;
                                for (var prItem in prItems) {
                                  final qty = double.tryParse(
                                          prQtyControllers[item.materialCode]
                                                      ?[prItem.prNo]
                                                  ?.text ??
                                              '0') ??
                                      0.0;
                                  final cost = double.parse(item.costPerUnit);
                                  itemTotal += qty * cost;
                                }
                                total += itemTotal;
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Total Order Value: ",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "₹${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
