import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/delivery_challan.dart';
import '../../services/pdf_service.dart';
import '../../models/material_item.dart';
import '../../models/customer_scope_material_issue_master.dart';
import '../../models/supplier.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/sale_order_provider.dart';
import '../../provider/customer_scope_material_issue_master_provider.dart';

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
  // Material source selection for JODC type
  String _materialSource = 'material_master'; // 'material_master' or 'customer_scope'

  @override
  void initState() {
    super.initState();
    // For internal outward DCs, DC number will be auto-generated
    // For internal inward DCs, allow manual input
    // For job order DCs, JODC number will be auto-generated
    final isInternalOutward = widget.presetDcType == 'internal' && 
                              widget.presetInternalFlow == 'outward';
    final isJobOrder = widget.presetDcType == 'job_order';
    
    _dcNoController = TextEditingController(
      text: widget.deliveryChallan?.dcNo ?? (isInternalOutward || isJobOrder ? '' : ''),
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

    // Auto-generate DC number for job orders after first frame
    if (isJobOrder && widget.deliveryChallan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(deliveryChallanListProvider.notifier);
        final nextJODCNumber = notifier.generateNextJODCNumber();
        setState(() {
          _dcNoController.text = nextJODCNumber;
        });
      });
    }

    // Initialize selected supplier if editing
    if (widget.deliveryChallan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final suppliers = ref.read(supplierListProvider);
        final isInternal = widget.deliveryChallan!.dcType == 'internal';
        final matchName = isInternal
            ? (widget.deliveryChallan!.internalFlow == 'inward'
                ? (widget.deliveryChallan!.fromVendor ?? '')
                : (widget.deliveryChallan!.toVendor ?? ''))
            : widget.deliveryChallan!.vendorName;

        Supplier? selected;
        try {
          selected = suppliers.firstWhere((s) => s.name == matchName);
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

  // Helper method to get available materials based on selected source
  List<Object> _getAvailableMaterials(List<MaterialItem> materials, List<CustomerScopeMaterialIssueMaster> customerScopeMaterials) {
    if (widget.presetDcType == 'job_order' && _materialSource == 'customer_scope') {
      return customerScopeMaterials.cast<Object>();
    }
    return materials.cast<Object>();
  }

  // Helper method to validate material code based on source
  bool _isValidMaterialCode(String code, List<MaterialItem> materials, List<CustomerScopeMaterialIssueMaster> customerScopeMaterials, [List<DeliveryChallanItem> outwardDcItems = const []]) {
    final trimmedCode = code.trim();
    if (widget.presetDcType == 'material_return' && outwardDcItems.isNotEmpty) {
      return outwardDcItems.any((item) => item.materialCode.trim() == trimmedCode);
    }
    if (widget.presetDcType == 'job_order' && _materialSource == 'customer_scope') {
      return customerScopeMaterials.any((m) => m.partNo.trim() == trimmedCode);
    }
    return materials.any((m) => m.partNo.trim() == trimmedCode);
  }

  // Helper method to validate material description based on source
  bool _isValidMaterialDescription(String desc, List<MaterialItem> materials, List<CustomerScopeMaterialIssueMaster> customerScopeMaterials, [List<DeliveryChallanItem> outwardDcItems = const []]) {
    final trimmedDesc = desc.trim();
    if (widget.presetDcType == 'material_return' && outwardDcItems.isNotEmpty) {
      return outwardDcItems.any((item) => item.materialDescription.trim() == trimmedDesc);
    }
    if (widget.presetDcType == 'job_order' && _materialSource == 'customer_scope') {
      return customerScopeMaterials.any((m) => m.description.trim() == trimmedDesc);
    }
    return materials.any((m) => m.description.trim() == trimmedDesc);
  }

  // Helper method to find material by code
  dynamic _findMaterialByCode(String code, List<MaterialItem> materials, List<CustomerScopeMaterialIssueMaster> customerScopeMaterials) {
    if (widget.presetDcType == 'job_order' && _materialSource == 'customer_scope') {
      return customerScopeMaterials.firstWhere(
        (m) => m.partNo == code,
        orElse: () => null as CustomerScopeMaterialIssueMaster,
      );
    }
    return materials.firstWhere(
      (m) => m.partNo == code,
      orElse: () => null as MaterialItem,
    );
  }

  Future<void> _showBulkEntryDialog() async {
    _materialCodesController.clear();
    _quantitiesController.clear();
    bool isQuantityStep = false;
    List<String> materialCodes = [];
    final materials = ref.read(materialListProvider);
    final customerScopeMaterials = ref.read(customerScopeMaterialIssueMasterListProvider);
    
    // Get correct material list based on source
    final availableMaterials = _getAvailableMaterials(materials, customerScopeMaterials);

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
                              (code) => !availableMaterials.any((m) => 
                                  (m is CustomerScopeMaterialIssueMaster ? m.partNo : (m as MaterialItem).partNo) == code))
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
                        final material = availableMaterials.firstWhere(
                            (m) => (m is CustomerScopeMaterialIssueMaster 
                                ? m.partNo 
                                : (m as MaterialItem).partNo) == materialCodes[i]);
                        final quantity = double.tryParse(quantities[i]) ?? 0;

                        if (material is CustomerScopeMaterialIssueMaster) {
                          _items.add(
                            DeliveryChallanItem(
                              materialCode: material.partNo,
                              materialDescription: material.description,
                              unit: material.unit,
                              quantity: quantity,
                              jobNo: null,
                              price: 0.0,
                            ),
                          );
                        } else {
                          final m = material as MaterialItem;
                          _items.add(
                            DeliveryChallanItem(
                              materialCode: m.partNo,
                              materialDescription: m.description,
                              unit: m.unit,
                              quantity: quantity,
                              jobNo: null,
                              price: 0.0,
                            ),
                          );
                        }
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
      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vendor')),
        );
        return;
      }

      final notifier = ref.read(deliveryChallanListProvider.notifier);

      final internalFlow = (widget.presetDcType == 'internal')
          ? (widget.presetInternalFlow ?? 'outward')
          : 'outward';

      final internalFromVendor = isInternal
          ? (internalFlow == 'inward' ? _selectedSupplier!.name : 'Store')
          : null;
      final internalToVendor = isInternal
          ? (internalFlow == 'inward' ? 'Store' : _selectedSupplier!.name)
          : null;

      // Auto-generate DC number for internal outward DCs and job orders
      final isInternalOutward = isInternal && internalFlow == 'outward';
      final isJobOrder = widget.presetDcType == 'job_order';
      
      String dcNo;
      if (widget.deliveryChallan == null) {
        // New DC - auto-generate if needed
        if (isJobOrder) {
          dcNo = _dcNoController.text.trim();
        } else if (isInternalOutward) {
          dcNo = notifier.generateInternalOutwardDcNo();
        } else {
          dcNo = _dcNoController.text.trim();
        }
      } else {
        // Editing existing DC - use existing number
        dcNo = _dcNoController.text.trim();
      }

      final dc = DeliveryChallan(
        dcNo: dcNo,
        dcDate: _selectedDate,
        vendorName: isInternal ? 'Internal' : _selectedSupplier!.name,
        vendorEmail: _selectedSupplier!.email,
        vendorGstin: _selectedSupplier!.gstNo,
        items: _items,
        isReturnable: _isReturnable,
        note: _noteController.text,
        dcType: widget.presetDcType ?? 'regular',
        internalFlow: internalFlow,
        fromVendor: internalFromVendor,
        toVendor: internalToVendor,
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

  // Helper method to get outward DC items for material return
  List<DeliveryChallanItem> _getOutwardDcItemsForVendor(String vendorName, List<DeliveryChallan> allDcs) {
    final outwardDcs = allDcs.where((dc) => 
      dc.dcType == 'regular' && 
      dc.vendorName.toLowerCase() == vendorName.toLowerCase()
    ).toList();
    
    final List<DeliveryChallanItem> items = [];
    for (final dc in outwardDcs) {
      items.addAll(dc.items);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final saleOrders = ref.watch(saleOrderProvider);
    final materials = ref.watch(materialListProvider);
    final customerScopeMaterials = ref.watch(customerScopeMaterialIssueMasterListProvider);
    final allDeliveryChallans = ref.watch(deliveryChallanListProvider);

    // Get outward DC items for material return
    final outwardDcItems = widget.presetDcType == 'material_return' && _selectedSupplier != null
        ? _getOutwardDcItemsForVendor(_selectedSupplier!.name, allDeliveryChallans)
        : <DeliveryChallanItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deliveryChallan != null
              ? 'Edit Delivery Challan'
              : (widget.presetDcType == 'job_order' 
                  ? 'New Job Order Delivery Challan'
                  : 'New Delivery Challan'),
        ),
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
                  // Show DC Number input only for non-job-order and non-internal-outward DCs
                  if (!(widget.presetDcType == 'job_order') && 
                      !(widget.presetDcType == 'internal' && widget.presetInternalFlow == 'outward')) ...[
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
                          // Check uniqueness only for new DCs
                          if (widget.deliveryChallan == null) {
                            final existingDCs = ref.read(deliveryChallanListProvider);
                            if (existingDCs.any((dc) => dc.dcNo == value.trim())) {
                              return 'DC number already exists';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Show auto-generated DC number for job orders and internal outward
                  if (widget.presetDcType == 'job_order' || 
                      (widget.presetDcType == 'internal' && widget.presetInternalFlow == 'outward')) ...[
                    Expanded(
                      child: TextFormField(
                        controller: _dcNoController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: widget.presetDcType == 'job_order' 
                              ? 'Job Order DC Number'
                              : 'DC Number',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.confirmation_number),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'DC Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(text: _selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(_selectedDate),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked.toString().split(' ')[0];
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
              // Material Source Selection for JODC type
              if (widget.presetDcType == 'job_order') ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Material Source',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Material Master'),
                              value: 'material_master',
                              groupValue: _materialSource,
                              onChanged: (value) {
                                setState(() {
                                  _materialSource = value!;
                                });
                              },
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Customer Scope Material Issue Master'),
                              value: 'customer_scope',
                              groupValue: _materialSource,
                              onChanged: (value) {
                                setState(() {
                                  _materialSource = value!;
                                });
                              },
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                            child: Autocomplete<Object>(
                              key: ValueKey('material_code_${_materialSource}_$index'),
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
                                  decoration: InputDecoration(
                                    labelText: 'Material Code',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: widget.presetDcType == 'job_order'
                                        ? Icon(
                                            _materialSource == 'customer_scope'
                                                ? Icons.inventory_2_outlined
                                                : Icons.warehouse_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    // Skip strict validation - Autocomplete already restricts to valid materials
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
                                          final partNo = option is CustomerScopeMaterialIssueMaster
                                              ? option.partNo
                                              : (option as MaterialItem).partNo;
                                          final description = option is CustomerScopeMaterialIssueMaster
                                              ? option.description
                                              : (option as MaterialItem).description;
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12.0,
                                                horizontal: 16.0,
                                              ),
                                              child: Text(
                                                '$partNo - $description',
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
                              displayStringForOption: (material) {
                                if (material is DeliveryChallanItem) {
                                  return material.materialCode;
                                }
                                if (material is CustomerScopeMaterialIssueMaster) {
                                  return material.partNo;
                                }
                                return (material as MaterialItem).partNo;
                              },
                              optionsBuilder: (textEditingValue) {
                                // For material return, show items from outward DCs for the selected vendor
                                if (widget.presetDcType == 'material_return' && _selectedSupplier != null) {
                                  if (textEditingValue.text.isEmpty) {
                                    return outwardDcItems;
                                  }
                                  return outwardDcItems.where((item) => 
                                    item.materialCode.toLowerCase().contains(textEditingValue.text.toLowerCase())
                                  );
                                }
                                // For other DC types, use regular materials
                                final availableMaterials = _getAvailableMaterials(materials, customerScopeMaterials);
                                if (textEditingValue.text.isEmpty) {
                                  return availableMaterials;
                                }
                                return availableMaterials.where((material) {
                                  final partNo = material is CustomerScopeMaterialIssueMaster 
                                      ? material.partNo 
                                      : (material as MaterialItem).partNo;
                                  return partNo.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase());
                                });
                              },
                              onSelected: (material) {
                                setState(() {
                                  if (material is DeliveryChallanItem) {
                                    // For material return, copy the item directly
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: material.materialCode,
                                      materialDescription: material.materialDescription,
                                      unit: material.unit,
                                      quantity: material.quantity,
                                      jobNo: material.jobNo,
                                      price: material.price,
                                    );
                                  } else if (material is CustomerScopeMaterialIssueMaster) {
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: material.partNo,
                                      materialDescription: material.description,
                                      unit: material.unit,
                                      quantity: item.quantity,
                                      jobNo: item.jobNo,
                                      price: item.price,
                                    );
                                  } else {
                                    final m = material as MaterialItem;
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: m.partNo,
                                      materialDescription: m.description,
                                      unit: m.unit,
                                      quantity: item.quantity,
                                      jobNo: item.jobNo,
                                      price: item.price,
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Material Description Selection
                          Expanded(
                            flex: 4,
                            child: Autocomplete<Object>(
                              key: ValueKey('material_desc_${_materialSource}_$index'),
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
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: widget.presetDcType == 'job_order'
                                        ? Icon(
                                            _materialSource == 'customer_scope'
                                                ? Icons.inventory_2_outlined
                                                : Icons.warehouse_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    // Skip strict validation - Autocomplete already restricts to valid materials
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
                                          final description = option is CustomerScopeMaterialIssueMaster
                                              ? option.description
                                              : (option as MaterialItem).description;
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12.0,
                                                horizontal: 16.0,
                                              ),
                                              child: Text(
                                                description,
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
                              displayStringForOption: (material) {
                                if (material is DeliveryChallanItem) {
                                  return material.materialDescription;
                                }
                                if (material is CustomerScopeMaterialIssueMaster) {
                                  return material.description;
                                }
                                return (material as MaterialItem).description;
                              },
                              optionsBuilder: (textEditingValue) {
                                // For material return, show items from outward DCs for the selected vendor
                                if (widget.presetDcType == 'material_return' && _selectedSupplier != null) {
                                  if (textEditingValue.text.isEmpty) {
                                    return outwardDcItems;
                                  }
                                  return outwardDcItems.where((item) => 
                                    item.materialDescription.toLowerCase().contains(textEditingValue.text.toLowerCase())
                                  );
                                }
                                // For other DC types, use regular materials
                                final availableMaterials = _getAvailableMaterials(materials, customerScopeMaterials);
                                if (textEditingValue.text.isEmpty) {
                                  return availableMaterials;
                                }
                                return availableMaterials.where((material) {
                                  final desc = material is CustomerScopeMaterialIssueMaster 
                                      ? material.description 
                                      : (material as MaterialItem).description;
                                  return desc.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase());
                                });
                              },
                              onSelected: (material) {
                                setState(() {
                                  if (material is DeliveryChallanItem) {
                                    // For material return, copy the item directly
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: material.materialCode,
                                      materialDescription: material.materialDescription,
                                      unit: material.unit,
                                      quantity: material.quantity,
                                      jobNo: material.jobNo,
                                      price: material.price,
                                    );
                                  } else if (material is CustomerScopeMaterialIssueMaster) {
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: material.partNo,
                                      materialDescription: material.description,
                                      unit: material.unit,
                                      quantity: item.quantity,
                                      jobNo: item.jobNo,
                                      price: item.price,
                                    );
                                  } else {
                                    final m = material as MaterialItem;
                                    _items[index] = DeliveryChallanItem(
                                      materialCode: m.partNo,
                                      materialDescription: m.description,
                                      unit: m.unit,
                                      quantity: item.quantity,
                                      jobNo: item.jobNo,
                                      price: item.price,
                                    );
                                  }
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
                            child: TextFormField(
                              initialValue: item.price.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final price = double.tryParse(value) ?? 0.0;
                                setState(() {
                                  _items[index] = item.copyWith(price: price);
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveDeliveryChallan,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
