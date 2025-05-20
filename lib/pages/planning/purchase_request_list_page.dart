import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/store_inward_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/purchase_order.dart';
import '../../models/store_inward.dart';
import '../../models/pr_item.dart';
import '../../models/po_item.dart';
import 'add_purchase_request_page.dart';

class PurchaseRequestListPage extends ConsumerStatefulWidget {
  const PurchaseRequestListPage({super.key});

  @override
  ConsumerState<PurchaseRequestListPage> createState() => _PurchaseRequestListPageState();
}

class _PurchaseRequestListPageState extends ConsumerState<PurchaseRequestListPage> {
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
        frozen: PlutoColumnFrozen.start,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'PR No',
        field: 'prNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'PR Date',
        field: 'prDate',
        type: PlutoColumnType.date(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
      ),
      PlutoColumn(
        title: 'PR Qty',
        field: 'prQty',
        type: PlutoColumnType.number(),
        width: 100,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Requested By',
        field: 'requestedBy',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Stock Transfer',
        field: 'stockTransfer',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        renderer: (rendererContext) {
          final transfers = rendererContext.cell.value.toString();
          if (transfers == '-') {
            return Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '-',
                style: TextStyle(color: Colors.grey[200]),
              ),
            );
          }
          return Container(
            height: PlutoGridSettings.rowHeight * 2,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: transfers.split('\n').map((transfer) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    transfer.trim(),
                    style: TextStyle(
                      color: Colors.grey[200],
                      height: 1.3,
                    ),
                  ),
                )).toList(),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'PO Details',
        field: 'poDetails',
        type: PlutoColumnType.text(),
        width: 300,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        renderer: (rendererContext) {
          final poDetails = rendererContext.cell.value.toString();
          if (poDetails == '-') {
            return Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '-',
                style: TextStyle(color: Colors.grey[200]),
              ),
            );
          }
          return Container(
            height: PlutoGridSettings.rowHeight * 2,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: poDetails.split('\n').map((po) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    po.trim(),
                    style: TextStyle(
                      color: Colors.grey[200],
                      height: 1.3,
                    ),
                  ),
                )).toList(),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Ordered Qty',
        field: 'orderedQty',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Pending Qty',
        field: 'pendingQty',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.grey[200]),
                onPressed: () {
                  // TODO: Implement view action
                },
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows(
    List<PurchaseRequest> requests,
    List<PurchaseOrder> purchaseOrders,
    List<StoreInward> storeInwards,
  ) {
    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (var request in requests) {
      for (var item in request.items) {
        // Calculate ordered quantity from POs
        final orderedQty = purchaseOrders
            .where((po) => po.items.any((poItem) => 
                poItem.materialCode == item.materialCode && 
                poItem.prQuantities.containsKey(request.prNo)))
            .fold<double>(0, (sum, po) => sum + po.items
                .where((poItem) => 
                    poItem.materialCode == item.materialCode && 
                    poItem.prQuantities.containsKey(request.prNo))
                .fold<double>(0, (sum, poItem) => sum + (poItem.prQuantities[request.prNo] ?? 0)));

        // Calculate received quantity from Store Inwards
        final receivedQty = storeInwards
            .where((si) => si.items.any((siItem) => 
                siItem.materialCode == item.materialCode && 
                siItem.poQuantities.keys.any((poNo) => 
                    purchaseOrders.any((po) => 
                        po.poNo == poNo && 
                        po.items.any((poItem) => 
                            poItem.materialCode == item.materialCode && 
                            poItem.prQuantities.containsKey(request.prNo))))))
            .fold<double>(0, (sum, si) => sum + si.items
                .where((siItem) => 
                    siItem.materialCode == item.materialCode)
                .fold<double>(0, (sum, siItem) => sum + siItem.acceptedQty));

        // Get PO details
        final relatedPOs = purchaseOrders
            .where((po) => po.items.any((poItem) => 
                poItem.materialCode == item.materialCode && 
                poItem.prQuantities.containsKey(request.prNo)))
            .map((po) => '${po.poNo}\n(${po.poDate})')
            .join('\n\n');

        // Get stock transfer details
        final transfers = storeInwards
            .where((si) => si.items.any((siItem) => 
                siItem.materialCode == item.materialCode && 
                siItem.poQuantities.keys.any((poNo) => 
                    purchaseOrders.any((po) => 
                        po.poNo == poNo && 
                        po.items.any((poItem) => 
                            poItem.materialCode == item.materialCode && 
                            poItem.prQuantities.containsKey(request.prNo))))))
            .map((si) {
              final matchingItems = si.items.where((siItem) => 
                  siItem.materialCode == item.materialCode);
              if (matchingItems.isNotEmpty) {
                return '${matchingItems.fold<double>(0, (sum, item) => sum + item.acceptedQty)} (${si.grnDate})';
              }
              return '';
            })
            .where((s) => s.isNotEmpty)
            .join('\n');

        final pendingQty = double.parse(item.quantity) - orderedQty;
        final status = pendingQty <= 0 ? 'Completed' : 
                      orderedQty > 0 ? 'Partially Ordered' : 'Pending';

        rows.add(
          PlutoRow(
            cells: {
              'serialNo': PlutoCell(value: serialNo++),
              'jobNo': PlutoCell(value: request.jobNo ?? '-'),
              'prNo': PlutoCell(value: request.prNo),
              'prDate': PlutoCell(value: request.date),
              'partNo': PlutoCell(value: item.materialCode),
              'description': PlutoCell(value: item.materialDescription),
              'prQty': PlutoCell(value: double.parse(item.quantity)),
              'unit': PlutoCell(value: item.unit),
              'requestedBy': PlutoCell(value: request.requiredBy),
              'stockTransfer': PlutoCell(value: transfers.isEmpty ? '-' : transfers),
              'poDetails': PlutoCell(value: relatedPOs.isEmpty ? '-' : relatedPOs),
              'orderedQty': PlutoCell(value: orderedQty),
              'pendingQty': PlutoCell(value: pendingQty),
              'status': PlutoCell(value: status),
              'actions': PlutoCell(value: ''),
            },
          ),
        );
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(purchaseRequestListProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    final storeInwards = ref.watch(storeInwardProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text('Purchase Requests', style: TextStyle(color: Colors.grey[200])),
        iconTheme: IconThemeData(color: Colors.grey[200]),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.grey[200]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPurchaseRequestPage(
                    existingRequest: null,
                    index: null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: PlutoGrid(
          columns: columns,
          rows: _getRows(requests, purchaseOrders, storeInwards),
          onLoaded: (PlutoGridOnLoadedEvent event) {
            stateManager = event.stateManager;
          },
          configuration: PlutoGridConfiguration(
            columnSize: const PlutoGridColumnSizeConfig(
              autoSizeMode: PlutoAutoSizeMode.scale,
            ),
            style: PlutoGridStyleConfig(
              gridBackgroundColor: Colors.grey[900]!,
              rowColor: Colors.grey[850]!,
              activatedColor: Colors.grey[800]!,
              gridBorderColor: Colors.grey[800]!,
              borderColor: Colors.grey[800]!,
              activatedBorderColor: Colors.grey[700]!,
              inactivatedBorderColor: Colors.grey[800]!,
              cellTextStyle: TextStyle(color: Colors.grey[200]!),
              columnTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              rowHeight: PlutoGridSettings.rowHeight * 2,
            ),
          ),
        ),
      ),
    );
  }
}
