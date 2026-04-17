import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/delivery_challan.dart';
import '../../services/pdf_service.dart';
import '../../models/sale_order.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/sale_order_provider.dart';

class AddJobDeliveryChallanPage extends ConsumerStatefulWidget {
  const AddJobDeliveryChallanPage({super.key});

  @override
  ConsumerState<AddJobDeliveryChallanPage> createState() =>
      _AddJobDeliveryChallanPageState();
}

class _AddJobDeliveryChallanPageState
    extends ConsumerState<AddJobDeliveryChallanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dcNoController;
  late TextEditingController _noteController;
  late String _selectedDate;
  List<DeliveryChallanItem> _items = [];

  @override
  void initState() {
    super.initState();
    _dcNoController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now().toString().split(' ')[0];
    
    // Auto-generate DC number after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(deliveryChallanListProvider.notifier);
      final nextDCNumber = notifier.generateNextDCNumber();
      setState(() {
        _dcNoController.text = nextDCNumber;
      });
    });
  }

  @override
  void dispose() {
    _dcNoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addJobItem() {
    final saleOrders = ref.read(saleOrderProvider);
    
    if (saleOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sale orders available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Job'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: saleOrders.length,
            itemBuilder: (context, index) {
              final order = saleOrders[index];
              return ListTile(
                title: Text('${order.jobNo} - ${order.customerName}'),
                subtitle: Text('Order No: ${order.orderNo}'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _items.add(
                      DeliveryChallanItem(
                        materialCode: 'JOB-${order.jobNo}',
                        materialDescription: 'Job Order: ${order.jobNo} - ${order.customerName}',
                        unit: 'JOB',
                        quantity: 1,
                        jobNo: order.jobNo,
                        price: order.finalBillValue ?? 0.0,
                      ),
                    );
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveDeliveryChallan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one job item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final notifier = ref.read(deliveryChallanListProvider.notifier);

      // For multiple jobs, use the first job as primary job order number
      String primaryJobNo = _items.first.jobNo ?? '';
      String primaryCustomerName = _items.first.materialDescription.split(' - ')[1];

      final dc = DeliveryChallan(
        dcNo: _dcNoController.text.trim(),
        dcDate: _selectedDate,
        vendorName: primaryCustomerName,
        vendorEmail: null,
        vendorGstin: null,
        items: _items,
        isReturnable: false,
        note: _noteController.text,
        dcType: 'billing',
        jobOrderNumber: primaryJobNo,
        siteAddress: 'Site Address', // You might want to add this to sale order
        expectedReturnDate: null,
        internalFlow: 'outward',
      );

      try {
        await notifier.addDeliveryChallan(dc, ref);
        if (mounted) {
          _showPDFGenerationDialog(dc);
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
            Text('Job: ${deliveryChallan.jobOrderNumber}'),
            const SizedBox(height: 16),
            const Text('Choose how to save the PDF:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSaveToDownloads(deliveryChallan);
              Navigator.pop(context);
            },
            child: const Text('Quick Save'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSavePDF(deliveryChallan);
              Navigator.pop(context);
            },
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSavePDF(DeliveryChallan deliveryChallan) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // For job delivery challan, we don't need materials or supplier
      final success = await PDFService.saveJobDeliveryChallan(deliveryChallan);

      Navigator.pop(context);

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

  Future<void> _generateAndSaveToDownloads(DeliveryChallan deliveryChallan) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await PDFService.saveJobDeliveryChallanToDownloads(deliveryChallan);

      Navigator.pop(context);

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
    final saleOrders = ref.watch(saleOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Delivery Challan'),
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
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'DC Number (Auto-generated)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.confirmation_number),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'DC number is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'DC Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
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

                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Job Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Job Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addJobItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Job Item'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.materialDescription,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Job No: ${item.jobNo}'),
                            Text('Quantity: ${item.quantity} ${item.unit}'),
                            Text(
                              'Value: ${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
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
