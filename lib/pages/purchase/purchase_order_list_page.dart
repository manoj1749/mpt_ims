import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_order.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/purchase_request_provider.dart';
import 'add_purchase_order_page.dart';

class PurchaseOrderListPage extends ConsumerStatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  ConsumerState<PurchaseOrderListPage> createState() => _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends ConsumerState<PurchaseOrderListPage> {
  String _searchQuery = '';
  String _selectedStatus = 'All';
  Set<String> _expandedPOs = {};

  List<PurchaseOrder> _filterOrders(List<PurchaseOrder> orders) {
    return orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order.poNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.items.any((item) => 
              item.materialDescription.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final matchesStatus = _selectedStatus == 'All' ||
          order.status.toLowerCase() == _selectedStatus.toLowerCase();
      
      return matchesSearch && matchesStatus;
    }).toList();
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
            case 'pending':
        color = Colors.grey;
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
    final relatedPRs = ref.watch(purchaseRequestListProvider)
        .where((pr) => order.items
            .any((poItem) => pr.items
                .any((prItem) => prItem.materialCode == poItem.materialCode)))
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
                Text(
                  'Supplier: ${order.supplierName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${order.poDate}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 2).format(order.grandTotal)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[300],
                  ),
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
                  onPressed: () => _showDeleteConfirmation(context, ref, index, order),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[300],
                  ),
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
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.materialDescription,
                            style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.quantity,
                            style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.unit,
                            style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            NumberFormat.currency(
                              symbol: '₹',
                              locale: 'en_IN',
                              decimalDigits: 2,
                            ).format(double.parse(item.totalCost)),
                            style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                            textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                    ),
                  )).toList(),
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
                          'PR No: ${pr.prNo}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                        ),
                        subtitle: Text(
                          'Status: ${pr.status}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                        trailing: Text(
                          'Items: ${pr.items.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ),
                    )),
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
                    items: ['All', 'Pending', 'Partially Received', 'Completed']
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
