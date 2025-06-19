// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/provider/material_request_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/material_issue_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_material_request_page.dart';

class MaterialRequestListPage extends ConsumerStatefulWidget {
  const MaterialRequestListPage({super.key});

  @override
  ConsumerState<MaterialRequestListPage> createState() =>
      _MaterialRequestListPageState();
}

class _MaterialRequestListPageState
    extends ConsumerState<MaterialRequestListPage> {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;
  String _selectedStatus = 'Active'; // Default to Active view

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
        title: 'Issue No',
        field: 'issueNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Issue Date',
        field: 'issueDate',
        type: PlutoColumnType.date(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Issue Qty',
        field: 'issueQty',
        type: PlutoColumnType.number(),
        width: 100,
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
        title: 'Issued By',
        field: 'issuedBy',
        type: PlutoColumnType.text(),
        width: 120,
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
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final rowData = rendererContext.row.cells;
                  final issueNo = rowData['issueNo']?.value as String;
                  final MaterialRequests =
                      ref.read(MaterialRequestListProvider);
                  final index = MaterialRequests.indexWhere(
                      (mi) => mi.issueNo == issueNo);
                  if (index != -1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMaterialRequestPage(
                          existingIssue: MaterialRequests[index],
                          index: index,
                        ),
                      ),
                    );
                  }
                },
                color: Colors.blue,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final rowData = rendererContext.row.cells;
                  final issueNo = rowData['issueNo']?.value as String;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                          'Are you sure you want to delete Issue No: $issueNo?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(MaterialRequestListProvider.notifier)
                        .deleteMaterialRequest(issueNo);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Material Request deleted successfully')),
                      );
                    }
                  }
                },
                color: Colors.red,
                iconSize: 20,
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows() {
    final MaterialRequests = ref.watch(MaterialRequestListProvider);
    final filteredIssues = MaterialRequests.where((issue) {
      if (_selectedStatus == 'All') return true;
      return issue.status == _selectedStatus;
    }).toList();

    return filteredIssues.mapIndexed((index, issue) {
      return PlutoRow(cells: {
        'serialNo': PlutoCell(value: index + 1),
        'jobNo': PlutoCell(value: issue.jobNo ?? ''),
        'issueNo': PlutoCell(value: issue.issueNo),
        'issueDate': PlutoCell(value: issue.date),
        'partNo': PlutoCell(
            value:
                issue.items.isNotEmpty ? issue.items.first.materialCode : ''),
        'description': PlutoCell(
            value: issue.items.isNotEmpty
                ? issue.items.first.materialDescription
                : ''),
        'issueQty': PlutoCell(
            value: issue.items.isNotEmpty ? issue.items.first.quantity : ''),
        'unit': PlutoCell(
            value: issue.items.isNotEmpty ? issue.items.first.unit : ''),
        'issuedBy': PlutoCell(value: issue.issuedBy),
        'status': PlutoCell(value: issue.status),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(materialRequestProvider);
    ref.watch(materialIssueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Requests'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedStatus,
              dropdownColor: Colors.grey[850],
              style: TextStyle(color: Colors.grey[200]),
              icon: Icon(Icons.filter_list, color: Colors.grey[200]),
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: 'Active',
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                  if (stateManager != null) {
                    ref.read(materialRequestProvider);
                    ref.read(materialIssueProvider);
                    stateManager!.removeAllRows();
                    stateManager!.appendRows(_getRows());
                  }
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (stateManager != null) {
                ref.read(materialRequestProvider);
                ref.read(materialIssueProvider);
                stateManager!.removeAllRows();
                stateManager!.appendRows(_getRows());
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Material Requests refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMaterialRequestPage(
                    existingIssue: null,
                    index: null,
                  ),
                ),
              );
            },
            child: const Text('New Material Request'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: PlutoGrid(
          columns: columns,
          rows: _getRows(),
          onLoaded: (PlutoGridOnLoadedEvent event) {
            stateManager = event.stateManager;
          },
          configuration: PlutoGridConfigurations.darkMode(),
        ),
      ),
    );
  }

}
