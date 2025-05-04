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
  String? _requiredBy;
  final Map<String, String?> _selectedVendors = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _requiredBy = widget.existingRequest!.requiredBy;
      for (var item in widget.existingRequest!.items) {
        _items.add(PRItemFormData(
          selectedMaterial: item.materialDescription,
          quantity: item.quantity,
          remarks: item.remarks,
          partNoController: TextEditingController(text: item.materialCode),
          unitController: TextEditingController(text: item.unit),
        ));
        _selectedVendors[item.materialDescription] =
            widget.existingRequest!.supplierName;
      }
    } else {
      _addNewItem();
    }
  }

  @override
  void dispose() {
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
    rates.sort(
        (a, b) => double.parse(a.saleRate).compareTo(double.parse(b.saleRate)));
    return rates;
  }

  String? _validateMaterialVendors(String materialId, String description) {
    final rates = _getVendorRates(materialId);
    if (rates.isEmpty) {
      return 'No vendors available for $description';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);

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
              TextFormField(
                initialValue: _requiredBy,
                decoration: const InputDecoration(
                  labelText: 'Required By',
                  hintText: 'Enter date or name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _requiredBy = v,
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
                          items: _getVendorRates(
                            materials
                                .firstWhere((m) =>
                                    m.description == item.selectedMaterial)
                                .slNo,
                          ).map((rate) {
                            final isLowestRate = rate ==
                                _getVendorRates(
                                  materials
                                      .firstWhere((m) =>
                                          m.description ==
                                          item.selectedMaterial)
                                      .slNo,
                                ).first;
                            return DropdownMenuItem<String>(
                              value: rate.vendorId,
                              child: Row(
                                children: [
                                  Expanded(child: Text(rate.vendorId)),
                                  Text(
                                    '₹${rate.saleRate}',
                                    style: TextStyle(
                                      color: isLowestRate ? Colors.green : null,
                                      fontWeight:
                                          isLowestRate ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedVendors[item.selectedMaterial!] = val;
                            });
                          },
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
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
                      final now =
                          DateFormat('yyyy-MM-dd').format(DateTime.now());

                      final items = _items.map((item) {
                        final material = materials.firstWhere(
                          (m) => m.description == item.selectedMaterial,
                        );

                        return PRItem(
                          materialCode: material.partNo,
                          materialDescription: material.description,
                          unit: material.unit,
                          quantity: item.quantity!,
                          remarks: item.remarks ?? '',
                        );
                      }).toList();

                      final newRequest = PurchaseRequest(
                        prNo: widget.existingRequest?.prNo ??
                            'PR${DateTime.now().millisecondsSinceEpoch}',
                        date: widget.existingRequest?.date ?? now,
                        requiredBy: _requiredBy!,
                        supplierName:
                            _selectedVendors[_items[0].selectedMaterial]!,
                        items: items,
                        status: 'Requested',
                      );

                      final notifier =
                          ref.read(purchaseRequestListProvider.notifier);
                      if (widget.existingRequest != null) {
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
