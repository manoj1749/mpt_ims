// Service Bills PO Page - Separate from material POs
// Only reflects in invoices, no correlation with Quality, Stock, etc.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_order.dart';
import '../../provider/supplier_provider.dart';
import '../../services/pdf_service.dart';
import 'add_service_bill_po_page.dart';

class ServiceBillsPOPage extends ConsumerStatefulWidget {
  const ServiceBillsPOPage({super.key});

  @override
  ConsumerState<ServiceBillsPOPage> createState() => _ServiceBillsPOPageState();
}

class _ServiceBillsPOPageState extends ConsumerState<ServiceBillsPOPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedPOs = {};

  List<PurchaseOrder> _filterServiceBills(List<PurchaseOrder> orders) {
    return orders.where((order) {
      // Only show service bills
      if (!order.isServiceBill) return false;
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesPONo = order.poNo.toLowerCase().contains(query);
        final matchesSupplier = order.supplierName.toLowerCase().contains(query);
        final matchesDate = order.poDate.contains(query);
        
        return matchesPONo || matchesSupplier || matchesDate;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(purchaseOrderListProvider);
    final serviceBills = _filterServiceBills(allOrders);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          // Header with Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Bills PO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[200],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddServiceBillPOPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service Bill PO'),
                ),
              ],
            ),
          ),
          
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by PO Number, Supplier, or Date',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Service Bills List
          Expanded(
            child: serviceBills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No Service Bills PO found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a service bill PO to get started',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: serviceBills.length,
                    itemBuilder: (context, index) {
                      final order = serviceBills[index];
                      return _buildServiceBillCard(order, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBillCard(PurchaseOrder order, int index) {
    final isExpanded = _expandedPOs.contains(order.poNo);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[850],
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            dense: true,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  order.poNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    border: Border.all(color: Colors.purple.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Service Bill',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supplier: ${order.supplierName}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  NumberFormat.currency(
                    symbol: '₹',
                    locale: 'en_IN',
                    decimalDigits: 2,
                  ).format(order.grandTotal),
                  style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                ),
              ],
            ),
            subtitle: Text(
              'Date: ${order.poDate}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[300]),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Edit Service Bill PO',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddServiceBillPOPage(
                          existingPO: order,
                          index: index,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.grey[300]),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showPDFOptions(order),
                  tooltip: 'Generate PDF',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey[300]),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showDeleteConfirmation(context, ref, index, order),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[300],
                  ),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedPOs.remove(order.poNo);
                      } else {
                        _expandedPOs.add(order.poNo);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 0, thickness: 1, color: Colors.grey[700]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.materialDescription,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Quantity: ${item.quantity} ${item.unit}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                                  ),
                                  Text(
                                    'Rate: ₹${item.costPerUnit}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                                  ),
                                  Text(
                                    'Total: ₹${item.totalCost}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Subtotal: ₹${order.total.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                          ),
                          if (order.igst > 0)
                            Text(
                              'IGST: ₹${order.igst.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                            ),
                          if (order.cgst > 0)
                            Text(
                              'CGST: ₹${order.cgst.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                            ),
                          if (order.sgst > 0)
                            Text(
                              'SGST: ₹${order.sgst.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                            ),
                          const Divider(),
                          Text(
                            'Grand Total: ₹${order.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPDFOptions(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Generate PDF', style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Choose where to save the PDF:',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAndSavePDF(order);
            },
            child: Text('App Folder', style: TextStyle(color: Colors.grey[200])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAndSaveToDownloads(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Downloads'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSavePDF(PurchaseOrder purchaseOrder) async {
    try {
      final supplier = ref.read(supplierListProvider).firstWhere(
            (s) => s.name == purchaseOrder.supplierName,
          );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await PDFService.savePurchaseOrder(purchaseOrder, supplier);

      Navigator.pop(context); // Close loading dialog

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndSaveToDownloads(PurchaseOrder purchaseOrder) async {
    try {
      final supplier = ref.read(supplierListProvider).firstWhere(
            (s) => s.name == purchaseOrder.supplierName,
          );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await PDFService.savePurchaseOrderToDownloads(purchaseOrder, supplier);

      Navigator.pop(context); // Close loading dialog

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved to Downloads folder'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, int index, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Delete Service Bill PO', style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Are you sure you want to delete ${order.poNo}?',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(purchaseOrderListProvider.notifier).deleteOrder(order);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service Bill PO deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
