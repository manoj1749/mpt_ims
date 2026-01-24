// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

 import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/provider/material_request_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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

    columns = [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableFilterMenuItem: true,
      ),
      PlutoColumn(
        title: 'Issue No',
        field: 'issueNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableFilterMenuItem: true,
      ),
      PlutoColumn(
        title: 'Issue Date',
        field: 'issueDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableFilterMenuItem: true,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        enableFilterMenuItem: true,
      ),
      PlutoColumn(
        title: 'Issue Qty',
        field: 'issueQty',
        type: PlutoColumnType.text(),
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
        title: 'Issued By',
        field: 'issuedBy',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableFilterMenuItem: true,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final issue = ref.read(materialRequestProvider).firstWhere(
                        (issue) =>
                            issue.issueNo ==
                            rendererContext.cell.row.cells['issueNo']!.value,
                      );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMaterialRequestPage(
                        existingIssue: issue,
                        index: rendererContext.rowIdx,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final issueNo =
                      rendererContext.cell.row.cells['issueNo']!.value;

                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text(
                          'Are you sure you want to delete this Material Request?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    await ref
                        .read(materialRequestProvider.notifier)
                        .deleteMaterialRequest(issueNo);

                    if (stateManager != null) {
                      stateManager!.removeRows([rendererContext.row]);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Material Request deleted successfully')),
                      );
                    }
                  }
                },
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
      case 'part':
        return 'Search Part No';
      case 'description':
        return 'Search Description';
      case 'job':
        return 'Search Job No';
      case 'issuedBy':
        return 'Search Issued By';
      default:
        return 'Search';
    }
  }

  Widget _buildHeader() {
    final materialRequests = ref.read(materialRequestProvider);

    final issueNoOptions = {
      for (final r in materialRequests) r.issueNo,
    }.toList()
      ..sort();

    final partOptions = {
      for (final r in materialRequests) ...r.items.map((i) => i.materialCode),
    }.toList()
      ..sort();

    final descriptionOptions = {
      for (final r in materialRequests)
        ...r.items.map((i) => i.materialDescription),
    }.toList()
      ..sort();

    final jobOptions = {
      for (final r in materialRequests) r.jobNo ?? '',
    }.where((j) => j.isNotEmpty).toList()
      ..sort();

    final issuedByOptions = {
      for (final r in materialRequests) r.issuedBy,
    }.toList()
      ..sort();

    List<String> optionsForMode() {
      switch (_searchMode) {
        case 'issueNo':
          return issueNoOptions;
        case 'part':
          return partOptions;
        case 'description':
          return descriptionOptions;
        case 'job':
          return jobOptions;
        case 'issuedBy':
          return issuedByOptions;
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
                  _searchMode == 'part',
                  _searchMode == 'description',
                  _searchMode == 'job',
                  _searchMode == 'issuedBy',
                ],
                onPressed: (index) {
                  setState(() {
                    _searchMode = [
                      'all',
                      'issueNo',
                      'part',
                      'description',
                      'job',
                      'issuedBy'
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
                      child: Text('Part')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Desc')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Job')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Issued By')),
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
                width: 220,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status Filter',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    fillColor: Colors.grey[800],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  value: _selectedStatus,
                  items: ['Active', 'Completed', 'All']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                    _scheduleGridRefresh();
                  },
                ),
              ),
              const SizedBox(width: 16),
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
    final materialRequests = ref.watch(materialRequestProvider);

    // Apply status and date filters at request-level
    final filteredRequests = materialRequests.where((req) {
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Active') {
          if (req.status == 'Completed' || req.status == 'Issued') return false;
        } else if (_selectedStatus == 'Completed') {
          if (!(req.status == 'Completed' || req.status == 'Issued')) return false;
        } else {
          if (req.status != _selectedStatus) return false;
        }
      }

      try {
        final d = DateTime.parse(req.date);
        if (_startDate != null && d.isBefore(_startDate!)) return false;
        if (_endDate != null && d.isAfter(_endDate!)) return false;
      } catch (_) {}

      return true;
    }).toList();

    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (final req in filteredRequests) {
      for (final item in req.items) {
        if (_searchMode != 'all' && _searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          switch (_searchMode) {
            case 'issueNo':
              if (!req.issueNo.toLowerCase().contains(q)) continue;
              break;
            case 'part':
              if (!(item.materialCode.toLowerCase().contains(q) ||
                  item.materialDescription.toLowerCase().contains(q))) {
                continue;
              }
              break;
            case 'description':
              if (!item.materialDescription.toLowerCase().contains(q)) continue;
              break;
            case 'job':
              if (!(req.jobNo ?? '').toLowerCase().contains(q)) continue;
              break;
            case 'issuedBy':
              if (!req.issuedBy.toLowerCase().contains(q)) continue;
              break;
          }
        }

        if (_fromQty != null || _toQty != null) {
          final itemQty = double.tryParse(item.quantity) ?? 0.0;
          final matchesQty = (_fromQty == null || itemQty >= _fromQty!) &&
              (_toQty == null || itemQty <= _toQty!);
          if (!matchesQty) continue;
        }

        rows.add(
          PlutoRow(cells: {
            'serialNo': PlutoCell(value: serialNo++),
            'jobNo': PlutoCell(value: req.jobNo ?? ''),
            'issueNo': PlutoCell(value: req.issueNo),
            'issueDate': PlutoCell(value: req.date),
            'partNo': PlutoCell(value: item.materialCode),
            'description': PlutoCell(value: item.materialDescription),
            'issueQty': PlutoCell(value: item.quantity),
            'unit': PlutoCell(value: item.unit),
            'issuedBy': PlutoCell(value: req.issuedBy),
            'status': PlutoCell(value: req.status),
            'actions': PlutoCell(value: ''),
          }),
        );
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(materialRequestProvider);
    ref.watch(materialIssueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (stateManager != null) {
                ref.read(materialRequestProvider);
                ref.read(materialIssueProvider);
                _scheduleGridRefresh();

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
