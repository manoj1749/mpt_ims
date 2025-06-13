// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_store_inward_page.dart';

class StoreInwardListPage extends ConsumerStatefulWidget {
  const StoreInwardListPage({super.key});

  @override
  ConsumerState<StoreInwardListPage> createState() =>
      _StoreInwardListPageState();
}

class _StoreInwardListPageState extends ConsumerState<StoreInwardListPage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = false;

  List<PlutoRow> _buildRows(List<StoreInward> inwards) {
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
          },
        );
      });
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Set loading to false after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _navigateToAddInward() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddStoreInwardPage(),
      ),
    );
    // Force a rebuild of the grid after returning from add page
    if (mounted) {
      setState(() {});
    }
  }

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 180,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.left,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'GR Date',
        field: 'grDate',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.left,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'QTY',
        field: 'qty',
        type: PlutoColumnType.number(),
        width: 100,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'UNIT',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'COST/UNIT',
        field: 'costPerUnit',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
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
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
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
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Invoice Date',
        field: 'invoiceDate',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Invoice Amount',
        field: 'invoiceAmount',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'Received By',
        field: 'receivedBy',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Checked By',
        field: 'checkedBy',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final inwards = ref.watch(storeInwardProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && stateManager != null) {
        stateManager!.removeAllRows();
        stateManager!.appendRows(_buildRows(inwards));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Inward List'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddInward,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                          rows: _buildRows(inwards),
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            stateManager = event.stateManager;
                            event.stateManager.setShowColumnFilter(true);
                          },
                          configuration: PlutoGridConfigurations.darkMode(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
