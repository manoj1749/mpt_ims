import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_order.dart';
import '../../provider/purchase_request_provider.dart';
import 'add_purchase_order_page.dart';

class PurchaseOrderListPage extends ConsumerStatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  ConsumerState<PurchaseOrderListPage> createState() =>
      _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends ConsumerState<PurchaseOrderListPage> {
  String _searchQuery = '';
  String _selectedStatus = 'Active';
  final Set<String> _expandedPOs = {};
  final Set<String> _fullyExpandedPOs = {};

  List<PurchaseOrder> _filterOrders(List<PurchaseOrder> orders) {
    if (_searchQuery.isEmpty) {
      return orders.where((order) => _matchesStatus(order)).toList();
    }

    final searchLower = _searchQuery.toLowerCase();
    return orders.where((order) {
      // Check if matches status filter first
      if (!_matchesStatus(order)) return false;

      // Search in PO details
      if (order.poNo.toLowerCase().contains(searchLower)) return true;
      if (order.supplierName.toLowerCase().contains(searchLower)) return true;

      // Search in items
      for (var item in order.items) {
        // Check material description
        if (item.materialDescription.toLowerCase().contains(searchLower)) return true;
        // Check material code
        if (item.materialCode.toLowerCase().contains(searchLower)) return true;

        // Check PR details for job numbers
        for (var prDetail in item.prDetails.values) {
          // Check PR number
          if (prDetail.prNo.toLowerCase().contains(searchLower)) return true;
          // Check job number if it exists
          if (prDetail.jobNo.toLowerCase().contains(searchLower)) return true;
        }
      }

      return false;
    }).toList();
  }

  bool _matchesStatus(PurchaseOrder order) {
    return _selectedStatus == 'All' ||
        (_selectedStatus == 'Active' &&
            (order.status == 'Placed' ||
                order.status == 'Partially Received')) ||
        order.status.toLowerCase() == _selectedStatus.toLowerCase();
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'partially received':
        color = Colors.orange;
        break;
      case 'placed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPOCard(PurchaseOrder order, int index) {
    final isExpanded = _expandedPOs.contains(order.poNo);
    final isFullyExpanded = _fullyExpandedPOs.contains(order.poNo);

    // Get only PRs that are actually referenced in this PO's items
    final relatedPRs = ref
        .watch(purchaseRequestListProvider)
        .where((pr) => order.items.any((poItem) =>
            poItem.prDetails.values.any((detail) => detail.prNo == pr.prNo)))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  order.poNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(order.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Supplier: ${order.supplierName} | Date: ${order.poDate} | Total: ${NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 2).format(order.grandTotal)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[300]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPurchaseOrderPage(
                          existingPO: order,
                          index: index,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey[300]),
                  onPressed: () =>
                      _showDeleteConfirmation(context, ref, index, order),
                ),
                IconButton(
                  icon: Icon(
                    !isExpanded
                        ? Icons.expand_more
                        : (isFullyExpanded
                            ? Icons.expand_less
                            : Icons.more_horiz),
                    color: Colors.grey[300],
                  ),
                  onPressed: () {
                    setState(() {
                      if (!isExpanded) {
                        _expandedPOs.add(order.poNo);
                        _fullyExpandedPOs.remove(order.poNo);
                      } else if (!isFullyExpanded) {
                        _fullyExpandedPOs.add(order.poNo);
                      } else {
                        _expandedPOs.remove(order.poNo);
                        _fullyExpandedPOs.remove(order.poNo);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[700]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isFullyExpanded) ...[
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.materialDescription,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[300]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity} ${item.unit}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        )),
                  ] else ...[
                    ...order.items.map((item) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.materialDescription,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Quantity: ${item.quantity} ${item.unit}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                    Text(
                                      'Rate: ₹${item.costPerUnit}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Cost: ₹${item.totalCost}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                  ],
                                ),
                                if (item.prDetails.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PR References:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(height: 4),
                                  ...item.prDetails.entries.map(
                                    (entry) => Text(
                                      entry.key == 'General'
                                          ? 'General Stock (${entry.value.quantity} ${item.unit})'
                                          : '${entry.value.prNo} (Job: ${entry.value.jobNo}) - ${entry.value.quantity} ${item.unit}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                    if (relatedPRs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Related Purchase Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...relatedPRs.map((pr) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.grey[800],
                            child: ListTile(
                              title: Text(
                                pr.prNo == 'General'
                                    ? 'General Stock'
                                    : 'PR No: ${pr.prNo}${pr.jobNo != null && pr.jobNo!.isNotEmpty ? ' (Job: ${pr.jobNo})' : ''}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[300]),
                              ),
                              subtitle: Text(
                                'Status: ${pr.status}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                              trailing: Text(
                                'Items: ${pr.items.length}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, int index, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Order'),
        content: Text(
          'Are you sure you want to delete purchase order ${order.poNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(purchaseOrderListProvider.notifier).deleteOrder(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase order deleted successfully'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    final filteredOrders = _filterOrders(purchaseOrders);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search POs...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor: Colors.grey[850],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.grey[850],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: Colors.grey[850],
                    style: const TextStyle(color: Colors.white),
                    items: [
                      'Active',
                      'Placed',
                      'Partially Received',
                      'Completed',
                      'All'
                    ]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No purchase orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddPurchaseOrderPage(),
                            ),
                          ),
                          child: const Text('Add New Order'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildPOCard(
                        order,
                        purchaseOrders.indexOf(order),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPurchaseOrderPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
      ),
    );
  }
}
