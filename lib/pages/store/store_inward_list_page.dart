import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../provider/store_inward_provider.dart';
import '../../models/store_inward.dart';
import 'add_store_inward_page.dart';

class StoreInwardListPage extends ConsumerStatefulWidget {
  const StoreInwardListPage({super.key});

  @override
  ConsumerState<StoreInwardListPage> createState() =>
      _StoreInwardListPageState();
}

class _StoreInwardListPageState extends ConsumerState<StoreInwardListPage> {
  late PlutoGridStateManager stateManager;

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'GR Date',
        field: 'grDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'QTY',
        field: 'qty',
        type: PlutoColumnType.number(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'UNIT',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'COST/UNIT',
        field: 'costPerUnit',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'TOTAL COST',
        field: 'totalCost',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'Invoice No',
        field: 'invoiceNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Invoice Date',
        field: 'invoiceDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Invoice Amount',
        field: 'invoiceAmount',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Received By',
        field: 'receivedBy',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Checked By',
        field: 'checkedBy',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
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
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  final inward =
                      rendererContext.row.cells['inward']!.value as StoreInward;
                  _confirmDelete(context, inward);
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

  List<PlutoRow> _getRows(List<StoreInward> inwards) {
    return inwards.expand((inward) {
      return inward.items.map((item) {
        final costPerUnit = double.tryParse(item.costPerUnit) ?? 0;
        final totalCost = costPerUnit * item.receivedQty;

        return PlutoRow(
          cells: {
            'grnNo': PlutoCell(value: inward.grnNo),
            'poNo': PlutoCell(value: inward.poNo),
            'supplier': PlutoCell(value: inward.supplierName),
            'grDate': PlutoCell(value: inward.grnDate),
            'partNo': PlutoCell(value: item.materialCode),
            'description': PlutoCell(value: item.materialDescription),
            'qty': PlutoCell(value: item.receivedQty),
            'unit': PlutoCell(value: item.unit),
            'costPerUnit': PlutoCell(value: costPerUnit),
            'totalCost': PlutoCell(value: totalCost),
            'invoiceNo': PlutoCell(value: inward.invoiceNo),
            'invoiceDate': PlutoCell(value: inward.invoiceDate),
            'invoiceAmount': PlutoCell(value: inward.invoiceAmount),
            'receivedBy': PlutoCell(value: inward.receivedBy),
            'checkedBy': PlutoCell(value: inward.checkedBy),
            'actions': PlutoCell(value: ''),
            'inward': PlutoCell(value: inward), // Hidden cell for reference
          },
        );
      });
    }).toList();
  }

  void _confirmDelete(BuildContext context, StoreInward inward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete store inward for PO ${inward.poNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref.read(storeInwardProvider.notifier).deleteInward(inward);
                Navigator.of(context).pop();
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
    final inwards = ref.watch(storeInwardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Inward List'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddStoreInwardPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Column(
            children: [
              if (inwards.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No store inwards found.\nClick the + button to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: PlutoGrid(
                    columns: _getColumns(),
                    rows: _getRows(inwards),
                    onLoaded: (PlutoGridOnLoadedEvent event) {
                      stateManager = event.stateManager;
                      event.stateManager.setShowColumnFilter(true);
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
                        cellTextStyle: const TextStyle(color: Colors.white),
                        columnTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        rowHeight: 45,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
