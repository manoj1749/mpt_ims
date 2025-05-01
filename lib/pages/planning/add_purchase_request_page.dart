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

class _AddPurchaseRequestPageState extends ConsumerState<AddPurchaseRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final List<PRItemFormData> _items = [];
  String? _requiredBy;
  Map<String, String?> _selectedVendors = {};

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
        _selectedVendors[item.materialDescription] = widget.existingRequest!.supplierName;
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
    final rates = ref.read(vendorMaterialRateProvider.notifier).getRatesForMaterial(materialId);
    rates.sort((a, b) => double.parse(a.saleRate).compareTo(double.parse(b.saleRate)));
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[100]!,
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _requiredBy,
                          decoration: InputDecoration(
                            labelText: 'Required By',
                            hintText: 'Enter date or name',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onSaved: (v) => _requiredBy = v,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Item ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (_items.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeItem(index),
                                    color: Colors.red[400],
                                    tooltip: 'Remove Item',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField2<String>(
                              isExpanded: true,
                              value: item.selectedMaterial,
                              decoration: InputDecoration(
                                labelText: 'Material Name',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.inventory),
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
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              vendorError,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
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
                                decoration: InputDecoration(
                                  labelText: 'Vendor',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: const Icon(Icons.business),
                                ),
                                items: _getVendorRates(
                                  materials
                                      .firstWhere((m) =>
                                          m.description == item.selectedMaterial)
                                      .slNo,
                                ).map((rate) {
                                  final isLowestRate = rate == _getVendorRates(
                                    materials
                                        .firstWhere((m) =>
                                            m.description == item.selectedMaterial)
                                        .slNo,
                                  ).first;
                                  return DropdownMenuItem<String>(
                                    value: rate.vendorId,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(rate.vendorId),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLowestRate
                                                ? Colors.green[50]
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isLowestRate
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                          ),
                                          child: Text(
                                            '₹${rate.saleRate}',
                                            style: TextStyle(
                                              color: isLowestRate
                                                  ? Colors.green[700]
                                                  : Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (isLowestRate) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green[700],
                                            size: 16,
                                          ),
                                        ],
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
                                    decoration: InputDecoration(
                                      labelText: 'Material Code',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      prefixIcon: const Icon(Icons.tag),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: item.unitController,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText: 'Unit',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      prefixIcon: const Icon(Icons.straighten),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: item.quantity,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.numbers),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              onSaved: (v) => item.quantity = v,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: item.remarks,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Remarks',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.note),
                              ),
                              onSaved: (v) => item.remarks = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _addNewItem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Item'),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
                          supplierName: _selectedVendors[_items[0].selectedMaterial]!,
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit Request',
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
