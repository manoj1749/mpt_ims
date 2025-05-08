import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/quality_inspection.dart';
import '../../provider/quality_inspection_provider.dart';
import 'add_quality_inspection_page.dart';
import 'category_parameter_mapping_page.dart';

class QualityInspectionListPage extends ConsumerStatefulWidget {
  const QualityInspectionListPage({super.key});

  @override
  ConsumerState<QualityInspectionListPage> createState() =>
      _QualityInspectionListPageState();
}

class _QualityInspectionListPageState
    extends ConsumerState<QualityInspectionListPage> {
  PlutoGridStateManager? stateManager;

  List<PlutoColumn> _getColumns() {
    final standardParams = QualityParameter.standardParameters;
        // Define base columns
    final baseColumns = [
      'poNo',
      'supplier',
      'partNo',
      'description',
      'qty',
      'unit',
      'costPerUnit',
      'totalCost',
      'billNo',
      'billDate',
      'receivedDate',
      'expirationDate',
      'grDate',
      'category',
      'sampleSize',
      'manufacturingDate',
      'remarks',
      'usageDecision',
      'acceptedQty',
      'rejectedQty',
      'pendingQty',
      'actions',
    ];
    final columns = [
      // Base columns
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Qty',
        field: 'qty',
        type: PlutoColumnType.number(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '0',
          );
        },
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Cost/Unit',
        field: 'costPerUnit',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;
          return Text(
            value != null ? '₹$value' : '₹0',
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
          final value = rendererContext.cell.value;
          return Text(
            value != null ? '₹$value' : '₹0',
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
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Bill Date',
        field: 'billDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Received Date',
        field: 'receivedDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Expiration Date',
        field: 'expirationDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'GR Date',
        field: 'grDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Sample Size',
        field: 'sampleSize',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '0',
          );
        },
      ),
      // Quality Parameters
      ...standardParams.map((param) {
        final fieldName = param.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        return PlutoColumn(
          title: param,
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
        title: 'Manufacturing Date/Shelf Life',
        field: 'manufacturingDate',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Remarks',
        field: 'remarks',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? 'NA',
          );
        },
      ),
      PlutoColumn(
        title: 'Usage Decision',
        field: 'usageDecision',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final item =
              rendererContext.row.cells['item']?.value as InspectionItem?;
          if (item == null) return const Text('');

          String displayText = item.usageDecision;
          if (item.usageDecision == '100% Recheck' &&
              (item.isPartialRecheck ?? false)) {
            displayText = '100% Recheck (Partial)';
          }

          Color textColor;
          switch (item.usageDecision) {
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
            displayText,
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
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '0',
          );
        },
      ),
      PlutoColumn(
        title: 'Rejected Qty',
        field: 'rejectedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '0',
          );
        },
      ),
      PlutoColumn(
        title: 'Pending Qty',
        field: 'pendingQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '0',
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
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  final inspection = rendererContext
                      .row.cells['inspection']?.value as QualityInspection?;
                  if (inspection != null) {
                    _confirmDelete(context, inspection);
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

    return columns;
  }

  List<PlutoRow> _getRows(List<QualityInspection> inspections) {
    return inspections.expand((inspection) {
      return inspection.items.map((item) {
        
        // Ensure item.parameters is initialized
        if (item.parameters.isEmpty) {
          item.parameters = QualityParameter.standardParameters.map((param) {
            return QualityParameter(
              parameter: param,
              specification: '',
              observation: 'NA',
              isAcceptable: true,
              remarks: '',
            );
          }).toList();
        }

        // Create a map for parameter cells
        final parameterCells = Map.fromEntries(
          QualityParameter.standardParameters.map((param) {
            final fieldName = param.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
            
            // Find existing parameter or create a new one
            final parameter = item.parameters.firstWhere(
              (p) => p.parameter == param,
              orElse: () => QualityParameter(
                parameter: param,
                specification: '',
                observation: 'NA',
                isAcceptable: true,
                remarks: '',
              ),
            );

            // Create a new PlutoCell with the parameter
            return MapEntry(fieldName, PlutoCell(value: parameter));
          }),
        );

        
        // Helper function to create a PlutoCell with null safety
        PlutoCell safeCell(dynamic value, {bool isNumber = false}) {
          if (value == null) return PlutoCell(value: isNumber ? 0 : 'NA');
          if (value is String && value.isEmpty) return PlutoCell(value: 'NA');
          return PlutoCell(value: value);
        }

        // Ensure all required fields have non-null values
        final cells = {
          'inspection': PlutoCell(value: inspection),
          'item': PlutoCell(value: item),
          'poNo': safeCell(inspection.poNo),
          'supplier': safeCell(inspection.supplierName),
          'partNo': safeCell(item.materialCode),
          'description': safeCell(item.materialDescription),
          'qty': safeCell(item.receivedQty, isNumber: true),
          'unit': safeCell(item.unit),
          'costPerUnit': safeCell(item.costPerUnit, isNumber: true),
          'totalCost': safeCell(item.totalCost, isNumber: true),
          'billNo': safeCell(inspection.billNo),
          'billDate': safeCell(inspection.billDate),
          'receivedDate': safeCell(item.receivedDate),
          'expirationDate': safeCell(item.expirationDate),
          'grDate': safeCell(inspection.grnDate),
          'category': safeCell(item.category),
          'sampleSize': safeCell(item.sampleSize, isNumber: true),
          'manufacturingDate': safeCell(''),
          'remarks': safeCell(item.remarks),
          'usageDecision': safeCell(item.usageDecision),
          'acceptedQty': safeCell(item.acceptedQty, isNumber: true),
          'rejectedQty': safeCell(item.rejectedQty, isNumber: true),
          'pendingQty': safeCell(item.pendingQty, isNumber: true),
          'actions': safeCell(''),
          ...parameterCells,
        };

        return PlutoRow(cells: cells);
      });
    }).toList();
  }

  void _confirmDelete(BuildContext context, QualityInspection inspection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete inspection ${inspection.inspectionNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(qualityInspectionProvider.notifier)
                    .deleteInspection(inspection);
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
    final inspections = ref.watch(qualityInspectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Inspection List'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryParameterMappingPage(),
                ),
              );
            },
            tooltip: 'Configure Quality Parameters',
          ),
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
