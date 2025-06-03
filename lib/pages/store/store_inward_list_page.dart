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
            'actions': PlutoCell(value: ''),
            'inward': PlutoCell(value: inward),
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

  Future<void> _confirmDelete(BuildContext context, StoreInward inward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete store inward for PO ${inward.poNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[400],
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ref.read(storeInwardProvider.notifier).deleteInward(inward);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store inward deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting store inward: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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
