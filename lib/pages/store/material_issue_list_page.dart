// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/material_issue_provider.dart';
import '../../models/material_issue.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_material_issue_page.dart';

class MaterialIssueListPage extends ConsumerStatefulWidget {
  const MaterialIssueListPage({super.key});

  @override
  ConsumerState<MaterialIssueListPage> createState() => _MaterialIssueListPageState();
}

class _MaterialIssueListPageState extends ConsumerState<MaterialIssueListPage> {
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
                  final materialIssues = ref.read(materialIssueListProvider);
                  final index = materialIssues.indexWhere((mi) => mi.issueNo == issueNo);
                  if (index != -1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMaterialIssuePage(
                          existingIssue: materialIssues[index],
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
                      content: Text('Are you sure you want to delete Issue No: $issueNo?'),
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
                        .read(materialIssueListProvider.notifier)
                        .deleteMaterialIssue(issueNo);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Material Issue deleted successfully')),
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
    final materialIssues = ref.watch(materialIssueListProvider);
    final filteredIssues = materialIssues.where((issue) {
      if (_selectedStatus == 'All') return true;
      return issue.status == _selectedStatus;
    }).toList();

    return filteredIssues.mapIndexed((index, issue) {
      return PlutoRow(cells: {
        'serialNo': PlutoCell(value: index + 1),
        'jobNo': PlutoCell(value: issue.jobNo ?? ''),
        'issueNo': PlutoCell(value: issue.issueNo),
        'issueDate': PlutoCell(value: issue.date),
        'partNo': PlutoCell(value: issue.items.isNotEmpty ? issue.items.first.materialCode : ''),
        'description': PlutoCell(value: issue.items.isNotEmpty ? issue.items.first.materialDescription : ''),
        'issueQty': PlutoCell(value: issue.items.isNotEmpty ? issue.items.first.quantity : ''),
        'unit': PlutoCell(value: issue.items.isNotEmpty ? issue.items.first.unit : ''),
        'issuedBy': PlutoCell(value: issue.issuedBy),
        'status': PlutoCell(value: issue.status),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Issues'),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'All', child: Text('All')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMaterialIssuePage(
                    existingIssue: null,
                    index: null,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Material Issue'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: PlutoGrid(
          columns: columns,
          rows: _getRows(),
          onLoaded: (event) => stateManager = event.stateManager,
          configuration: PlutoGridConfigurations.darkMode(),
        ),
      ),
    );
  }
} 