// Add/Edit Service Bill PO Page
// Simplified PO creation for service bills - no PR correlation, no stock impact

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:collection/collection.dart';
import '../../models/supplier.dart';
import '../../models/purchase_order.dart';
import '../../models/po_item.dart';
import '../../models/service_name.dart';
import '../../models/service_type.dart';
import '../../provider/service_supplier_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/service_name_provider.dart';
import '../../provider/service_type_provider.dart';

class AddServiceBillPOPage extends ConsumerStatefulWidget {
  final PurchaseOrder? existingPO;
  final int? index;

  const AddServiceBillPOPage({
    super.key,
    this.existingPO,
    this.index,
  });

  @override
  ConsumerState<AddServiceBillPOPage> createState() => _AddServiceBillPOPageState();
}

class _AddServiceBillPOPageState extends ConsumerState<AddServiceBillPOPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? selectedSupplier;
  final TextEditingController _supplierSearchController = TextEditingController();
  final TextEditingController _serviceSearchController = TextEditingController();

  String? _selectedServiceName;
  String? _selectedServiceType;
  
  List<ServiceBillItem> items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(serviceNameProvider.notifier).loadServiceNames();
        await ref.read(serviceTypeProvider.notifier).loadServiceTypes();
      } catch (_) {}
    });

    if (widget.existingPO != null) {
      selectedSupplier = ref
          .read(serviceSupplierListProvider)
          .firstWhereOrNull((s) => s.name == widget.existingPO!.supplierName);
      // Persisted using existing PO fields to avoid schema changes:
      // transport = serviceType, deliveryRequirements = serviceName
      final existingServiceName = widget.existingPO!.deliveryRequirements;
      final existingServiceType = widget.existingPO!.transport;
      if (existingServiceName.isNotEmpty) {
        try {
          _selectedServiceName = existingServiceName;
          _selectedServiceType = existingServiceType.isNotEmpty ? existingServiceType : null;
        } catch (_) {
          // ignore
        }
      }
      
      // Load existing items
      items = widget.existingPO!.items.map((item) => ServiceBillItem(
        description: item.materialDescription,
        amount: double.tryParse(item.totalCost) ??
            (double.tryParse(item.costPerUnit) ?? 0),
      )).toList();
    }
  }

  @override
  void dispose() {
    _supplierSearchController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      items.add(ServiceBillItem(
        description: '',
        amount: 0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  double _calculateSubtotal() {
    return items.fold(0, (sum, item) => sum + (item.amount ?? 0));
  }

  Future<void> _savePO() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if ((_selectedServiceName ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if ((_selectedServiceType ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (items.isEmpty || items.any((item) => item.description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final subtotal = _calculateSubtotal();
    final igst = subtotal * (double.tryParse(selectedSupplier!.igst.replaceAll('%', '')) ?? 0) / 100;
    final cgst = subtotal * (double.tryParse(selectedSupplier!.cgst.replaceAll('%', '')) ?? 0) / 100;
    final sgst = subtotal * (double.tryParse(selectedSupplier!.sgst.replaceAll('%', '')) ?? 0) / 100;
    final grandTotal = subtotal + igst + cgst + sgst;

    final now = DateTime.now();
    final poNo = widget.existingPO?.poNo ?? 
        'SB-PO-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour}${now.minute}${now.second}';

    final poItems = items.map((item) => POItem(
      materialCode: 'SERVICE',
      materialDescription: item.description,
      unit: 'Nos',
      quantity: '1',
      costPerUnit: (item.amount ?? 0).toString(),
      totalCost: (item.amount ?? 0).toString(),
      saleRate: '0',
      marginPerUnit: '0',
      totalMargin: '0',
      prDetails: {},
    )).toList();

    final purchaseOrder = PurchaseOrder(
      poNo: poNo,
      poDate: widget.existingPO?.poDate ?? DateFormat('yyyy-MM-dd').format(now),
      supplierName: selectedSupplier!.name,
      // Persisted using existing PO fields to avoid schema changes:
      // transport = serviceType, deliveryRequirements = serviceName
      transport: _selectedServiceType ?? '',
      deliveryRequirements: _selectedServiceName ?? '',
      items: poItems,
      total: subtotal,
      igst: igst,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
      isServiceBill: true,
    );

    if (widget.existingPO != null && widget.index != null) {
      await ref.read(purchaseOrderListProvider.notifier).updateOrder(widget.index!, purchaseOrder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service Bill PO updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await ref.read(purchaseOrderListProvider.notifier).addOrder(purchaseOrder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service Bill PO created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(serviceSupplierListProvider);
    final services = ref.watch(serviceNameProvider);
    final allTypes = ref.watch(serviceTypeProvider);
    final serviceNameOptions = services
        .map((s) => s.name)
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filteredTypeOptions = (_selectedServiceName == null || _selectedServiceName!.isEmpty)
        ? <String>[]
        : allTypes
            .where((t) => t.serviceName == _selectedServiceName)
            .map((t) => t.name)
            .where((n) => n.trim().isNotEmpty)
            .toSet()
            .toList()
      ..sort();
    final subtotal = _calculateSubtotal();
    final igst = selectedSupplier != null
        ? subtotal * (double.tryParse(selectedSupplier!.igst.replaceAll('%', '')) ?? 0) / 100
        : 0;
    final cgst = selectedSupplier != null
        ? subtotal * (double.tryParse(selectedSupplier!.cgst.replaceAll('%', '')) ?? 0) / 100
        : 0;
    final sgst = selectedSupplier != null
        ? subtotal * (double.tryParse(selectedSupplier!.sgst.replaceAll('%', '')) ?? 0) / 100
        : 0;
    final grandTotal = subtotal + igst + cgst + sgst;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(widget.existingPO != null ? 'Edit Service Bill PO' : 'Add Service Bill PO'),
        backgroundColor: Colors.grey[850],
        actions: [
          TextButton.icon(
            onPressed: _savePO,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier Selection
              DropdownButtonFormField2<Supplier?>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Supplier',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                hint: const Text("Select Supplier"),
                value: selectedSupplier,
                items: suppliers.isEmpty
                    ? [
                        const DropdownMenuItem<Supplier?>(
                          value: null,
                          enabled: false,
                          child: Text('No Suppliers Found'),
                        ),
                      ]
                    : suppliers
                        .map((supplier) => DropdownMenuItem<Supplier?>(
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
                dropdownSearchData: suppliers.isEmpty
                    ? null
                    : DropdownSearchData(
                        searchController: _supplierSearchController,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            controller: _supplierSearchController,
                            expands: true,
                            maxLines: null,
                            autofocus: true,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Search Supplier',
                              hintStyle: const TextStyle(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {
                          final name = item.value?.name ?? '';
                          if (name.isEmpty) return true;
                          return name
                              .toLowerCase()
                              .contains(searchValue.toLowerCase());
                        },
                      ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    _supplierSearchController.clear();
                  }
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
              const SizedBox(height: 16),
              
              // Service Name
              DropdownButtonFormField2<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                hint: const Text('Select Service'),
                value: _selectedServiceName,
                items: serviceNameOptions
                    .map((name) => DropdownMenuItem<String>(
                          value: name,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedServiceName = val;
                    _selectedServiceType = null;

                    if (val != null) {
                      final typesForService = allTypes
                          .where((t) => t.serviceName == val)
                          .map((t) => t.name)
                          .where((n) => n.trim().isNotEmpty)
                          .toSet()
                          .toList();

                      if (typesForService.length == 1) {
                        _selectedServiceType = typesForService.first;
                      }
                    }
                  });
                },
                dropdownSearchData: DropdownSearchData(
                  searchController: _serviceSearchController,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Container(
                    height: 50,
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 4,
                      right: 8,
                      left: 8,
                    ),
                    child: TextFormField(
                      controller: _serviceSearchController,
                      expands: true,
                      maxLines: null,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintText: 'Search Service',
                        hintStyle: const TextStyle(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    return (item.value ?? '')
                        .toLowerCase()
                        .contains(searchValue.toLowerCase());
                  },
                ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    _serviceSearchController.clear();
                  }
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
              const SizedBox(height: 16),

              // Service Type (auto-filled when service name is selected)
              DropdownButtonFormField2<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                hint: const Text('Select Service Type'),
                value: _selectedServiceType,
                items: filteredTypeOptions
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedServiceType = val;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
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
              const SizedBox(height: 24),
              
              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[200],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Items List
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildItemCard(item, index);
              }),
              
              const SizedBox(height: 24),
              
              // Total Summary
              if (selectedSupplier != null) ...[
                Card(
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey[300])),
                        if (igst > 0)
                          Text('IGST (${selectedSupplier!.igst}): ₹${igst.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey[300])),
                        if (cgst > 0)
                          Text('CGST (${selectedSupplier!.cgst}): ₹${cgst.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey[300])),
                        if (sgst > 0)
                          Text('SGST (${selectedSupplier!.sgst}): ₹${sgst.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey[300])),
                        const Divider(),
                        Text(
                          'Grand Total: ₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(ServiceBillItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          'Description of Service',
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: item.description,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              item.description = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          'Amount',
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: (item.amount ?? 0).toString(),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              item.amount = double.tryParse(value) ?? 0;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final v = double.tryParse(value);
                            if (v == null) {
                              return 'Invalid';
                            }
                            if (v < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: Text(
                          'Total: ₹${(item.amount ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[300]),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
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

class ServiceBillItem {
  String description;
  double? amount;

  ServiceBillItem({
    required this.description,
    this.amount,
  });
}
