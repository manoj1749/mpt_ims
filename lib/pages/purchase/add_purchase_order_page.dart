// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:math';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_item.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../provider/material_provider.dart';
import '../../models/supplier.dart';
import '../../models/po_item.dart';
import '../../models/purchase_order.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/vendor_material_rate_provider.dart';
import 'package:collection/collection.dart';

class AddPurchaseOrderPage extends ConsumerStatefulWidget {
  final PurchaseOrder? existingPO;
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
  List<POItem> selectedItems = [];
  final Map<String, TextEditingController> qtyControllers = {};
  final Map<String, TextEditingController> maxQtyControllers = {};
  final TextEditingController _boardNoController = TextEditingController();
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _deliveryRequirementsController =
      TextEditingController();

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
      selectedItems = widget.existingPO!.items;
      for (var item in selectedItems) {
        qtyControllers[item.materialCode] =
            TextEditingController(text: item.quantity);
        maxQtyControllers[item.materialCode] =
            TextEditingController(text: item.quantity);
      }
      _boardNoController.text = widget.existingPO!.boardNo;
      _transportController.text = widget.existingPO!.transport;
      _deliveryRequirementsController.text =
          widget.existingPO!.deliveryRequirements;
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
    super.dispose();
  }

  double calculateTotal(List<POItem> items) {
    return items.fold(0.0, (sum, item) => sum + double.parse(item.totalCost));
  }

  POItem _createPOItem(MaterialItem material, double totalRemainingQty) {
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

    return POItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalRemainingQty.toString(),
      costPerUnit: costPerUnit.toString(),
      totalCost: (totalRemainingQty * costPerUnit).toString(),
      seiplRate: seiplRate.toString(),
      marginPerUnit: marginPerUnit.toString(),
      totalMargin: (marginPerUnit * totalRemainingQty).toString(),
    );
  }

  void _savePurchaseOrder() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var item in selectedItems) {
        final qtyText = qtyControllers[item.materialCode]?.text ?? '0';
        item.updateQuantity(qtyText);
      }

      // First update all items with their latest quantities and calculations
      final updatedItems = selectedItems.map((item) {
        final qty = int.parse(item.quantity);
        final cost = double.parse(item.costPerUnit);
        final seipl = double.parse(item.seiplRate);
        final margin = cost - seipl;

        final totalCost = (qty * cost).toStringAsFixed(2);
        final totalMargin = (qty * margin).toStringAsFixed(2);
        final rateDiff = (cost - seipl).toStringAsFixed(2);
        final totalRateDiff = (qty * (cost - seipl)).toStringAsFixed(2);
        return POItem(
          materialCode: item.materialCode,
          materialDescription: item.materialDescription,
          unit: item.unit,
          quantity: qty.toString(),
          costPerUnit: cost.toStringAsFixed(2),
          totalCost: totalCost,
          seiplRate: seipl.toStringAsFixed(2),
          rateDifference: rateDiff,
          totalRateDifference: totalRateDiff,
          marginPerUnit: margin.toStringAsFixed(2),
          totalMargin: totalMargin,
        );
      }).toList();

      // Calculate totals with proper rounding
      final subtotal = updatedItems.fold(
        0.0,
        (sum, item) => sum + double.parse(item.totalCost),
      );
      const igst = 0.0; // Add tax calculation logic if needed
      const cgst = 0.0;
      const sgst = 0.0;
      final grandTotal = subtotal + igst + cgst + sgst;

      final newPO = PurchaseOrder(
        poNo: widget.existingPO?.poNo ??
            'PO${DateTime.now().millisecondsSinceEpoch}',
        poDate: widget.existingPO?.poDate ?? now,
        supplierName: selectedSupplier!.name,
        boardNo: _boardNoController.text,
        transport: _transportController.text,
        deliveryRequirements: _deliveryRequirementsController.text,
        items: updatedItems,
        total: double.parse(subtotal.toStringAsFixed(2)),
        igst: double.parse(igst.toStringAsFixed(2)),
        cgst: double.parse(cgst.toStringAsFixed(2)),
        sgst: double.parse(sgst.toStringAsFixed(2)),
        grandTotal: double.parse(grandTotal.toStringAsFixed(2)),
      );

      // Update PR quantities and status with proper integer handling
      final purchaseRequests = ref.read(purchaseRequestListProvider);
      final prNotifier = ref.read(purchaseRequestListProvider.notifier);

      for (var pr in purchaseRequests) {
        if (pr.supplierName == selectedSupplier!.name) {
          bool prUpdated = false;

          for (var prItem in pr.items) {
            final poItem = updatedItems.firstWhereOrNull(
              (po) => po.materialCode == prItem.materialCode,
            );

            if (poItem != null) {
              // Convert quantity to integer before updating PR
              final orderedQty = int.parse(poItem.quantity);
              prItem.addOrderedQuantity(
                newPO.poNo,
                orderedQty.toDouble(),
              );
              prUpdated = true;
            }
          }

          if (prUpdated) {
            pr.updateStatus();
            final index = purchaseRequests.indexOf(pr);
            prNotifier.updateRequest(index, pr);
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

    final filteredPRs = selectedSupplier == null
        ? <PurchaseRequest>[]
        : purchaseRequests
            .where((pr) =>
                pr.supplierName == selectedSupplier!.name && !pr.isFullyOrdered)
            .toList();

    final groupedItems = _groupPRsByMaterial(filteredPRs);
    final materials = ref.watch(materialListProvider);

    final poItems = <String, POItem>{};

    for (var entry in groupedItems.entries) {
      final materialCode = entry.key;
      final items = entry.value;
      final totalRemainingQty = _calculateTotalRemainingQuantity(items);

      if (totalRemainingQty <= 0) continue; // Skip if no remaining quantity

      MaterialItem? findMaterialByCode(List<MaterialItem> list, String code) {
        for (final item in list) {
          if (item.partNo == code) return item;
        }
        return null;
      }

      final material = findMaterialByCode(materials, materialCode);
      if (material == null) continue;

      try {
        poItems[materialCode] = _createPOItem(material, totalRemainingQty);

        // Initialize controller if not exists
        qtyControllers[materialCode] ??= TextEditingController(
          text: totalRemainingQty.toString(),
        );
        maxQtyControllers[materialCode] ??= TextEditingController(
          text: totalRemainingQty.toString(),
        );
      } catch (e) {
        // Show a snackbar with the error message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Add Rate',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to add rate page
                  // This will be implemented when the add rate functionality is ready
                },
              ),
            ),
          );
        });
      }
    }

    selectedItems = poItems.values.toList();

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
                decoration: const InputDecoration(labelText: 'Board No'),
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
                              final item = poItems.values.elementAt(index);
                              final prItems =
                                  groupedItems[item.materialCode] ?? [];
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

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.materialCode,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.materialDescription,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Qty Needed",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$totalNeededQty ${item.unit}",
                                            style: const TextStyle(
                                              color: Colors.amberAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            "Order Qty",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextFormField(
                                            controller: qtyControllers[
                                                item.materialCode],
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Quantity is required';
                                              }
                                              final inputQty =
                                                  int.tryParse(value);
                                              if (inputQty == null) {
                                                return 'Please enter a valid number';
                                              }
                                              if (inputQty <= 0) {
                                                return 'Quantity must be greater than 0';
                                              }
                                              final maxQty = int.parse(
                                                  totalNeededQty
                                                      .toStringAsFixed(0));
                                              if (inputQty > maxQty) {
                                                return 'Cannot exceed required quantity ($maxQty)';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              if (value == null ||
                                                  value.isEmpty) return;
                                              final qty = int.tryParse(value);
                                              if (qty == null) return;

                                              setState(() {
                                                final maxQty = int.parse(
                                                    maxQtyControllers[
                                                            item.materialCode]!
                                                        .text
                                                        .split('.')[0]);

                                                final limitedQty =
                                                    min(qty, maxQty).toString();
                                                if (value != limitedQty) {
                                                  qtyControllers[
                                                          item.materialCode]
                                                      ?.text = limitedQty;
                                                }
                                                item.updateQuantity(limitedQty);
                                              });
                                            },
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              errorStyle: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Rate Details",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: "Cost/Unit: ",
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                                TextSpan(
                                                  text:
                                                      "₹${item.costPerUnit}\n",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const TextSpan(
                                                  text: "SEIPL: ",
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                                TextSpan(
                                                  text: "₹${item.seiplRate}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Cost Summary",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ListenableBuilder(
                                            listenable: qtyControllers[
                                                item.materialCode]!,
                                            builder: (context, child) {
                                              final qty = double.tryParse(
                                                      qtyControllers[item
                                                                  .materialCode]
                                                              ?.text ??
                                                          '0') ??
                                                  0.0;
                                              final cost = double.parse(
                                                  item.costPerUnit);
                                              final totalCost = qty * cost;

                                              return RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: "Total: ",
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          "₹${totalCost.toStringAsFixed(2)}\n",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
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
                              for (var item in poItems.values) {
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
                  onPressed: _savePurchaseOrder,
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
