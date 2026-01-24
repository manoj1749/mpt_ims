// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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

  int _gridRebuildToken = 0;
  Timer? _refreshDebounce;

  String _searchMode = 'all';
  String _searchQuery = '';
  double? _fromQty;
  double? _toQty;
  DateTime? _startDate;
  DateTime? _endDate;

  TextEditingController? _fromQtyController;
  TextEditingController? _toQtyController;

  final TextEditingController _dropdownSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fromQtyController = TextEditingController(text: _fromQty?.toString() ?? '');
    _toQtyController = TextEditingController(text: _toQty?.toString() ?? '');

    _fromQtyController!.addListener(() {
      final value = _fromQtyController!.text;
      _fromQty = value.isEmpty ? null : double.tryParse(value);
      _scheduleGridRefresh();
    });

    _toQtyController!.addListener(() {
      final value = _toQtyController!.text;
      _toQty = value.isEmpty ? null : double.tryParse(value);
      _scheduleGridRefresh();
    });

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

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _fromQtyController?.dispose();
    _toQtyController?.dispose();
    _dropdownSearchController.dispose();
    super.dispose();
  }

  void _scheduleGridRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _gridRebuildToken++;
      });
    });
  }

  String _getSearchLabel() {
    switch (_searchMode) {
      case 'issueNo':
        return 'Search Issue No';
      case 'mr':
        return 'Search MR No';
      case 'job':
        return 'Search Job No';
      case 'part':
        return 'Search Part No';
      case 'description':
        return 'Search Description';
      case 'issuedTo':
        return 'Search Issued To';
      default:
        return 'Search';
    }
  }

  Widget _buildHeader() {
    final materialIssues = ref.read(materialIssueProvider);

    final issueNoOptions = {
      for (final i in materialIssues) i.issueNo,
    }.toList()
      ..sort();

    final mrOptions = <String>{};
    final partOptions = <String>{};
    final descriptionOptions = <String>{};
    final jobOptions = <String>{};
    final issuedToOptions = {
      for (final i in materialIssues) i.issuedTo,
    };

    for (final issue in materialIssues) {
      for (final item in issue.items) {
        partOptions.add(item.materialCode);
        descriptionOptions.add(item.materialDescription);
        mrOptions.addAll(item.mrDetails.keys);
        for (final d in item.mrDetails.values) {
          if (d.jobNo.isNotEmpty) jobOptions.add(d.jobNo);
        }
      }
    }

    final mrList = mrOptions.toList()..sort();
    final partList = partOptions.toList()..sort();
    final descList = descriptionOptions.toList()..sort();
    final jobList = jobOptions.where((j) => j.isNotEmpty).toList()..sort();
    final issuedToList = issuedToOptions.toList()..sort();

    List<String> optionsForMode() {
      switch (_searchMode) {
        case 'issueNo':
          return issueNoOptions;
        case 'mr':
          return mrList;
        case 'job':
          return jobList;
        case 'part':
          return partList;
        case 'description':
          return descList;
        case 'issuedTo':
          return issuedToList;
        default:
          return [];
      }
    }

    Widget buildSearchableDropdown(List<String> options) {
      return DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            _getSearchLabel(),
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
          items: options
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          value: _searchQuery.isEmpty ? null : _searchQuery,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _searchQuery = value);
            _scheduleGridRefresh();
          },
          buttonStyleData: ButtonStyleData(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[600]!),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 320,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _dropdownSearchController,
            searchInnerWidgetHeight: 56,
            searchInnerWidget: Container(
              height: 56,
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _dropdownSearchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return (item.value ?? '')
                  .toLowerCase()
                  .contains(searchValue.toLowerCase());
            },
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              _dropdownSearchController.clear();
            }
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Search Mode:', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: [
                  _searchMode == 'all',
                  _searchMode == 'issueNo',
                  _searchMode == 'mr',
                  _searchMode == 'job',
                  _searchMode == 'part',
                  _searchMode == 'description',
                  _searchMode == 'issuedTo',
                ],
                onPressed: (index) {
                  setState(() {
                    _searchMode = [
                      'all',
                      'issueNo',
                      'mr',
                      'job',
                      'part',
                      'description',
                      'issuedTo'
                    ][index];
                    _searchQuery = '';
                    _fromQty = null;
                    _toQty = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  _fromQtyController?.text = '';
                  _toQtyController?.text = '';
                  _scheduleGridRefresh();
                },
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('All')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Issue')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('MR')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Job')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Part')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Desc')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Issued To')),
                ],
                borderColor: Colors.grey,
                selectedBorderColor: Colors.blue,
                selectedColor: Colors.white,
                fillColor: Colors.blueAccent,
                color: Colors.white70,
              ),
              const SizedBox(width: 16),
              if (_searchMode != 'all')
                SizedBox(
                  width: 320,
                  child: buildSearchableDropdown(optionsForMode()),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'From Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: _startDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _startDate = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                      text: _startDate == null
                          ? ''
                          : _startDate!.toIso8601String().split('T').first),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() => _startDate =
                          DateTime(picked.year, picked.month, picked.day));
                      _scheduleGridRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'To Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _endDate = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                      text: _endDate == null
                          ? ''
                          : _endDate!.toIso8601String().split('T').first),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() => _endDate =
                          DateTime(picked.year, picked.month, picked.day));
                      _scheduleGridRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'From Qty',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF424242),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                  controller: _fromQtyController,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'To Qty',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF424242),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                  controller: _toQtyController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PlutoRow> _getRows() {
    final materialIssues = ref.watch(materialIssueProvider);

    final filtered = materialIssues.where((issue) {
      try {
        final d = DateTime.parse(issue.issueDate);
        if (_startDate != null && d.isBefore(_startDate!)) return false;
        if (_endDate != null && d.isAfter(_endDate!)) return false;
      } catch (_) {}
      return true;
    }).toList();

    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (final issue in filtered) {
      // Search filters
      if (_searchMode != 'all' && _searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        bool matches = true;
        switch (_searchMode) {
          case 'issueNo':
            matches = issue.issueNo.toLowerCase().contains(q);
            break;
          case 'issuedTo':
            matches = issue.issuedTo.toLowerCase().contains(q);
            break;
          case 'job':
            matches = issue.formattedJobNo.toLowerCase().contains(q);
            break;
          case 'mr':
            matches = issue.items.any((it) =>
                it.mrDetails.keys.any((mr) => mr.toLowerCase().contains(q)));
            break;
          case 'part':
            matches = issue.items.any((it) =>
                it.materialCode.toLowerCase().contains(q) ||
                it.materialDescription.toLowerCase().contains(q));
            break;
          case 'description':
            matches = issue.items
                .any((it) => it.materialDescription.toLowerCase().contains(q));
            break;
          default:
            break;
        }
        if (!matches) continue;
      }

      // Qty filter: issue-level total issued qty across items
      if (_fromQty != null || _toQty != null) {
        final totalQty = issue.items.fold<double>(
            0.0, (sum, it) => sum + (it.quantity));
        final matchesQty = (_fromQty == null || totalQty >= _fromQty!) &&
            (_toQty == null || totalQty <= _toQty!);
        if (!matchesQty) continue;
      }

      // Get unique MR numbers
      final mrNumbers =
          issue.items.expand((item) => item.mrDetails.keys).toSet().join(', ');

      // Get unique job numbers
      final jobNumbers = issue.items
          .expand((item) => item.mrDetails.values)
          .map((detail) => detail.jobNo)
          .toSet()
          .join(', ');

      rows.add(
        PlutoRow(cells: {
          'serialNo': PlutoCell(value: serialNo++),
          'issueNo': PlutoCell(value: issue.issueNo),
          'issueDate': PlutoCell(value: issue.issueDate),
          'mrNumbers': PlutoCell(value: mrNumbers),
          'jobNumbers': PlutoCell(value: jobNumbers),
          'materials': PlutoCell(value: ''),
          'actions': PlutoCell(value: ''),
        }),
      );
    }

    return rows;
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
                _scheduleGridRefresh();

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
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: PlutoGrid(
                key: ValueKey(_gridRebuildToken),
                columns: columns,
                rows: _getRows(),
                onLoaded: (PlutoGridOnLoadedEvent event) {
                  stateManager = event.stateManager;
                },
                configuration: PlutoGridConfigurations.darkMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
