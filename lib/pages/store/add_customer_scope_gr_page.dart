// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/customer_scope_material_issue_master_provider.dart';
import '../../models/customer_scope_material_issue_master.dart';
import '../../models/customer.dart';
import '../../provider/customer_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../provider/purchase_request_provider.dart';
import 'package:mpt_ims/pages/store/select_jobs_dialog.dart';
import '../planning/add_customer_free_issue_page.dart';

class AddCustomerScopeGRPage extends ConsumerStatefulWidget {
  final StoreInward? existingGR;
  final int? index;

  const AddCustomerScopeGRPage({
    super.key,
    this.existingGR,
    this.index,
  });

  @override
  ConsumerState<AddCustomerScopeGRPage> createState() => _AddCustomerScopeGRPageState();
}

class _AddCustomerScopeGRPageState extends ConsumerState<AddCustomerScopeGRPage> {
  final _formKey = GlobalKey<FormState>();
  final _grnDateController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _partNumberFilterController = TextEditingController();
  final TextEditingController _descriptionFilterController = TextEditingController();

  Customer? selectedCustomer;
  List<String> selectedJobs = ['All'];
  
  // Simplified data structure: Material -> PR -> Quantity
  Map<String, Map<String, TextEditingController>> prQtyControllers = {};
  Map<String, Map<String, TextEditingController>> priceControllers = {};
  
  bool _isLoading = false;

  String _generateGRNNo() {
    return ref.read(storeInwardProvider.notifier).generateGRNNumber();
  }

  @override
  void initState() {
    super.initState();
    
    // Load customer data
    Future.microtask(() async {
      try {
        await ref.read(customerListProvider.notifier).loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading customers: $e')),
          );
        }
      }
    });

    // Initialize for edit mode
    if (widget.existingGR != null) {
      selectedCustomer = ref
          .read(customerListProvider)
          .firstWhere((c) => c.name == widget.existingGR!.customerName,
              orElse: () => ref.read(customerListProvider).first);
      _grnDateController.text = widget.existingGR!.grnDate;
      _invoiceNoController.text = widget.existingGR!.invoiceNo;
      _invoiceDateController.text = widget.existingGR!.invoiceDate;
      _invoiceAmountController.text =
          widget.existingGR!.invoiceAmount.toStringAsFixed(2);
      _receivedByController.text = widget.existingGR!.receivedBy;
      _checkedByController.text = widget.existingGR!.checkedBy;
    } else {
      _grnDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _grnDateController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _invoiceAmountController.dispose();
    _receivedByController.dispose();
    _checkedByController.dispose();
    _customerSearchController.dispose();
    _partNumberFilterController.dispose();
    _descriptionFilterController.dispose();
    
    for (var prMap in prQtyControllers.values) {
      for (var controller in prMap.values) {
        controller.dispose();
      }
    }
    for (var prMap in priceControllers.values) {
      for (var controller in prMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Set<String> _getUniqueJobNumbers(List<PurchaseRequest> purchaseRequests) {
    final Set<String> jobNos = {'All'};
    for (var pr in purchaseRequests) {
      final j = pr.jobNo?.trim() ?? '';
      if (j.isNotEmpty) {
        jobNos.add(j);
      }
    }
    return jobNos;
  }

  bool _hasInputData(String materialPartNo) {
    final qtyControllers = prQtyControllers[materialPartNo];
    final priceControllersMap = priceControllers[materialPartNo];
    
    if (qtyControllers == null || priceControllersMap == null) return false;
    
    for (var entry in qtyControllers.entries) {
      final prNo = entry.key;
      final qty = double.tryParse(entry.value.text) ?? 0.0;
      final price = double.tryParse(priceControllersMap[prNo]?.text ?? '0') ?? 0.0;
      
      if (qty > 0 || price > 0) {
        return true;
      }
    }
    return false;
  }

  void _updateInvoiceAmount() {
    double total = 0.0;
    for (var entry in prQtyControllers.entries) {
      final materialCode = entry.key;
      final prControllers = entry.value;
      for (var prEntry in prControllers.entries) {
        final prNo = prEntry.key;
        final qty = double.tryParse(prEntry.value.text) ?? 0.0;
        final price = double.tryParse(
            priceControllers[materialCode]?[prNo]?.text ?? '0') ?? 0.0;
        total += qty * price;
      }
    }

    // Calculate GST
    final customer = selectedCustomer;
    if (customer != null) {
      final igst = total *
          (double.tryParse(customer.igst.replaceAll('%', '')) ?? 0) /
          100;
      final cgst = total *
          (double.tryParse(customer.cgst.replaceAll('%', '')) ?? 0) /
          100;
      final sgst = total *
          (double.tryParse(customer.sgst.replaceAll('%', '')) ?? 0) /
          100;
      total += igst + cgst + sgst;
    }

    setState(() {
      _invoiceAmountController.text = total.toStringAsFixed(2);
    });
  }

  Widget _buildItemCard(CustomerScopeMaterialIssueMaster material, List<PurchaseRequest> prs) {
    // Initialize controllers for this material if not exists
    if (!prQtyControllers.containsKey(material.partNo)) {
      prQtyControllers[material.partNo] = {};
      priceControllers[material.partNo] = {};
      
      for (var pr in prs) {
        final prItem = pr.items.firstWhere(
          (item) => item.materialCode == material.partNo,
        );
        
        prQtyControllers[material.partNo]![pr.prNo] =
            TextEditingController(text: '0');
        priceControllers[material.partNo]![pr.prNo] =
            TextEditingController(text: '0');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${material.partNo} | Unit: ${material.unit}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // PR List
          ...prs.map((pr) {
            final prItem = pr.items.firstWhere(
              (item) => item.materialCode == material.partNo,
            );
            
            final totalRequired = double.tryParse(prItem.quantity) ?? 0.0;
            final totalReceived = prItem.totalReceivedQuantity;
            final pendingQty = totalRequired - totalReceived;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PR: ${pr.prNo}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Job: ${pr.jobNo ?? "General"}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pending: ${pendingQty.toStringAsFixed(2)} ${material.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: priceControllers[material.partNo]![pr.prNo],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateInvoiceAmount(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: prQtyControllers[material.partNo]![pr.prNo],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            labelText: 'Qty',
                            border: const OutlineInputBorder(),
                            suffixText: material.unit,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateInvoiceAmount(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _saveGR() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    // Validate at least one quantity is entered
    bool hasQuantity = false;
    for (var prMap in prQtyControllers.values) {
      for (var controller in prMap.values) {
        if ((double.tryParse(controller.text) ?? 0.0) > 0) {
          hasQuantity = true;
          break;
        }
      }
      if (hasQuantity) break;
    }

    if (!hasQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final grnNo = widget.existingGR?.grnNo ?? _generateGRNNo();
      final purchaseRequests = ref.read(purchaseRequestListProvider);
      final prNotifier = ref.read(purchaseRequestListProvider.notifier);
      final grNotifier = ref.read(storeInwardProvider.notifier);

      // Create inward items
      final inwardItems = <InwardItem>[];
      final prNos = <String>{};

      for (var entry in prQtyControllers.entries) {
        final materialCode = entry.key;
        final prControllers = entry.value;
        
        final material = ref
            .read(customerScopeMaterialIssueMasterListProvider)
            .firstWhere((m) => m.partNo == materialCode);
        
        double totalReceivedQty = 0;
        final inwardItem = InwardItem(
          materialCode: materialCode,
          materialDescription: material.description,
          unit: material.unit,
          orderedQty: 0,
          receivedQty: 0,
          acceptedQty: 0,
          rejectedQty: 0,
          costPerUnit: '0',
        );

        for (var prEntry in prControllers.entries) {
          final prNo = prEntry.key;
          final qty = double.tryParse(prEntry.value.text) ?? 0.0;
          if (qty <= 0) continue;

          final pr = purchaseRequests.firstWhere((pr) => pr.prNo == prNo);
          final prItem = pr.items.firstWhere(
            (item) => item.materialCode == materialCode,
          );

          // Update PR item received quantity
          prItem.totalReceivedQuantity += qty;
          
          // Update PR status
          pr.updateStatus();
          await prNotifier.update(pr);

          // Set price
          final price = double.tryParse(
              priceControllers[materialCode]?[prNo]?.text ?? '0') ?? 0.0;
          inwardItem.costPerUnit = price.toStringAsFixed(2);

          // Add to inward item (using PR as "PO" reference for compatibility)
          inwardItem.addPRQuantity(prNo, prNo, qty);
          inwardItem.addJobNumberForPR(prNo, prNo, pr.jobNo ?? 'General');
          
          totalReceivedQty += qty;
          prNos.add(prNo);
          
          inwardItem.orderedQty = double.tryParse(prItem.quantity) ?? 0.0;
        }

        if (totalReceivedQty > 0) {
          inwardItem.receivedQty = totalReceivedQty;
          inwardItems.add(inwardItem);
        }
      }

      // Create or update GR
      final newGR = StoreInward(
        grnNo: grnNo,
        grnDate: _grnDateController.text,
        supplierName: selectedCustomer!.name,
        poNo: prNos.join(', '), // Store PR numbers
        poDate: '',
        invoiceNo: _invoiceNoController.text,
        invoiceDate: _invoiceDateController.text,
        invoiceAmount:
            StoreInward.parseInvoiceAmount(_invoiceAmountController.text),
        receivedBy: _receivedByController.text,
        checkedBy: _checkedByController.text,
        items: inwardItems,
        isCustomerScope: true,
        customerId: selectedCustomer!.customerCode,
        customerName: selectedCustomer!.name,
      );

      // Save the GR
      if (widget.existingGR != null && widget.index != null) {
        grNotifier.updateInward(widget.index!, newGR);
      } else {
        grNotifier.addInward(newGR);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goods Receipt saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving GR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving GR: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);
    
    // Get CFI Purchase Requests for selected customer
    final allPurchaseRequests = ref
        .watch(purchaseRequestListProvider)
        .where((pr) {
          if (!pr.prNo.startsWith('CFI')) return false;
          // Filter by selected customer if one is selected
          if (selectedCustomer != null) {
            return pr.customerName == selectedCustomer!.name;
          }
          return true;
        })
        .toList();

    // Get unique job numbers
    final availableJobs = _getUniqueJobNumbers(allPurchaseRequests);

    // Get materials that have pending quantities in CFI PRs
    var materials = ref.watch(customerScopeMaterialIssueMasterListProvider).where((material) {
      // Apply part number filter
      final partNumberFilter = _partNumberFilterController.text.trim().toLowerCase();
      if (partNumberFilter.isNotEmpty && !material.partNo.toLowerCase().contains(partNumberFilter)) {
        return false;
      }
      
      // Apply description filter
      final descriptionFilter = _descriptionFilterController.text.trim().toLowerCase();
      if (descriptionFilter.isNotEmpty && !material.description.toLowerCase().contains(descriptionFilter)) {
        return false;
      }
      
      return allPurchaseRequests.any((pr) {
        // Skip if job filter is active and this PR's job doesn't match
        if (!selectedJobs.contains('All') && 
            !selectedJobs.contains(pr.jobNo ?? '')) {
          return false;
        }
        
        final prItems = pr.items.where((item) => item.materialCode == material.partNo);
        if (prItems.isEmpty) return false;

        for (var item in prItems) {
          final totalRequired = double.tryParse(item.quantity) ?? 0.0;
          final totalReceived = item.totalReceivedQuantity;
          
          if (totalReceived < totalRequired) {
            return true;
          }
        }
        return false;
      });
    }).toList();

    // Sort materials: ones with input data at the top, followed by the rest
    materials.sort((a, b) {
      final aHasInput = _hasInputData(a.partNo);
      final bHasInput = _hasInputData(b.partNo);
      if (aHasInput && !bHasInput) return -1;
      if (!aHasInput && bHasInput) return 1;
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingGR != null
            ? "Edit Customer Scope GR"
            : "Create Customer Scope GR"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField2<Customer>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Customer',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 0),
                          ),
                          hint: const Text("Select Customer"),
                          value: selectedCustomer,
                          items: customers
                              .map((customer) => DropdownMenuItem(
                                    value: customer,
                                    child: Text(customer.name),
                                  ))
                              .toList(),
                          onChanged: (Customer? value) {
                            setState(() {
                              selectedCustomer = value;
                              // Reset job selection when customer changes
                              selectedJobs = ['All'];
                            });
                          },
                          dropdownSearchData: DropdownSearchData(
                            searchController: _customerSearchController,
                            searchInnerWidgetHeight: 56,
                            searchInnerWidget: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                controller: _customerSearchController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Search customer...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            searchMatchFn: (item, searchValue) {
                              final name = item.value?.name ?? '';
                              return name
                                  .toLowerCase()
                                  .contains(searchValue.toLowerCase());
                            },
                          ),
                          onMenuStateChange: (isOpen) {
                            if (!isOpen) {
                              _customerSearchController.clear();
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.filter_list),
                                label: Text(
                                  selectedJobs.contains('All')
                                      ? 'All Jobs'
                                      : selectedJobs.length == 1
                                          ? selectedJobs.first
                                          : '${selectedJobs.length} Jobs Selected',
                                ),
                                onPressed: () async {
                                  final result = await showDialog<List<String>>(
                                    context: context,
                                    builder: (context) => SelectJobsDialog(
                                      selectedJobs: selectedJobs,
                                      availableJobs: availableJobs.toList(),
                                    ),
                                  );

                                  if (result != null) {
                                    setState(() {
                                      selectedJobs = result;
                                      if (selectedJobs.isEmpty) {
                                        selectedJobs = ['All'];
                                      }
                                      if (selectedJobs.contains('All')) {
                                        selectedJobs = ['All'];
                                      }
                                      prQtyControllers.clear();
                                      priceControllers.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            if (!selectedJobs.contains('All') && selectedJobs.length == 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: 'Create CFI PR for ${selectedJobs.first}',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddCustomerFreeIssuePage(
                                          existingRequest: null,
                                          index: null,
                                          initialJobNo: selectedJobs.first,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _grnDateController,
                          decoration: const InputDecoration(
                            labelText: 'GR Date',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _grnDateController.text =
                                    DateFormat('yyyy-MM-dd').format(date);
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select GR date';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceDateController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Date',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _invoiceDateController.text =
                                    DateFormat('yyyy-MM-dd').format(date);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNoController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice No',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Amount',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _receivedByController,
                          decoration: const InputDecoration(
                            labelText: 'Received By',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter received by';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _checkedByController,
                          decoration: const InputDecoration(
                            labelText: 'Checked By',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter checked by';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _partNumberFilterController,
                          decoration: InputDecoration(
                            labelText: 'Filter by Part Number',
                            border: const OutlineInputBorder(),
                            suffixIcon: _partNumberFilterController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _partNumberFilterController.clear();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _descriptionFilterController,
                          decoration: InputDecoration(
                            labelText: 'Filter by Description',
                            border: const OutlineInputBorder(),
                            suffixIcon: _descriptionFilterController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _descriptionFilterController.clear();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: selectedCustomer == null
                  ? const Center(
                      child: Text('Please select a customer to continue'),
                    )
                  : materials.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'No pending materials for selected customer',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a CFI Purchase Request first',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: materials.length,
                          itemBuilder: (context, index) {
                            final material = materials[index];
                            final prs = allPurchaseRequests.where((pr) {
                              if (!selectedJobs.contains('All') &&
                                  !selectedJobs.contains(pr.jobNo ?? '')) {
                                return false;
                              }
                              return pr.items.any((item) =>
                                  item.materialCode == material.partNo);
                            }).toList();
                            return _buildItemCard(material, prs);
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveGR,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save GR'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
