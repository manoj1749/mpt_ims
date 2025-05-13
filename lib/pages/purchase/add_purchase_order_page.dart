// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:math';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/po_item.dart';
import '../../models/supplier.dart';
import '../../models/material_item.dart';
import '../../models/pr_item.dart';
import '../../models/purchase_request.dart';
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
  Map<String, List<PRItem>> _groupPRsByMaterial(List<PurchaseRequest> prs) {
    final grouped = <String, List<PRItem>>{};
    for (var pr in prs) {
      for (var item in pr.items) {
        if (!item.isFullyOrdered) {
          // Only include items that aren't fully ordered
          grouped.putIfAbsent(item.materialCode, () => []).add(item);
        }
      }
    }
    return grouped;
  }

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
      poItems = List<POItem>.from(widget.existingPO!.items);
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

  double calculateTotal(List<POItem> items) {
    return items.fold(0.0, (sum, item) => sum + double.parse(item.totalCost));
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.description,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text('Material Code: ${material.partNo}'),
            Text('Unit: ${material.unit}'),
            const SizedBox(height: 16),
            const Text(
              'Purchase Requests',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...prItems.map((prItem) {
              final remainingQty =
                  double.parse(prItem.quantity) - prItem.totalOrderedQuantity;
              if (remainingQty <= 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text('PR: ${prItem.prNo}'),
                    ),
                    Expanded(
                      child: Text('Need: ${remainingQty.toStringAsFixed(2)}'),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller:
                            prQtyControllers[material.partNo]![prItem.prNo],
                        decoration: const InputDecoration(
                          labelText: 'Order Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final qty = double.tryParse(value);
                          if (qty == null) return 'Invalid number';
                          if (qty < 0) return 'Cannot be negative';
                          if (qty > remainingQty) {
                            return 'Exceeds needed qty';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            // This will trigger rebuild and update totals
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Total Order Quantity:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    poItem.quantity,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Cost per Unit: ₹${poItem.costPerUnit}'),
                ),
                Expanded(
                  child: Text('Total Cost: ₹${poItem.totalCost}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSavePressed() {
    if (_formKey.currentState!.validate()) {
      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Calculate tax amounts
      final subtotal =
          poItems.fold(0.0, (sum, item) => sum + double.parse(item.totalCost));
      final igst = subtotal * 0.18; // 18% IGST
      final cgst = subtotal * 0.09; // 9% CGST
      final sgst = subtotal * 0.09; // 9% SGST
      final grandTotal = subtotal + igst + cgst + sgst;

      final newPO = po.PurchaseOrder(
        poNo: widget.existingPO?.poNo ??
            'PO${DateTime.now().millisecondsSinceEpoch}',
        poDate: widget.existingPO?.poDate ?? now,
        supplierName: selectedSupplier!.name,
        boardNo: _boardNoController.text,
        transport: _transportController.text,
        deliveryRequirements: _deliveryRequirementsController.text,
        items: List<POItem>.from(poItems),
        total: subtotal,
        igst: igst,
        cgst: cgst,
        sgst: sgst,
        grandTotal: grandTotal,
      );

      // Update PR quantities and status
      final purchaseRequests = ref.read(purchaseRequestListProvider);
      final prNotifier = ref.read(purchaseRequestListProvider.notifier);

      for (var poItem in poItems) {
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
        if (pr.supplierName == selectedSupplier!.name && !pr.isFullyOrdered) {
          for (var item in pr.items) {
            if (!item.isFullyOrdered) {
              materialPRItems
                  .putIfAbsent(item.materialCode, () => [])
                  .add(item);
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
              if (selectedSupplier != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Address:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            "${selectedSupplier!.address1}, ${selectedSupplier!.address2},"),
                        Text(
                            "${selectedSupplier!.address3}, ${selectedSupplier!.address4}"),
                        const SizedBox(height: 6),
                        Text("GSTIN: ${selectedSupplier!.gstNo}"),
                        Text("Email: ${selectedSupplier!.email}"),
                        Text("Contact: ${selectedSupplier!.contact}"),
                        const SizedBox(height: 6),
                        Text("Payment Terms: ${selectedSupplier!.paymentTerms}",
                            style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  ),
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Material Details",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Quantity",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Rates",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Cost",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: poItems.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 32),
                            itemBuilder: (_, index) {
                              final item = poItems.elementAt(index);
                              final prItems =
                                  materialPRItems[item.materialCode] ?? [];
                              final totalNeededQty =
                                  _calculateTotalRemainingQuantity(prItems);

                              // Initialize controller if not exists
                              qtyControllers[item.materialCode] ??=
                                  TextEditingController(
                                text: totalNeededQty.toString(),
                              );
                              maxQtyControllers[item.materialCode] ??=
                                  TextEditingController(
                                text: totalNeededQty.toString(),
                              );

                              return _buildItemCard(
                                  materials.firstWhere(
                                    (m) => m.partNo == item.materialCode,
                                    orElse: () =>
                                        throw Exception('Material not found'),
                                  ),
                                  prItems);
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: ListenableBuilder(
                            listenable: Listenable.merge(
                              qtyControllers.values.toList(),
                            ),
                            builder: (context, _) {
                              double total = 0;
                              for (var item in poItems) {
                                final qty = double.tryParse(
                                        qtyControllers[item.materialCode]
                                                ?.text ??
                                            '0') ??
                                    0.0;
                                final cost = double.parse(item.costPerUnit);
                                final totalCost = qty * cost;
                                total += totalCost;
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Total Order Value: ",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "₹${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
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
