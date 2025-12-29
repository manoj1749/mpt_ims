import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/delivery_challan.dart';
import '../../services/pdf_service.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/stock_maintenance_provider.dart' as stock;
import '../../provider/supplier_provider.dart';
import '../../provider/sale_order_provider.dart';
import '../../models/stock_maintenance.dart';

// Use the provider from the provider file

class AddDeliveryChallanPage extends ConsumerStatefulWidget {
  final DeliveryChallan? deliveryChallan;
  final String? presetDcType; // e.g., 'internal'
  final String? presetInternalFlow; // 'inward' | 'outward'

  const AddDeliveryChallanPage({super.key, this.deliveryChallan, this.presetDcType, this.presetInternalFlow});

  @override
  ConsumerState<AddDeliveryChallanPage> createState() =>
      _AddDeliveryChallanPageState();
}

class _AddDeliveryChallanPageState
    extends ConsumerState<AddDeliveryChallanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorNameController;
  late TextEditingController _vendorEmailController;
  late TextEditingController _vendorGstinController;
  late TextEditingController _noteController;
  bool _isReturnable = false;
  List<DeliveryChallanItem> _items = [];
  Supplier? _selectedSupplier;
  final _materialCodesController = TextEditingController();
  final _quantitiesController = TextEditingController();
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _vendorNameController = TextEditingController(
      text: widget.deliveryChallan?.vendorName ?? '',
    );
    _vendorEmailController = TextEditingController(
      text: widget.deliveryChallan?.vendorEmail ?? '',
    );
    _vendorGstinController = TextEditingController(
      text: widget.deliveryChallan?.vendorGstin ?? '',
    );
    _noteController = TextEditingController(
      text: widget.deliveryChallan?.note ?? '',
    );
    _isReturnable = widget.deliveryChallan?.isReturnable ?? false;
    _items =
        widget.deliveryChallan?.items.map((i) => i.copyWith()).toList() ?? [];
    _selectedDate = widget.deliveryChallan?.dcDate ??
        DateTime.now().toString().split(' ')[0];

    // Initialize selected supplier if editing
    if (widget.deliveryChallan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final suppliers = ref.read(supplierListProvider);
        _selectedSupplier = suppliers.firstWhere(
          (s) => s.name == widget.deliveryChallan!.vendorName,
          orElse: () => Supplier(
            name: '',
            contact: '',
            phone: '',
            email: '',
            vendorCode: '',
            address1: '',
            address2: '',
            address3: '',
            address4: '',
            state: '',
            stateCode: '',
            paymentTerms: '',
            pan: '',
            gstNo: '',
            igst: '',
            cgst: '',
            sgst: '',
            totalGst: '',
            bank: '',
            branch: '',
            account: '',
            ifsc: '',
            email1: '',
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _vendorEmailController.dispose();
    _vendorGstinController.dispose();
    _noteController.dispose();
    _materialCodesController.dispose();
    _quantitiesController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(
        DeliveryChallanItem(
          materialCode: '',
          materialDescription: '',
          unit: '',
          quantity: 0,
          jobNo: null,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _showBulkEntryDialog() async {
    _materialCodesController.clear();
    _quantitiesController.clear();
    bool isQuantityStep = false;
    List<String> materialCodes = [];
    final materials = ref.read(materialListProvider);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  isQuantityStep ? 'Enter Quantities' : 'Enter Material Codes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isQuantityStep) ...[
                    const Text(
                      'Enter material codes, one per line:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _materialCodesController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g.\nM001\nM002\nM003',
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Enter quantities in the same order:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantitiesController,
                      maxLines: 8,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText:
                            'Enter quantities for:\n${materialCodes.join('\n')}',
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!isQuantityStep) {
                      // Process material codes
                      materialCodes = _materialCodesController.text
                          .split('\n')
                          .where((code) => code.trim().isNotEmpty)
                          .map((code) => code.trim())
                          .toList();

                      // Validate material codes
                      final invalidCodes = materialCodes
                          .where(
                              (code) => !materials.any((m) => m.partNo == code))
                          .toList();

                      if (invalidCodes.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Invalid Material Codes'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'The following codes were not found:'),
                                const SizedBox(height: 8),
                                Text(invalidCodes.join('\n')),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isQuantityStep = true;
                      });
                    } else {
                      // Process quantities
                      final quantities = _quantitiesController.text
                          .split('\n')
                          .where((qty) => qty.trim().isNotEmpty)
                          .map((qty) => qty.trim())
                          .toList();

                      if (quantities.length != materialCodes.length) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Quantity Mismatch'),
                            content: Text(
                                'Please enter ${materialCodes.length} quantities, one for each material code.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      // Add all items
                      for (var i = 0; i < materialCodes.length; i++) {
                        final material = materials
                            .firstWhere((m) => m.partNo == materialCodes[i]);
                        final quantity = double.tryParse(quantities[i]) ?? 0;

                        _items.add(
                          DeliveryChallanItem(
                            materialCode: material.partNo,
                            materialDescription: material.description,
                            unit: material.unit,
                            quantity: quantity,
                            jobNo: null,
                          ),
                        );
                      }

                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: Text(isQuantityStep ? 'Add Items' : 'Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveDeliveryChallan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final isInternal = (widget.presetDcType == 'internal');
      if (!isInternal && _selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vendor')),
        );
        return;
      }

      // Check stock availability only for outward flows
      if (!isInternal || (widget.presetInternalFlow ?? 'outward') == 'outward') {
        final stockBox = ref.read(stock.stockMaintenanceBoxProvider);
        for (var item in _items) {
          StockMaintenance? stockItem;
          try {
            stockItem = stockBox.values
                .firstWhere((stock) => stock.materialCode == item.materialCode);
          } catch (_) {
            stockItem = null;
          }

          if (stockItem == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stock entry not found for ${item.materialDescription} (${item.materialCode}). Please sync stock before issuing.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final jobNo = item.jobNo ?? 'General';

          // Calculate available quantity based on job number
          double availableQty = 0.0;
          if (jobNo == 'General') {
            availableQty = stockItem.calculatedCurrentStock;
            for (var jobDetail in stockItem.jobDetails.entries) {
              if (jobDetail.key != 'General') {
                availableQty -= jobDetail.value.allocatedQuantity;
              }
            }
          } else {
            final jobDetail = stockItem.jobDetails[jobNo];
            if (jobDetail != null) {
              availableQty =
                  jobDetail.allocatedQuantity - jobDetail.consumedQuantity;
            }
          }

          if (item.quantity > availableQty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Insufficient stock for ${item.materialDescription} in ${jobNo == 'General' ? 'general stock' : 'job $jobNo'}. Available: $availableQty, Requested: ${item.quantity}',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      final notifier = ref.read(deliveryChallanListProvider.notifier);
      final dc = DeliveryChallan(
        dcNo: widget.deliveryChallan?.dcNo ?? notifier.generateDcNo(),
        dcDate: _selectedDate,
        vendorName: isInternal ? 'Internal' : _selectedSupplier!.name,
        vendorEmail: isInternal ? null : _selectedSupplier!.email,
        vendorGstin: isInternal ? null : _selectedSupplier!.gstNo,
        items: _items,
        isReturnable: _isReturnable,
        note: _noteController.text,
        dcType: widget.presetDcType ?? 'regular',
        internalFlow: (widget.presetDcType == 'internal')
            ? (widget.presetInternalFlow ?? 'outward')
            : 'outward',
      );

      try {
        if (widget.deliveryChallan != null) {
          // Find the index of the existing DC
          final deliveryChallans = ref.read(deliveryChallanListProvider);
          final index = deliveryChallans
              .indexWhere((d) => d.dcNo == widget.deliveryChallan!.dcNo);
          if (index != -1) {
            await notifier.updateDeliveryChallan(index, dc, ref);
          }
          // For editing, just go back without PDF generation
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          await notifier.addDeliveryChallan(dc, ref);
          // For new DC, show PDF generation dialog
          if (mounted) {
            _showPDFGenerationDialog(dc);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPDFGenerationDialog(DeliveryChallan deliveryChallan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Challan Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DC No: ${deliveryChallan.dcNo}'),
            const SizedBox(height: 16),
            const Text('Choose how to save the PDF:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _navigateBackToDCList();
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _generateAndSaveToDownloads(deliveryChallan);
              _navigateBackToDCList();
            },
            child: const Text('Quick Save'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _generateAndSavePDF(deliveryChallan);
              _navigateBackToDCList();
            },
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  void _navigateBackToDCList() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _generateAndSavePDF(DeliveryChallan deliveryChallan) async {
    try {
      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveDeliveryChallan(
          deliveryChallan, _selectedSupplier!,
          materials: materials);

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save cancelled by user'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndSaveToDownloads(
      DeliveryChallan deliveryChallan) async {
    try {
      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveDeliveryChallanToDownloads(
          deliveryChallan, _selectedSupplier!,
          materials: materials);

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Platform.isMacOS || Platform.isIOS
                  ? 'PDF saved to Documents folder successfully!'
                  : 'PDF saved to Downloads folder successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save PDF to Downloads'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final saleOrders = ref.watch(saleOrderProvider);
    final materials = ref.watch(materialListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deliveryChallan != null
              ? 'Edit Delivery Challan'
              : 'New Delivery Challan',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Name Dropdown
              DropdownButtonFormField2<Supplier>(
                value: _selectedSupplier,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                ),
                items: suppliers
                    .map((supplier) => DropdownMenuItem(
                          value: supplier,
                          child: Text(supplier.name),
                        ))
                    .toList(),
                onChanged: (supplier) {
                  setState(() {
                    _selectedSupplier = supplier;
                    _vendorNameController.text = supplier?.name ?? '';
                    _vendorEmailController.text = supplier?.email ?? '';
                    _vendorGstinController.text = supplier?.gstNo ?? '';
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a vendor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Read-only Email field
              TextFormField(
                controller: _vendorEmailController,
                decoration: InputDecoration(
                  labelText: 'Vendor Email',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).disabledColor.withOpacity(0.1),
                  prefixIconColor: Theme.of(context).disabledColor,
                  suffixIconColor: Theme.of(context).disabledColor,
                ),
                style: TextStyle(color: Theme.of(context).disabledColor),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
              // Read-only GSTIN field
              TextFormField(
                controller: _vendorGstinController,
                decoration: InputDecoration(
                  labelText: 'Vendor GSTIN',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).disabledColor.withOpacity(0.1),
                  prefixIconColor: Theme.of(context).disabledColor,
                  suffixIconColor: Theme.of(context).disabledColor,
                ),
                style: TextStyle(color: Theme.of(context).disabledColor),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Returnable'),
                value: _isReturnable,
                onChanged: (value) {
                  setState(() {
                    _isReturnable = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
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
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showBulkEntryDialog(),
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Bulk Entry'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Material Code Selection
                          Expanded(
                            flex: 2,
                            child: Autocomplete<MaterialItem>(
                              fieldViewBuilder: (context, textEditingController,
                                  focusNode, onFieldSubmitted) {
                                // Set initial value without triggering rebuild
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (textEditingController.text.isEmpty &&
                                      item.materialCode.isNotEmpty) {
                                    textEditingController.text =
                                        item.materialCode;
                                  }
                                });
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Material Code',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (!materials.any((m) => m.partNo == v)) {
                                      return 'Invalid material code';
                                    }
                                    return null;
                                  },
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: 400,
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8.0),
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option =
                                              options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12.0,
                                                horizontal: 16.0,
                                              ),
                                              child: Text(
                                                '${option.partNo} - ${option.description}',
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              displayStringForOption: (material) =>
                                  material.partNo,
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return materials;
                                }
                                return materials.where((material) =>
                                    material.partNo.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase()));
                              },
                              onSelected: (material) {
                                setState(() {
                                  _items[index] = DeliveryChallanItem(
                                    materialCode: material.partNo,
                                    materialDescription: material.description,
                                    unit: material.unit,
                                    quantity: item.quantity,
                                    jobNo: item.jobNo,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Material Description Selection
                          Expanded(
                            flex: 4,
                            child: Autocomplete<MaterialItem>(
                              fieldViewBuilder: (context, textEditingController,
                                  focusNode, onFieldSubmitted) {
                                // Set initial value without triggering rebuild
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (textEditingController.text.isEmpty &&
                                      item.materialDescription.isNotEmpty) {
                                    textEditingController.text =
                                        item.materialDescription;
                                  }
                                });
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (!materials
                                        .any((m) => m.description == v)) {
                                      return 'Invalid material';
                                    }
                                    return null;
                                  },
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: 600,
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8.0),
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option =
                                              options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12.0,
                                                horizontal: 16.0,
                                              ),
                                              child: Text(
                                                option.description,
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              displayStringForOption: (material) =>
                                  material.description,
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return materials;
                                }
                                return materials.where((material) =>
                                    material.description.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase()));
                              },
                              onSelected: (material) {
                                setState(() {
                                  _items[index] = DeliveryChallanItem(
                                    materialCode: material.partNo,
                                    materialDescription: material.description,
                                    unit: material.unit,
                                    quantity: item.quantity,
                                    jobNo: item.jobNo,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: InputDecoration(
                                labelText: 'Quantity (${item.unit})',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                final qty = double.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final qty = double.tryParse(value) ?? 0;
                                setState(() {
                                  _items[index] = item.copyWith(quantity: qty);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField2<String>(
                              isExpanded: true,
                              value: item.jobNo ?? 'General',
                              decoration: const InputDecoration(
                                labelText: 'Job No',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'General',
                                  child: Text('General'),
                                ),
                                ...saleOrders
                                    .where((order) => order.boardNo.isNotEmpty)
                                    .map((order) => order.boardNo)
                                    .toSet() // Remove duplicates
                                    .map((boardNo) => DropdownMenuItem(
                                          value: boardNo,
                                          child: Text(boardNo),
                                        )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _items[index] = item.copyWith(
                                    jobNo: value == 'General' ? null : value,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveDeliveryChallan,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
