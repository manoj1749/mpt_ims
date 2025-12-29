import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'dart:async';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/sale_order.dart';
import '../../provider/sale_order_provider.dart';
import 'add_edit_sale_order_page.dart';
import '../../widgets/pluto_grid_configuration.dart';

class SaleOrderListPage extends ConsumerStatefulWidget {
  const SaleOrderListPage({super.key});

  @override
  ConsumerState<SaleOrderListPage> createState() => _SaleOrderListPageState();
}

class _SaleOrderListPageState extends ConsumerState<SaleOrderListPage> {
  PlutoGridStateManager? stateManager;

  int _gridRebuildToken = 0;
  Timer? _refreshDebounce;

  String _searchMode = 'all';
  String _searchQuery = '';
  final TextEditingController _dropdownSearchController = TextEditingController();

  DateTime? _createdFrom;
  DateTime? _createdTo;
  DateTime? _startFrom;
  DateTime? _startTo;
  DateTime? _targetFrom;
  DateTime? _targetTo;
  DateTime? _endFrom;
  DateTime? _endTo;

  @override
  void initState() {
    super.initState();
    // Load sale orders when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleOrderProvider.notifier).loadSaleOrders();
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
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
      case 'orderNo':
        return 'Search Order No';
      case 'customer':
        return 'Search Customer';
      case 'jobNo':
        return 'Search Job No';
      default:
        return 'Search';
    }
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    final d = DateTime.tryParse(value.trim());
    if (d != null) return DateTime(d.year, d.month, d.day);
    return null;
  }

  Future<void> _pickDate({required bool isFrom, required String field}) async {
    DateTime? current;
    switch (field) {
      case 'created':
        current = isFrom ? _createdFrom : _createdTo;
        break;
      case 'start':
        current = isFrom ? _startFrom : _startTo;
        break;
      case 'target':
        current = isFrom ? _targetFrom : _targetTo;
        break;
      case 'end':
        current = isFrom ? _endFrom : _endTo;
        break;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);

    setState(() {
      switch (field) {
        case 'created':
          if (isFrom) {
            _createdFrom = normalized;
          } else {
            _createdTo = normalized;
          }
          break;
        case 'start':
          if (isFrom) {
            _startFrom = normalized;
          } else {
            _startTo = normalized;
          }
          break;
        case 'target':
          if (isFrom) {
            _targetFrom = normalized;
          } else {
            _targetTo = normalized;
          }
          break;
        case 'end':
          if (isFrom) {
            _endFrom = normalized;
          } else {
            _endTo = normalized;
          }
          break;
      }
    });

    _scheduleGridRefresh();
  }

  Widget _buildHeader(List<SaleOrder> orders) {
    final orderNoOptions = {
      for (final o in orders) o.orderNo,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final customerOptions = {
      for (final o in orders) o.customerName,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final jobNoOptions = {
      for (final o in orders) o.jobNo,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    List<String> optionsForMode() {
      switch (_searchMode) {
        case 'orderNo':
          return orderNoOptions;
        case 'customer':
          return customerOptions;
        case 'jobNo':
          return jobNoOptions;
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
                  _searchMode == 'orderNo',
                  _searchMode == 'customer',
                  _searchMode == 'jobNo',
                ],
                onPressed: (index) {
                  setState(() {
                    _searchMode = [
                      'all',
                      'orderNo',
                      'customer',
                      'jobNo',
                    ][index];
                    _searchQuery = '';
                  });
                  _scheduleGridRefresh();
                },
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('All')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Order')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Customer')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Job')),
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
                  width: 360,
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
                    labelText: 'Created From',
                    border: const OutlineInputBorder(),
                    suffixIcon: _createdFrom != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _createdFrom = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _createdFrom == null
                        ? ''
                        : _createdFrom!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: true, field: 'created'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Created To',
                    border: const OutlineInputBorder(),
                    suffixIcon: _createdTo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _createdTo = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _createdTo == null
                        ? ''
                        : _createdTo!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: false, field: 'created'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start From',
                    border: const OutlineInputBorder(),
                    suffixIcon: _startFrom != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _startFrom = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _startFrom == null
                        ? ''
                        : _startFrom!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: true, field: 'start'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start To',
                    border: const OutlineInputBorder(),
                    suffixIcon: _startTo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _startTo = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _startTo == null
                        ? ''
                        : _startTo!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: false, field: 'start'),
                ),
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
                    labelText: 'Target From',
                    border: const OutlineInputBorder(),
                    suffixIcon: _targetFrom != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _targetFrom = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _targetFrom == null
                        ? ''
                        : _targetFrom!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: true, field: 'target'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Target To',
                    border: const OutlineInputBorder(),
                    suffixIcon: _targetTo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _targetTo = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _targetTo == null
                        ? ''
                        : _targetTo!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: false, field: 'target'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End From',
                    border: const OutlineInputBorder(),
                    suffixIcon: _endFrom != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _endFrom = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _endFrom == null
                        ? ''
                        : _endFrom!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: true, field: 'end'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End To',
                    border: const OutlineInputBorder(),
                    suffixIcon: _endTo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _endTo = null);
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _endTo == null
                        ? ''
                        : _endTo!.toIso8601String().split('T').first,
                  ),
                  onTap: () => _pickDate(isFrom: false, field: 'end'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: 'Order No',
        field: 'orderNo',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
        width: 120,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'orderDate',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
        width: 120,
      ),
      PlutoColumn(
        title: 'Customer',
        field: 'customerName',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 150,
        width: 200,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
        width: 120,
      ),
      PlutoColumn(
        title: 'Start Date',
        field: 'jobStartDate',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
        width: 120,
      ),
      PlutoColumn(
        title: 'Target Date',
        field: 'targetDate',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
        width: 120,
      ),
      PlutoColumn(
        title: 'End Date',
        field: 'endDate',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
        width: 120,
        renderer: (rendererContext) {
          final endDate = rendererContext.cell.value?.toString() ?? '';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              endDate.isEmpty ? 'Not completed' : endDate,
              style: TextStyle(
                color: endDate.isEmpty ? Colors.grey : Colors.green,
                fontWeight:
                    endDate.isEmpty ? FontWeight.normal : FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 80,
        width: 80,
        renderer: (rendererContext) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final order =
                        rendererContext.row.cells['order']?.value as SaleOrder?;
                    if (order != null) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditSaleOrderPage(order: order),
                        ),
                      );
                      if (result == true) {
                        // Force refresh the state
                        ref.invalidate(saleOrderProvider);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.blue[400],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    final order =
                        rendererContext.row.cells['order']?.value as SaleOrder?;
                    if (order != null) {
                      _confirmDelete(context, order);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows(List<SaleOrder> orders) {
    final filtered = <SaleOrder>[];
    for (final order in orders) {
      if (_searchMode != 'all' && _searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        switch (_searchMode) {
          case 'orderNo':
            if (!order.orderNo.toLowerCase().contains(q)) continue;
            break;
          case 'customer':
            if (!order.customerName.toLowerCase().contains(q)) continue;
            break;
          case 'jobNo':
            if (!order.jobNo.toLowerCase().contains(q)) continue;
            break;
        }
      }

      if (_createdFrom != null || _createdTo != null) {
        final d = _parseDate(order.orderDate);
        if (d == null) continue;
        if (_createdFrom != null && d.isBefore(_createdFrom!)) continue;
        if (_createdTo != null && d.isAfter(_createdTo!)) continue;
      }

      if (_startFrom != null || _startTo != null) {
        final d = _parseDate(order.jobStartDate);
        if (d == null) continue;
        if (_startFrom != null && d.isBefore(_startFrom!)) continue;
        if (_startTo != null && d.isAfter(_startTo!)) continue;
      }

      if (_targetFrom != null || _targetTo != null) {
        final d = _parseDate(order.targetDate);
        if (d == null) continue;
        if (_targetFrom != null && d.isBefore(_targetFrom!)) continue;
        if (_targetTo != null && d.isAfter(_targetTo!)) continue;
      }

      if (_endFrom != null || _endTo != null) {
        final d = _parseDate(order.endDate ?? '');
        if (d == null) continue;
        if (_endFrom != null && d.isBefore(_endFrom!)) continue;
        if (_endTo != null && d.isAfter(_endTo!)) continue;
      }

      filtered.add(order);
    }

    return filtered.map((order) {
      return PlutoRow(cells: {
        'order': PlutoCell(value: order),
        'orderNo': PlutoCell(value: order.orderNo),
        'orderDate': PlutoCell(value: order.orderDate),
        'customerName': PlutoCell(value: order.customerName),
        'jobNo': PlutoCell(value: order.jobNo),
        'jobStartDate': PlutoCell(value: order.jobStartDate),
        'targetDate': PlutoCell(value: order.targetDate),
        'endDate': PlutoCell(value: order.endDate ?? ''),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  void _confirmDelete(BuildContext context, SaleOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete sale order ${order.orderNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref.read(saleOrderProvider.notifier).deleteOrder(order);
                Navigator.of(context).pop();
                // Force refresh the state
                ref.invalidate(saleOrderProvider);
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
    final orders = ref.watch(saleOrderProvider);
    final visibleRows = _getRows(orders);

    if (stateManager != null) {
      stateManager!.removeAllRows();
      stateManager!.appendRows(visibleRows);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Orders'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditSaleOrderPage(),
            ),
          );
          if (result == true) {
            // Force refresh the state
            ref.invalidate(saleOrderProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sale orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditSaleOrderPage(),
                        ),
                      );
                      if (result == true) {
                        // Force refresh the state
                        ref.invalidate(saleOrderProvider);
                      }
                    },
                    child: const Text('Create New Order'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(orders),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: PlutoGrid(
                          key: ValueKey(_gridRebuildToken),
                          columns: _getColumns(),
                          rows: visibleRows,
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            setState(() {
                              stateManager = event.stateManager;
                              stateManager?.setShowColumnFilter(true);
                            });
                          },
                          configuration:
                              PlutoGridConfigurations.darkMode().copyWith(
                            columnSize: const PlutoGridColumnSizeConfig(
                              autoSizeMode: PlutoAutoSizeMode.equal,
                              resizeMode: PlutoResizeMode.normal,
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
