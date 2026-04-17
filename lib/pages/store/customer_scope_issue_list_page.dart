// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/material_issue_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_material_issue_page.dart';

class CustomerScopeIssueListPage extends ConsumerStatefulWidget {
  const CustomerScopeIssueListPage({super.key});

  @override
  ConsumerState<CustomerScopeIssueListPage> createState() =>
      _CustomerScopeIssueListPageState();
}

class _CustomerScopeIssueListPageState extends ConsumerState<CustomerScopeIssueListPage> {
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
        title: 'Material Requests',
        field: 'mrNumbers',
        type: PlutoColumnType.text(),
        width: 200,
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
        title: 'Issue Qty',
        field: 'issueQty',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Materials',
        field: 'materials',
        type: PlutoColumnType.text(),
        width: 300,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.left,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final issue = ref.read(materialIssueProvider).firstWhereOrNull(
                (mi) =>
                    mi.issueNo == rendererContext.row.cells['issueNo']!.value,
              );

          if (issue == null) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: issue.items.map((item) {
                  return Text(
                    '${item.materialCode} - ${item.materialDescription} (${item.quantity} ${item.unit})',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList(),
              ),
            ),
          );
        },
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
      // Get unique MR numbers
      final mrNumbers =
          issue.items.expand((item) => item.mrDetails.keys).toSet().join(', ');

      // Get formatted job numbers from the issue
      final jobNumbers = issue.formattedJobNo;

      // Calculate total issue quantity
      final totalIssueQty = issue.items.fold<double>(0.0, (sum, item) => sum + item.quantity);

      return PlutoRow(cells: {
        'serialNo': PlutoCell(value: index + 1),
        'issueNo': PlutoCell(value: issue.issueNo),
        'issueDate': PlutoCell(value: issue.issueDate),
        'mrNumbers': PlutoCell(value: mrNumbers),
        'jobNumbers': PlutoCell(value: jobNumbers),
        'issueQty': PlutoCell(value: totalIssueQty),
        'materials': PlutoCell(value: ''),
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
        title: const Text('Customer Scope Material Issues'),
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
