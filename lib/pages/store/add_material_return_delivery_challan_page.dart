import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/delivery_challan.dart';
import '../../services/pdf_service.dart';
import '../../models/supplier.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/sale_order_provider.dart';

class AddMaterialReturnDeliveryChallanPage extends ConsumerStatefulWidget {
  final DeliveryChallan? deliveryChallan;

  const AddMaterialReturnDeliveryChallanPage({super.key, this.deliveryChallan});

  @override
  ConsumerState<AddMaterialReturnDeliveryChallanPage> createState() =>
      _AddMaterialReturnDeliveryChallanPageState();
}

class _AddMaterialReturnDeliveryChallanPageState
    extends ConsumerState<AddMaterialReturnDeliveryChallanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dcNoController;
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
    _dcNoController = TextEditingController(
      text: widget.deliveryChallan?.dcNo ?? '',
    );
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
        Supplier? selected;
        try {
          selected = suppliers.firstWhere(
              (s) => s.name == widget.deliveryChallan!.vendorName);
        } catch (_) {
          selected = null;
        }
        setState(() {
          _selectedSupplier = selected;
          _vendorNameController.text = selected?.name ?? '';
          _vendorEmailController.text = selected?.email ?? '';
          _vendorGstinController.text = selected?.gstNo ?? '';
        });
      });
    }
  }

  @override
  void dispose() {
    _dcNoController.dispose();
    _vendorNameController.dispose();
    _vendorEmailController.dispose();
    _vendorGstinController.dispose();
    _noteController.dispose();
    _materialCodesController.dispose();
    _quantitiesController.dispose();
    super.dispose();
  }

  // Get items from outward DCs for the selected vendor.
  // Checks vendorName, toVendor, and fromVendor to handle all DC types.
  // For internal outward DCs: vendorName='Internal', actual vendor is in toVendor.
  // For regular/job_order DCs: vendor is in vendorName.
  // Excludes 'material_return' DCs to avoid circular references.
  List<DeliveryChallanItem> _getOutwardDcItemsForVendor(
      String vendorName, List<DeliveryChallan> allDcs) {
    final vLower = vendorName.toLowerCase().trim();
    bool nameMatches(DeliveryChallan dc) {
      if (dc.vendorName.toLowerCase().trim() == vLower) return true;
      if (dc.toVendor?.toLowerCase().trim() == vLower) return true;
      if (dc.fromVendor?.toLowerCase().trim() == vLower) return true;
      return false;
    }

    final outwardDcs = allDcs.where((dc) {
      if (dc.dcType == 'material_return') return false;
      if (dc.dcType == 'internal' && dc.internalFlow != 'outward') return false;
      return nameMatches(dc);
    }).toList();

    final List<DeliveryChallanItem> items = [];
    for (final dc in outwardDcs) {
      items.addAll(dc.items);
    }
    return items;
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

  Future<void> _showBulkEntryDialog(
      List<DeliveryChallanItem> outwardDcItems) async {
    _materialCodesController.clear();
    _quantitiesController.clear();
    bool isQuantityStep = false;
    List<String> materialCodes = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  isQuantityStep ? 'Enter Quantities' : 'Enter Material Codes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isQuantityStep) ...[
                    const Text(
                      'Enter material codes from outward DCs, one per line:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (outwardDcItems.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: outwardDcItems
                            .map((item) => ActionChip(
                                  label: Text(item.materialCode,
                                      style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    final existing =
                                        _materialCodesController.text;
                                    _materialCodesController.text = existing
                                            .isEmpty
                                        ? item.materialCode
                                        : '$existing\n${item.materialCode}';
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                      materialCodes = _materialCodesController.text
                          .split('\n')
                          .where((code) => code.trim().isNotEmpty)
                          .map((code) => code.trim())
                          .toList();

                      final invalidCodes = materialCodes
                          .where((code) => !outwardDcItems
                              .any((item) => item.materialCode == code))
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
                                    'The following codes were not found in outward DCs:'),
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

                      setDialogState(() {
                        isQuantityStep = true;
                      });
                    } else {
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

                      for (var i = 0; i < materialCodes.length; i++) {
                        final dcItem = outwardDcItems.firstWhere(
                            (item) => item.materialCode == materialCodes[i]);
                        final quantity = double.tryParse(quantities[i]) ?? 0;
                        setState(() {
                          _items.add(
                            DeliveryChallanItem(
                              materialCode: dcItem.materialCode,
                              materialDescription: dcItem.materialDescription,
                              unit: dcItem.unit,
                              quantity: quantity,
                              jobNo: dcItem.jobNo,
                              price: dcItem.price,
                            ),
                          );
                        });
                      }

                      Navigator.pop(context);
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

      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vendor')),
        );
        return;
      }

      final notifier = ref.read(deliveryChallanListProvider.notifier);

      final dc = DeliveryChallan(
        dcNo: _dcNoController.text.trim(),
        dcDate: _selectedDate,
        vendorName: _selectedSupplier!.name,
        vendorEmail: _selectedSupplier!.email,
        vendorGstin: _selectedSupplier!.gstNo,
        items: _items,
        isReturnable: _isReturnable,
        note: _noteController.text,
        dcType: 'material_return',
        internalFlow: 'outward',
        fromVendor: null,
        toVendor: null,
      );

      try {
        if (widget.deliveryChallan != null) {
          final deliveryChallans = ref.read(deliveryChallanListProvider);
          final index = deliveryChallans
              .indexWhere((d) => d.dcNo == widget.deliveryChallan!.dcNo);
          if (index != -1) {
            await notifier.updateDeliveryChallan(index, dc, ref);
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          await notifier.addDeliveryChallan(dc, ref);
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
        title: const Text('Material Return DC Created Successfully!'),
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
              Navigator.pop(context);
              _navigateBack();
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSaveToDownloads(deliveryChallan);
              _navigateBack();
            },
            child: const Text('Quick Save'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSavePDF(deliveryChallan);
              _navigateBack();
            },
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  void _navigateBack() {
    if (mounted) Navigator.pop(context);
  }

  Future<void> _generateAndSavePDF(DeliveryChallan deliveryChallan) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveDeliveryChallan(
          deliveryChallan, _selectedSupplier!,
          materials: materials);

      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'PDF saved successfully!' : 'Save cancelled by user'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveDeliveryChallanToDownloads(
          deliveryChallan, _selectedSupplier!,
          materials: materials);

      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? (Platform.isMacOS || Platform.isIOS
                    ? 'PDF saved to Documents folder successfully!'
                    : 'PDF saved to Downloads folder successfully!')
                : 'Failed to save PDF to Downloads'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
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
    final allDeliveryChallans = ref.watch(deliveryChallanListProvider);

    // Fetch items from outward DCs for the selected vendor
    final outwardDcItems = _selectedSupplier != null
        ? _getOutwardDcItemsForVendor(
            _selectedSupplier!.name, allDeliveryChallans)
        : <DeliveryChallanItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deliveryChallan != null
            ? 'Edit Material Return DC'
            : 'New Material Return DC'),
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom + 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DC Number and Date Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dcNoController,
                        decoration: const InputDecoration(
                          labelText: 'DC Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter DC number';
                          }
                          if (widget.deliveryChallan == null) {
                            final existingDCs =
                                ref.read(deliveryChallanListProvider);
                            if (existingDCs
                                .any((dc) => dc.dcNo == value.trim())) {
                              return 'DC number already exists';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'DC Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller:
                            TextEditingController(text: _selectedDate),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(_selectedDate),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate =
                                  picked.toString().split(' ')[0];
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select date';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      // Clear items when vendor changes
                      _items = [];
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a vendor';
                    }
                    return null;
                  },
                  dropdownSearchData: DropdownSearchData(
                    searchController: TextEditingController(),
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
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: 'Search vendor...',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value!.name
                          .toLowerCase()
                          .contains(searchValue.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Read-only Email field
                TextFormField(
                  controller: _vendorEmailController,
                  decoration: InputDecoration(
                    labelText: 'Vendor Email',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor:
                        Theme.of(context).disabledColor.withOpacity(0.1),
                    prefixIconColor: Theme.of(context).disabledColor,
                    suffixIconColor: Theme.of(context).disabledColor,
                  ),
                  style:
                      TextStyle(color: Theme.of(context).disabledColor),
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
                    fillColor:
                        Theme.of(context).disabledColor.withOpacity(0.1),
                    prefixIconColor: Theme.of(context).disabledColor,
                    suffixIconColor: Theme.of(context).disabledColor,
                  ),
                  style:
                      TextStyle(color: Theme.of(context).disabledColor),
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
                // Outward DC Items Banner
                if (_selectedSupplier != null) ...[
                  if (outwardDcItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No outward delivery challans found for ${_selectedSupplier!.name}. Add items manually.',
                              style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${outwardDcItems.length} item(s) found from outward DCs for ${_selectedSupplier!.name}',
                              style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                // Items header
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
                        if (_selectedSupplier != null &&
                            outwardDcItems.isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showBulkEntryDialog(outwardDcItems),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Bulk Entry'),
                          ),
                          const SizedBox(width: 8),
                        ],
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
                              child: Autocomplete<DeliveryChallanItem>(
                                key: ValueKey(
                                    'mr_code_${_selectedSupplier?.name}_$index'),
                                fieldViewBuilder: (context,
                                    textEditingController,
                                    focusNode,
                                    onFieldSubmitted) {
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
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        side: BorderSide(
                                          color:
                                              Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                          maxWidth: 400,
                                        ),
                                        child: ListView.builder(
                                          padding:
                                              const EdgeInsets.all(8.0),
                                          itemCount: options.length,
                                          itemBuilder: (context, idx) {
                                            final option =
                                                options.elementAt(idx);
                                            return InkWell(
                                              onTap: () =>
                                                  onSelected(option),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                                child: Text(
                                                  '${option.materialCode} - ${option.materialDescription}',
                                                  style: const TextStyle(
                                                      fontSize: 14.0),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                displayStringForOption: (dcItem) =>
                                    dcItem.materialCode,
                                optionsBuilder: (textEditingValue) {
                                  if (outwardDcItems.isEmpty) {
                                    return const Iterable.empty();
                                  }
                                  if (textEditingValue.text.isEmpty) {
                                    return outwardDcItems;
                                  }
                                  return outwardDcItems.where((dcItem) =>
                                      dcItem.materialCode
                                          .toLowerCase()
                                          .contains(textEditingValue.text
                                              .toLowerCase()));
                                },
                                onSelected: (dcItem) {
                                  setState(() {
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: dcItem.materialCode,
                                      materialDescription:
                                          dcItem.materialDescription,
                                      unit: dcItem.unit,
                                      quantity: item.quantity > 0
                                          ? item.quantity
                                          : dcItem.quantity,
                                      jobNo: dcItem.jobNo,
                                      price: dcItem.price,
                                    );
                                  });
                                  _formKey.currentState?.validate();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Material Description Selection
                            Expanded(
                              flex: 4,
                              child: Autocomplete<DeliveryChallanItem>(
                                key: ValueKey(
                                    'mr_desc_${_selectedSupplier?.name}_$index'),
                                fieldViewBuilder: (context,
                                    textEditingController,
                                    focusNode,
                                    onFieldSubmitted) {
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
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        side: BorderSide(
                                          color:
                                              Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                          maxWidth: 600,
                                        ),
                                        child: ListView.builder(
                                          padding:
                                              const EdgeInsets.all(8.0),
                                          itemCount: options.length,
                                          itemBuilder: (context, idx) {
                                            final option =
                                                options.elementAt(idx);
                                            return InkWell(
                                              onTap: () =>
                                                  onSelected(option),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                                child: Text(
                                                  option.materialDescription,
                                                  style: const TextStyle(
                                                      fontSize: 14.0),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                displayStringForOption: (dcItem) =>
                                    dcItem.materialDescription,
                                optionsBuilder: (textEditingValue) {
                                  if (outwardDcItems.isEmpty) {
                                    return const Iterable.empty();
                                  }
                                  if (textEditingValue.text.isEmpty) {
                                    return outwardDcItems;
                                  }
                                  return outwardDcItems.where((dcItem) =>
                                      dcItem.materialDescription
                                          .toLowerCase()
                                          .contains(textEditingValue.text
                                              .toLowerCase()));
                                },
                                onSelected: (dcItem) {
                                  setState(() {
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: dcItem.materialCode,
                                      materialDescription:
                                          dcItem.materialDescription,
                                      unit: dcItem.unit,
                                      quantity: item.quantity > 0
                                          ? item.quantity
                                          : dcItem.quantity,
                                      jobNo: dcItem.jobNo,
                                      price: dcItem.price,
                                    );
                                  });
                                  _formKey.currentState?.validate();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Quantity
                            Expanded(
                              child: TextFormField(
                                initialValue: item.quantity == 0
                                    ? ''
                                    : item.quantity.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Qty (${item.unit})',
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final qty = double.tryParse(value);
                                  if (qty == null || qty <= 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final qty = double.tryParse(value) ?? 0;
                                  setState(() {
                                    _items[index] =
                                        item.copyWith(quantity: qty);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Price
                            Expanded(
                              child: TextFormField(
                                initialValue: item.price.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price < 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final price =
                                      double.tryParse(value) ?? 0.0;
                                  setState(() {
                                    _items[index] =
                                        item.copyWith(price: price);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Job No
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
                                      .where((order) =>
                                          order.boardNo.isNotEmpty)
                                      .map((order) => order.boardNo)
                                      .toSet()
                                      .map((boardNo) => DropdownMenuItem(
                                            value: boardNo,
                                            child: Text(boardNo),
                                          )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _items[index] = item.copyWith(
                                      jobNo: value == 'General'
                                          ? null
                                          : value,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveDeliveryChallan,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
