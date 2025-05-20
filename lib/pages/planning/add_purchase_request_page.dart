import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../models/vendor_material_rate.dart';
import '../../provider/sale_order_provider.dart';

class AddPurchaseRequestPage extends ConsumerStatefulWidget {
  final PurchaseRequest? existingRequest;
  final int? index;
  const AddPurchaseRequestPage(
      {super.key, required this.existingRequest, required this.index});

  @override
  ConsumerState<AddPurchaseRequestPage> createState() =>
      _AddPurchaseRequestPageState();
}

class _AddPurchaseRequestPageState
    extends ConsumerState<AddPurchaseRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final List<PRItemFormData> _items = [];
  final _requiredByController = TextEditingController();
  String? _selectedJobNo;
  final Map<String, String?> _selectedVendors = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _requiredByController.text = widget.existingRequest!.requiredBy;
      _selectedJobNo = widget.existingRequest!.jobNo;
      for (var item in widget.existingRequest!.items) {
        _items.add(PRItemFormData(
          selectedMaterial: item.materialDescription,
          quantity: item.quantity,
          remarks: item.remarks,
          partNoController: TextEditingController(text: item.materialCode),
          unitController: TextEditingController(text: item.unit),
        ));
      }
    } else {
      _addNewItem();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized && widget.existingRequest != null) {
      for (var item in widget.existingRequest!.items) {
        // Initialize vendor selections from the item's supplier
        _selectedVendors[item.materialDescription] = item.supplierName;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _requiredByController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(PRItemFormData(
        selectedMaterial: null,
        quantity: null,
        remarks: null,
        partNoController: TextEditingController(),
        unitController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _items[index];
      if (item.selectedMaterial != null) {
        _selectedVendors.remove(item.selectedMaterial);
      }
      item.dispose();
      _items.removeAt(index);
    });
  }

  List<VendorMaterialRate> _getVendorRates(String materialId) {
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(materialId);
    return rates;
  }

  String? _validateMaterialVendors(String materialId, String description) {
    final rates = _getVendorRates(materialId);
    return null;
  }

  List<DropdownMenuItem<String>> _buildVendorDropdownItems(String materialId, String materialDescription) {
    final rates = _getVendorRates(materialId);
    final preferredVendor = ref.read(materialListProvider)
        .firstWhere((m) => m.slNo == materialId)
        .getPreferredVendorName(ref);

    // Create a map to store unique vendors and their best rates
    final vendorMap = <String, VendorMaterialRate>{};
    
    // Keep only the best rate for each vendor
    for (var rate in rates) {
      if (!vendorMap.containsKey(rate.vendorId) || 
          double.parse(rate.saleRate) < double.parse(vendorMap[rate.vendorId]!.saleRate)) {
        vendorMap[rate.vendorId] = rate;
      }
    }

    // Convert to dropdown items
    return vendorMap.values.map((rate) {
      final isPreferred = rate.vendorId == preferredVendor;
      
      return DropdownMenuItem<String>(
        value: rate.vendorId,
        child: Row(
          children: [
            if (isPreferred)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            Expanded(
              child: Text(
                rate.vendorId,
                style: TextStyle(
                  fontWeight: isPreferred ? FontWeight.bold : null,
                ),
              ),
            ),
            Text(
              '₹${rate.saleRate}',
              style: TextStyle(
                color: isPreferred ? Colors.green : null,
                fontWeight: isPreferred ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);
    final saleOrders = ref.watch(saleOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingRequest != null
              ? 'Edit Purchase Request'
              : 'New Purchase Request',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _requiredByController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Required By',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      value: _selectedJobNo,
                      decoration: const InputDecoration(
                        labelText: 'Job No',
                        border: OutlineInputBorder(),
                      ),
                      items: saleOrders.map((order) {
                        return DropdownMenuItem<String>(
                          value: order.boardNo,
                          child:
                              Text('${order.boardNo} - ${order.customerName}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedJobNo = value;
                          if (value != null) {
                            final selectedOrder = saleOrders.firstWhere(
                              (order) => order.boardNo == value,
                            );
                            _requiredByController.text =
                                selectedOrder.customerName;
                          } else {
                            _requiredByController.text = '';
                          }
                        });
                      },
                      validator: (value) => null, // Job number is optional
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Item ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (_items.length > 1)
                            TextButton.icon(
                              onPressed: () => _removeItem(index),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField2<String>(
                        isExpanded: true,
                        value: item.selectedMaterial,
                        decoration: const InputDecoration(
                          labelText: 'Material Name',
                          border: OutlineInputBorder(),
                        ),
                        items: materials.map((m) {
                          final vendorError = _validateMaterialVendors(
                            m.slNo,
                            m.description,
                          );
                          return DropdownMenuItem<String>(
                            value: m.description,
                            enabled: vendorError == null,
                            child: vendorError != null
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.description,
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                      ),
                                      Text(
                                        vendorError,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(m.description),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            if (item.selectedMaterial != null) {
                              _selectedVendors.remove(item.selectedMaterial);
                            }

                            item.selectedMaterial = val;
                            if (val != null) {
                              final selectedItem = materials.firstWhere(
                                (m) => m.description == val,
                              );
                              item.partNoController.text = selectedItem.partNo;
                              item.unitController.text = selectedItem.unit;

                              final rates = _getVendorRates(selectedItem.slNo);
                              if (rates.isNotEmpty) {
                                _selectedVendors[val] = rates.first.vendorId;
                              }
                            }
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final material = materials.firstWhere(
                            (m) => m.description == val,
                          );
                          return _validateMaterialVendors(material.slNo, val);
                        },
                      ),
                      if (item.selectedMaterial != null) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField2<String>(
                          isExpanded: true,
                          value: _selectedVendors[item.selectedMaterial],
                          decoration: const InputDecoration(
                            labelText: 'Vendor',
                            border: OutlineInputBorder(),
                          ),
                          items: _buildVendorDropdownItems(
                            materials.firstWhere((m) => m.description == item.selectedMaterial).slNo,
                            item.selectedMaterial!,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedVendors[item.selectedMaterial!] = val;
                            });
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.partNoController,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Material Code',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: item.unitController,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: item.quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) => item.quantity = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: item.remarks,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => item.remarks = v,
                      ),
                      const Divider(height: 48),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Item'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

                      final prNo = widget.existingRequest?.prNo ??
                          'PR${DateTime.now().millisecondsSinceEpoch}';

                      // Process all items (both new and existing)
                      final allItems = <PRItem>[];
                      
                      // First, process the form items
                      for (var item in _items) {
                        if (item.selectedMaterial == null) continue;

                        final material = materials.firstWhere(
                          (m) => m.description == item.selectedMaterial,
                        );

                        final supplierName = _selectedVendors[item.selectedMaterial]!;

                        final prItem = PRItem(
                          materialCode: material.partNo,
                          materialDescription: material.description,
                          unit: material.unit,
                          quantity: item.quantity!,
                          remarks: item.remarks ?? '',
                          prNo: prNo,
                          supplierName: supplierName,
                        );

                        // Check if this is a modification of an existing item
                        if (widget.existingRequest != null) {
                          final existingItemIndex = widget.existingRequest!.items.indexWhere(
                            (existing) => existing.materialCode == prItem.materialCode
                          );

                          if (existingItemIndex != -1) {
                            // Preserve ordered quantities from existing item
                            prItem.orderedQuantities = 
                                Map<String, double>.from(widget.existingRequest!.items[existingItemIndex].orderedQuantities);
                          }
                        }

                        allItems.add(prItem);
                      }

                      final newRequest = PurchaseRequest(
                        prNo: prNo,
                        date: widget.existingRequest?.date ?? now,
                        requiredBy: _requiredByController.text,
                        items: allItems,
                        status: widget.existingRequest?.status ?? 'Requested',
                        jobNo: _selectedJobNo,
                      );

                      final notifier = ref.read(purchaseRequestListProvider.notifier);
                      if (widget.existingRequest != null && widget.index != null) {
                        notifier.updateRequest(widget.index!, newRequest);
                      } else {
                        notifier.addRequest(newRequest);
                      }

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PRItemFormData {
  String? selectedMaterial;
  String? quantity;
  String? remarks;
  final TextEditingController partNoController;
  final TextEditingController unitController;

  PRItemFormData({
    required this.selectedMaterial,
    required this.quantity,
    required this.remarks,
    required this.partNoController,
    required this.unitController,
  });

  void dispose() {
    partNoController.dispose();
    unitController.dispose();
  }
}
