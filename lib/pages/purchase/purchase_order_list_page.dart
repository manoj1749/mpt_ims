import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_order.dart';
import '../../provider/store_inward_provider.dart';
import 'add_purchase_order_page.dart';

class PurchaseOrderListPage extends ConsumerStatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  ConsumerState<PurchaseOrderListPage> createState() =>
      _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends ConsumerState<PurchaseOrderListPage> {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;

  @override
  void initState() {
    super.initState();
    columns = [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 60,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO Date',
        field: 'poDate',
        type: PlutoColumnType.date(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Items',
        field: 'items',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final items = rendererContext.cell.value.toString();
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .split('\n')
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            item.trim(),
                    style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Qty',
        field: 'quantity',
        type: PlutoColumnType.number(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final status = rendererContext.cell.value.toString();
          Color textColor;
          switch (status.toLowerCase()) {
            case 'completed':
              textColor = Colors.green[300]!;
              break;
            case 'partially received':
              textColor = Colors.orange[300]!;
              break;
            case 'pending':
              textColor = Colors.grey[400]!;
              break;
            default:
              textColor = Colors.grey[200]!;
          }
          return Center(
            child: Text(
              status,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Transport',
        field: 'transport',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Delivery Requirements',
        field: 'deliveryRequirements',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total',
        field: 'total',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        formatter: (value) => NumberFormat.currency(
          symbol: '₹',
          locale: 'en_IN',
          decimalDigits: 2,
        ).format(value),
      ),
      PlutoColumn(
        title: 'Grand Total',
        field: 'grandTotal',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        formatter: (value) => NumberFormat.currency(
                                  symbol: '₹',
                                  locale: 'en_IN',
                                  decimalDigits: 2,
        ).format(value),
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 140,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final index = rendererContext.row.cells['index']?.value as int;
          final orders = ref.read(purchaseOrderListProvider);

          if (index >= orders.length) {
            return const SizedBox.shrink();
          }

          final order = orders[index];

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
                              children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.edit, color: Colors.grey[200], size: 20),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                        builder: (context) => AddPurchaseOrderPage(
                                                          existingPO: order,
                          index: index,
                        ),
                      ),
                    ).then((_) {
                      // Refresh the grid after returning from edit page
                      if (stateManager != null) {
                        final orders = ref.read(purchaseOrderListProvider);
                        stateManager!.removeAllRows();
                        stateManager!.appendRows(_getRows(orders));
                      }
                    });
                  },
                ),
                                          ),
                                          const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.delete, color: Colors.grey[200], size: 20),
                                            onPressed: () {
                    _showDeleteConfirmation(context, ref, index, order);
                                            },
                                  ),
                                ),
                              ],
                          );
                        },
                      ),
    ];
  }

  List<PlutoRow> _getRows(List<PurchaseOrder> orders) {
    final rows = <PlutoRow>[];
    var serialNo = 1;
    final storeInwards = ref.read(storeInwardProvider);

    for (var i = 0; i < orders.length; i++) {
      final order = orders[i];

      // For each item in the order, create a separate row
      for (var item in order.items) {
        // Calculate received quantity from Store Inwards for this specific item in this PO
        double itemReceivedQty = 0;
        for (var si in storeInwards) {
          for (var siItem in si.items) {
            if (siItem.poQuantities.containsKey(order.poNo) && 
                siItem.materialCode == item.materialCode) {
              itemReceivedQty += siItem.acceptedQty;
            }
          }
        }

        // Determine status based on received quantity for this specific item
        String status;
        if (itemReceivedQty >= double.parse(item.quantity)) {
          status = 'Completed';
        } else if (itemReceivedQty > 0) {
          status = 'Partially Received';
        } else {
          status = 'Pending';
        }

        rows.add(
          PlutoRow(
            cells: {
              'serialNo': PlutoCell(value: serialNo++),
              'poNo': PlutoCell(value: order.poNo),
              'poDate': PlutoCell(value: order.poDate),
              'jobNo': PlutoCell(value: item.formattedJobNumbers),
              'supplier': PlutoCell(value: order.supplierName),
              'items': PlutoCell(value: '${item.materialDescription} (${item.materialCode})'),
              'quantity': PlutoCell(value: double.parse(item.quantity)),
              'unit': PlutoCell(value: item.unit),
              'status': PlutoCell(value: status),
              'transport': PlutoCell(value: order.transport ?? ''),
              'deliveryRequirements': PlutoCell(value: order.deliveryRequirements ?? ''),
              'total': PlutoCell(value: double.parse(item.totalCost)),
              'grandTotal': PlutoCell(value: order.grandTotal),
              'actions': PlutoCell(value: ''),
              'index': PlutoCell(value: i),
            },
          ),
        );
      }
    }

    return rows;
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, int index, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Delete Purchase Order',
            style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Are you sure you want to delete purchase order ${order.poNo}?',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          TextButton(
            onPressed: () {
              ref.read(purchaseOrderListProvider.notifier).deleteOrder(index);
              Navigator.pop(context);

              // Refresh grid rows
              if (stateManager != null) {
                final orders = ref.read(purchaseOrderListProvider);
                stateManager!.removeAllRows();
                stateManager!.appendRows(_getRows(orders));
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Purchase order deleted successfully'),
                  backgroundColor: Colors.grey[850],
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrders = ref.watch(purchaseOrderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPurchaseOrderPage()),
          );
          // Refresh the grid after returning from add/edit page
          if (stateManager != null) {
            final orders = ref.read(purchaseOrderListProvider);
            stateManager!.removeAllRows();
            stateManager!.appendRows(_getRows(orders));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: purchaseOrders.isEmpty
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
                    'No purchase orders yet',
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
                          builder: (_) => const AddPurchaseOrderPage()),
                    ),
                    child: const Text('Add New Order'),
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
                        '${purchaseOrders.length} Purchase Orders',
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
                    child: PlutoGrid(
                      columns: columns,
                      rows: _getRows(purchaseOrders),
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                        stateManager?.setShowColumnFilter(true);
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
                          cellTextStyle: TextStyle(
                            color: Colors.grey[200]!,
                            fontSize: 13,
                          ),
                          columnTextStyle: TextStyle(
                            color: Colors.grey[200]!,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          rowHeight: 45,
                        ),
                        columnSize: const PlutoGridColumnSizeConfig(
                          autoSizeMode: PlutoAutoSizeMode.none,
                          resizeMode: PlutoResizeMode.normal,
                        ),
                        scrollbar: const PlutoGridScrollbarConfig(
                          isAlwaysShown: true,
                          scrollbarThickness: 8,
                          hoverWidth: 20,
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
