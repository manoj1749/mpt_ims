// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/material_issue_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_material_issue_page.dart';

class MaterialIssueListPage extends ConsumerStatefulWidget {
  const MaterialIssueListPage({super.key});

  @override
  ConsumerState<MaterialIssueListPage> createState() =>
      _MaterialIssueListPageState();
}

class _MaterialIssueListPageState extends ConsumerState<MaterialIssueListPage> {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;

  @override
  void initState() {
    super.initState();
    // Initialize columns
    columns = [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Issue No',
        field: 'issueNo',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Issue Date',
        field: 'issueDate',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job Numbers',
        field: 'jobNumbers',
        type: PlutoColumnType.text(),
        width: 200,
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
                  final materialIssues = ref.read(materialIssueProvider);
                  final issue = materialIssues
                      .firstWhereOrNull((mi) => mi.issueNo == issueNo);
                  if (issue != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMaterialIssuePage(
                          existingIssue: issue,
                          index: materialIssues.indexOf(issue),
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
                      content: const Text(
                          'Are you sure you want to delete this material issue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(materialIssueProvider.notifier)
                        .deleteMaterialIssue(issueNo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Material Issue deleted successfully')),
                    );
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
    final materialIssues = ref.watch(materialIssueProvider);
    return materialIssues.mapIndexed((index, issue) {
      return PlutoRow(cells: {
        'serialNo': PlutoCell(value: index + 1),
        'issueNo': PlutoCell(value: issue.issueNo),
        'issueDate': PlutoCell(value: issue.issueDate),
        'jobNumbers': PlutoCell(value: issue.formattedJobNo),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to trigger rebuilds
    ref.watch(materialIssueProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (stateManager != null) {
                // Force a refresh of the provider
                ref.invalidate(materialIssueProvider);
                stateManager!.removeAllRows();
                stateManager!.appendRows(_getRows());

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Material Issues refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
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
