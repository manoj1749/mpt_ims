import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/sale_order.dart';
import '../../provider/sale_order_provider.dart';
import 'add_edit_sale_order_page.dart';

class SaleOrderListPage extends ConsumerStatefulWidget {
  const SaleOrderListPage({super.key});

  @override
  ConsumerState<SaleOrderListPage> createState() => _SaleOrderListPageState();
}

class _SaleOrderListPageState extends ConsumerState<SaleOrderListPage> {
  PlutoGridStateManager? stateManager;

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: 'Order No',
        field: 'orderNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'orderDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Customer',
        field: 'customerName',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'boardNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Start Date',
        field: 'jobStartDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Target Date',
        field: 'targetDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'End Date',
        field: 'endDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final endDate = rendererContext.cell.value?.toString() ?? '';
          return Text(
            endDate,
            style: TextStyle(
              color: endDate.isEmpty ? Colors.grey : Colors.green,
              fontWeight: endDate.isEmpty ? FontWeight.normal : FontWeight.bold,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  final order =
                      rendererContext.row.cells['order']?.value as SaleOrder?;
                  if (order != null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditSaleOrderPage(order: order),
                      ),
                    );
                    if (result == true) {
                      // Force refresh the state
                      ref.invalidate(saleOrderProvider);
                    }
                  }
                },
                color: Colors.blue[400],
                tooltip: 'Edit',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  final order =
                      rendererContext.row.cells['order']?.value as SaleOrder?;
                  if (order != null) {
                    _confirmDelete(context, order);
                  }
                },
                color: Colors.red[400],
                tooltip: 'Delete',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows(List<SaleOrder> orders) {
    return orders.map((order) {
      return PlutoRow(cells: {
        'order': PlutoCell(value: order),
        'orderNo': PlutoCell(value: order.orderNo),
        'orderDate': PlutoCell(value: order.orderDate),
        'customerName': PlutoCell(value: order.customerName),
        'boardNo': PlutoCell(value: order.boardNo),
        'jobStartDate': PlutoCell(value: order.jobStartDate),
        'targetDate': PlutoCell(value: order.targetDate),
        'endDate': PlutoCell(value: order.endDate ?? ''),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  void _confirmDelete(BuildContext context, SaleOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete sale order ${order.orderNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref.read(saleOrderProvider.notifier).deleteOrder(order);
                Navigator.of(context).pop();
                // Force refresh the state
                ref.invalidate(saleOrderProvider);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[400],
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(saleOrderProvider);

    if (stateManager != null) {
      final rows = _getRows(orders);
      stateManager!.removeAllRows();
      stateManager!.appendRows(rows);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Orders'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Orders',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditSaleOrderPage(),
            ),
          );
          if (result == true) {
            // Force refresh the state
            ref.invalidate(saleOrderProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: orders.isEmpty
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
                    'No sale orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditSaleOrderPage(),
                        ),
                      );
                      if (result == true) {
                        // Force refresh the state
                        ref.invalidate(saleOrderProvider);
                      }
                    },
                    child: const Text('Create New Order'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${orders.length} Orders',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonal(
                        onPressed: () {
                          // TODO: Implement filtering
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 20),
                            SizedBox(width: 8),
                            Text('Filter'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: PlutoGrid(
                          columns: _getColumns(),
                          rows: _getRows(orders),
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            setState(() {
                              stateManager = event.stateManager;
                              stateManager?.setShowColumnFilter(true);
                            });
                          },
                          configuration: PlutoGridConfiguration(
                            columnFilter: const PlutoGridColumnFilterConfig(
                              filters: [
                                ...FilterHelper.defaultFilters,
                              ],
                            ),
                            style: PlutoGridStyleConfig(
                              gridBorderColor: Colors.grey[700]!,
                              gridBackgroundColor: Colors.grey[900]!,
                              borderColor: Colors.grey[700]!,
                              iconColor: Colors.grey[300]!,
                              rowColor: Colors.grey[850]!,
                              oddRowColor: Colors.grey[800]!,
                              evenRowColor: Colors.grey[850]!,
                              activatedColor: Colors.blue[900]!,
                              cellTextStyle:
                                  const TextStyle(color: Colors.white),
                              columnTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              rowHeight: 45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
