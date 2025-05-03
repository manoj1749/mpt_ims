import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/quality_inspection.dart';
import '../../provider/quality_inspection_provider.dart';
import 'add_quality_inspection_page.dart';

class QualityInspectionListPage extends ConsumerStatefulWidget {
  const QualityInspectionListPage({super.key});

  @override
  ConsumerState<QualityInspectionListPage> createState() => _QualityInspectionListPageState();
}

class _QualityInspectionListPageState extends ConsumerState<QualityInspectionListPage> {
  late PlutoGridStateManager stateManager;

  List<PlutoColumn> _getColumns() {
    return [
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
        title: 'Qty',
        field: 'qty',
        type: PlutoColumnType.number(),
        width: 100,
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
          return Text(
            '₹${rendererContext.cell.value}',
            style: const TextStyle(fontFamily: 'monospace'),
          );
        },
      ),
      PlutoColumn(
        title: 'Total Cost',
        field: 'totalCost',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            '₹${rendererContext.cell.value}',
            style: const TextStyle(fontFamily: 'monospace'),
          );
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
      // Quality Parameters
      ...QualityParameter.standardParameters.map((param) => PlutoColumn(
        title: param,
        field: param.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final parameter = rendererContext.cell.value as QualityParameter;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  parameter.observation.isEmpty ? 'Not Checked' : parameter.observation,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: parameter.isAcceptable ? Colors.green : Colors.red,
                ),
              ),
            ],
          );
        },
      )),
      PlutoColumn(
        title: 'Manufacturing Date/Shelf Life',
        field: 'manufacturingDate',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Remarks',
        field: 'remarks',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Usage Decision',
        field: 'usageDecision',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          Color textColor;
          switch (rendererContext.cell.value) {
            case 'Lot Accepted':
              textColor = Colors.green;
              break;
            case 'Rejected':
              textColor = Colors.red;
              break;
            case '100% Recheck':
              textColor = Colors.orange;
              break;
            default:
              textColor = Colors.grey;
          }
          return Text(
            rendererContext.cell.value.toString(),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          );
        },
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
                  final inspection = rendererContext.row.cells['inspection']!.value as QualityInspection;
                  _confirmDelete(context, inspection);
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
    return inspections.expand((inspection) {
      return inspection.items.map((item) {
        // Create a map for parameter cells
        final parameterCells = Map.fromEntries(
          QualityParameter.standardParameters.map((param) {
            final fieldName = param.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
            final parameter = item.parameters.firstWhere(
              (p) => p.parameter == param,
              orElse: () => QualityParameter(
                parameter: param,
                specification: '',
                observation: '',
                isAcceptable: false,
                remarks: '',
              ),
            );
            return MapEntry(fieldName, PlutoCell(value: parameter));
          }),
        );

        return PlutoRow(
          cells: {
            'poNo': PlutoCell(value: inspection.poNo),
            'supplier': PlutoCell(value: inspection.supplierName),
            'partNo': PlutoCell(value: item.materialCode),
            'description': PlutoCell(value: item.materialDescription),
            'qty': PlutoCell(value: item.receivedQty),
            'unit': PlutoCell(value: item.unit),
            'costPerUnit': PlutoCell(value: item.costPerUnit),
            'totalCost': PlutoCell(value: item.totalCost),
            'billNo': PlutoCell(value: inspection.billNo),
            'billDate': PlutoCell(value: inspection.billDate),
            'receivedDate': PlutoCell(value: inspection.receivedDate),
            'grDate': PlutoCell(value: inspection.grnDate),
            'category': PlutoCell(value: item.category),
            'sampleSize': PlutoCell(value: item.sampleSize),
            'manufacturingDate': PlutoCell(value: item.manufacturingDate),
            'remarks': PlutoCell(value: item.remarks),
            'usageDecision': PlutoCell(value: item.usageDecision),
            'acceptedQty': PlutoCell(value: item.acceptedQty),
            'rejectedQty': PlutoCell(value: item.rejectedQty),
            'pendingQty': PlutoCell(value: item.pendingQty),
            'actions': PlutoCell(value: ''),
            'item': PlutoCell(value: item),
            ...parameterCells,
          },
        );
      });
    }).toList();
  }

  void _confirmDelete(BuildContext context, QualityInspection inspection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete inspection ${inspection.inspectionNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref.read(qualityInspectionProvider.notifier).deleteInspection(inspection);
                Navigator.of(context).pop();
              },
              child: const Text('DELETE'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[400],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspections = ref.watch(qualityInspectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Inspection List'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Inspections',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddQualityInspectionPage(),
            ),
          );
        },
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddQualityInspectionPage(),
                      ),
                    ),
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
                  Row(
                    children: [
                      Text(
                        '${inspections.length} Inspections',
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
                          rows: _getRows(inspections),
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            stateManager = event.stateManager;
                            event.stateManager.setShowColumnFilter(true);
                          },
                          configuration: PlutoGridConfiguration(
                            columnFilter: PlutoGridColumnFilterConfig(
                              filters: const [
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 