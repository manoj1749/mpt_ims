import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/quality_inspection.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import 'add_quality_inspection_page.dart';

class QualityInspectionListPage extends ConsumerStatefulWidget {
  const QualityInspectionListPage({super.key});

  @override
  ConsumerState<QualityInspectionListPage> createState() =>
      _QualityInspectionListPageState();
}

class _QualityInspectionListPageState
    extends ConsumerState<QualityInspectionListPage> {
  PlutoGridStateManager? stateManager;
  String _searchQuery = '';
  bool _showFilters = false;
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  void _navigateToAddInspection(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddQualityInspectionPage(),
      ),
    );
    if (stateManager != null) {
      final inspections = ref.read(qualityInspectionProvider);
      stateManager!.removeAllRows();
      stateManager!.appendRows(_getRows(inspections));
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final headers = _getColumns()
          .where((col) => col.field != 'actions')
          .map((col) => col.title)
          .toList();
      
      final rows = _getRows(ref.read(qualityInspectionProvider));
      final csvData = [headers];

      for (var row in rows) {
        final rowData = <String>[];
        row.cells.forEach((key, cell) {
          if (key != 'actions' && key != 'inspection') {
            rowData.add(cell.value.toString());
          }
        });
        csvData.add(rowData);
      }

      final csvString = ListToCsvConverter().convert(csvData);
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'quality_inspections_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.csv';
      final filePath = '${directory.path}/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully to $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSummaryCards(List<QualityInspection> inspections) {
    int totalInspections = inspections.length;
    int pendingInspections = inspections
        .where((inspection) => inspection.status == 'Pending')
        .length;
    int completedInspections = totalInspections - pendingInspections;

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Inspections',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalInspections.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Inspections',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pendingInspections.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: pendingInspections > 0 ? Colors.orange : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completed Inspections',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completedInspections.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: completedInspections > 0 ? Colors.green : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search inspections...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _showFilters ? Icons.filter_list_off : Icons.filter_list,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Filters'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                ),
              ],
            ),
            if (_showFilters) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                            value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'Completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PlutoColumn> _getColumns() {
    final universalParams = ref.watch(universalParameterProvider);

    return [
      PlutoColumn(
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 120,
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
        title: 'PR No',
        field: 'prNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
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
        title: 'Received Qty',
        field: 'receivedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Accepted Qty',
        field: 'acceptedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rejected Qty',
        field: 'rejectedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Pending Qty',
        field: 'pendingQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Usage Decision',
        field: 'usageDecision',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Cost/Unit',
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
        title: 'Total Cost',
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
        title: 'Bill No',
        field: 'billNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Bill Date',
        field: 'billDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Received Date',
        field: 'receivedDate',
        type: PlutoColumnType.text(),
        width: 120,
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
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sample Size',
        field: 'sampleSize',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      ...universalParams.map((param) {
        final fieldName =
            param.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        return PlutoColumn(
          title: param.name,
          field: fieldName,
          type: PlutoColumnType.text(),
          width: 120,
          enableEditingMode: false,
          renderer: (rendererContext) {
            final value = rendererContext.cell.value;
            if (value == null) {
              return const Text('NA');
            }

            if (value is! QualityParameter) {
              return Text(value.toString());
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value.observation.isEmpty ? 'NA' : value.observation,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value.isAcceptable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            );
          },
        );
      }),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final inspection = rendererContext.row.cells['inspection']!.value
              as QualityInspection;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  _showDeleteConfirmation(context, ref, inspection);
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

  List<PlutoRow> _getRows(List<QualityInspection> inspections) {
    final rows = <PlutoRow>[];

    for (var inspection in inspections) {
      for (var item in inspection.items) {
        final pendingQty = item.getPendingQuantityForGRN(inspection.grnNo);

        // Create a map of all required cells with proper null handling
        final cells = {
          'grnNo': PlutoCell(value: inspection.grnNo),
          'poNo': PlutoCell(value: inspection.poNo),
          'prNo':
              PlutoCell(value: inspection.prNumbers[inspection.poNo] ?? '-'),
          'jobNo':
              PlutoCell(value: inspection.jobNumbers[inspection.poNo] ?? '-'),
          'supplier': PlutoCell(value: inspection.supplierName),
          'partNo': PlutoCell(value: item.materialCode),
          'description': PlutoCell(value: item.materialDescription),
          'receivedQty': PlutoCell(value: item.receivedQty),
          'acceptedQty': PlutoCell(value: item.acceptedQty),
          'rejectedQty': PlutoCell(value: item.rejectedQty),
          'pendingQty': PlutoCell(value: pendingQty),
          'usageDecision': PlutoCell(value: item.usageDecision),
          'unit': PlutoCell(value: item.unit),
          'costPerUnit': PlutoCell(value: item.costPerUnit),
          'totalCost': PlutoCell(value: item.totalCost),
          'billNo': PlutoCell(value: inspection.billNo),
          'billDate': PlutoCell(value: inspection.billDate),
          'receivedDate': PlutoCell(value: inspection.receivedDate),
          'grDate': PlutoCell(value: inspection.grnDate),
          'category': PlutoCell(value: item.category),
          'sampleSize': PlutoCell(value: item.sampleSize),
          'actions': PlutoCell(value: ''),
          'inspection': PlutoCell(value: inspection),
        };

        // Add parameter cells
        for (var param in item.parameters) {
          final fieldName = param.parameter
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '_');
          cells[fieldName] = PlutoCell(value: param);
        }

        rows.add(PlutoRow(cells: cells));
      }
    }

    return rows;
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    QualityInspection inspection,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inspection'),
        content: Text(
          'Are you sure you want to delete inspection ${inspection.inspectionNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete only this specific inspection
              ref
                  .read(qualityInspectionProvider.notifier)
                  .deleteInspection(inspection);
              Navigator.pop(context);

              // Refresh grid rows
              if (stateManager != null) {
                final inspections = ref.read(qualityInspectionProvider);
                stateManager!.removeAllRows();
                stateManager!.appendRows(_getRows(inspections));
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspection deleted successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspections = ref.watch(qualityInspectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Inspection List'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddInspection(context),
        child: const Icon(Icons.add),
      ),
      body: inspections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quality inspections yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _navigateToAddInspection(context),
                    child: const Text('Add New Inspection'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(inspections),
                  const SizedBox(height: 16),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: PlutoGrid(
                          columns: _getColumns(),
                          rows: _getRows(inspections),
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
