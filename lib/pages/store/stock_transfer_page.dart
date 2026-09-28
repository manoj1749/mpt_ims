import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../models/job_order_request.dart';
import '../../models/purchase_request.dart';
import '../../models/sale_order.dart';
import '../../models/stock_maintenance.dart';
import '../../provider/job_order_request_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/sale_order_provider.dart';
import '../../provider/stock_maintenance_provider.dart';

class StockTransferHomePage extends ConsumerStatefulWidget {
  const StockTransferHomePage({super.key});

  @override
  ConsumerState<StockTransferHomePage> createState() =>
      _StockTransferHomePageState();
}

class _StockTransferHomePageState extends ConsumerState<StockTransferHomePage> {
  String? _selectedMaterialCode;
  final TextEditingController _materialSearchController =
      TextEditingController();

  @override
  void dispose() {
    _materialSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stocks = ref.watch(stockMaintenanceProvider);

    final materials = stocks.toList()
      ..sort((a, b) => a.materialCode.compareTo(b.materialCode));

    final selectedStock = _selectedMaterialCode == null
        ? null
        : materials
            .where((s) => s.materialCode == _selectedMaterialCode)
            .firstOrNull;

    final availabilityByJob = _selectedMaterialCode == null
        ? <String, double>{}
        : ref
            .watch(stockMaintenanceProvider.notifier)
            .jobWiseAvailability(_selectedMaterialCode!);

    final sortedJobs = availabilityByJob.keys.toList()
      ..sort((a, b) {
        if (a == 'General') return -1;
        if (b == 'General') return 1;
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Transfer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a material to view its available stock and transfer '
              'quantities between General and Board (job) locations.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField2<String>(
              value: _selectedMaterialCode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select Material'),
              items: materials
                  .map((s) => DropdownMenuItem<String>(
                        value: s.materialCode,
                        child: Text(
                          '${s.materialCode} - ${s.materialDescription}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMaterialCode = value;
                });
              },
              dropdownSearchData: DropdownSearchData(
                searchController: _materialSearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Container(
                  height: 50,
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 4,
                    right: 8,
                    left: 8,
                  ),
                  child: TextFormField(
                    controller: _materialSearchController,
                    expands: true,
                    maxLines: null,
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      hintText: 'Search Material',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  final stock = materials.firstWhere(
                    (s) => s.materialCode == item.value,
                  );
                  final query = searchValue.toLowerCase();
                  return stock.materialCode.toLowerCase().contains(query) ||
                      stock.materialDescription.toLowerCase().contains(query);
                },
              ),
              onMenuStateChange: (isOpen) {
                if (!isOpen) _materialSearchController.clear();
              },
            ),
            if (_selectedMaterialCode != null) ...[
              const SizedBox(height: 16),
              Text('Available Stock by Location',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sortedJobs.isEmpty
                      ? const Text('No available stock for this material.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedJobs
                              .map((job) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '$job: ${availabilityByJob[job]!.toStringAsFixed(2)} ${selectedStock?.unit ?? ''}',
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMaterialCode == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StockTransferPage(
                              materialCode: _selectedMaterialCode!,
                            ),
                          ),
                        );
                      },
                child: const Text('Open Transfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockTransferPage extends ConsumerStatefulWidget {
  final String materialCode;

  const StockTransferPage({
    super.key,
    required this.materialCode,
  });

  @override
  ConsumerState<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends ConsumerState<StockTransferPage> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _newBoardController = TextEditingController();
  bool _isSubmitting = false;
  bool _enterNewBoard = false;
  String? _fromJobNo;
  String? _toJobNo;

  DateTime? _tryParseDateTime(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) test) {
    for (final v in values) {
      if (test(v)) return v;
    }
    return null;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _newBoardController.dispose();
    super.dispose();
  }

  StockMaintenance? _getStock() {
    return _firstWhereOrNull(
      ref.read(stockMaintenanceProvider),
      (s) => s.materialCode == widget.materialCode,
    );
  }

  /// All known Board/job numbers anywhere in the system (Job Order Requests,
  /// Purchase Requests, Sale Orders, and any job already used in stock
  /// records), so a destination Board can be selected even if it doesn't yet
  /// have stock allocated to it for this specific material.
  List<String> _allKnownBoardJobs({
    required List<JobOrderRequest> jobOrderRequests,
    required List<PurchaseRequest> purchaseRequests,
    required List<SaleOrder> saleOrders,
    required List<StockMaintenance> allStocks,
  }) {
    final jobs = <String>{};

    void addJob(String? job) {
      final trimmed = job?.trim() ?? '';
      if (trimmed.isNotEmpty && trimmed != 'General') {
        jobs.add(trimmed);
      }
    }

    for (final jor in jobOrderRequests) {
      for (final job in jor.selectedJobs) {
        addJob(job);
      }
    }
    for (final pr in purchaseRequests) {
      addJob(pr.jobNo);
    }
    for (final so in saleOrders) {
      addJob(so.jobNo);
    }
    for (final stock in allStocks) {
      for (final jobNo in stock.jobDetails.keys) {
        addJob(jobNo);
      }
      for (final pr in stock.prDetails.values) {
        addJob(pr.jobNo);
      }
    }

    return jobs.toList()..sort();
  }

  Future<void> _submitTransfer() async {
    final fromJob = _fromJobNo;
    final toJob = _toJobNo;

    if (fromJob == null || toJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both From and To locations')),
      );
      return;
    }
    if (fromJob == toJob) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('From and To locations cannot be the same')),
      );
      return;
    }

    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer quantity')),
      );
      return;
    }

    final stock = _getStock();
    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Stock record not found for this material')),
      );
      return;
    }

    final available = ref
            .read(stockMaintenanceProvider.notifier)
            .jobWiseAvailability(widget.materialCode)[fromJob] ??
        0.0;
    if (qty > available + 0.0001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Insufficient available stock in $fromJob. Available: ${available.toStringAsFixed(2)}')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(stockMaintenanceProvider.notifier)
          .transferStockBetweenJobs(
            materialCode: widget.materialCode,
            fromJobNo: fromJob,
            toJobNo: toJob,
            quantity: qty,
          );

      if (mounted) {
        _qtyController.clear();
        setState(() {
          _fromJobNo = null;
          _toJobNo = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock transferred successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = _firstWhereOrNull(
      ref.watch(stockMaintenanceProvider),
      (s) => s.materialCode == widget.materialCode,
    );

    final jobOrderRequests = ref.watch(jobOrderRequestProvider);
    final purchaseRequests = ref.watch(purchaseRequestListProvider);
    final saleOrders = ref.watch(saleOrderProvider);
    final allStocks = ref.watch(stockMaintenanceProvider);

    final availabilityByJob = ref
        .watch(stockMaintenanceProvider.notifier)
        .jobWiseAvailability(widget.materialCode);

    // "From" can only be a location that actually has stock.
    final fromOptions = availabilityByJob.keys.toList()
      ..sort((a, b) {
        if (a == 'General') return -1;
        if (b == 'General') return 1;
        return a.compareTo(b);
      });

    // "To" can be General plus any known board/job (whether or not it
    // currently has stock), excluding whichever is selected as "From".
    final knownBoards = _allKnownBoardJobs(
      jobOrderRequests: jobOrderRequests,
      purchaseRequests: purchaseRequests,
      saleOrders: saleOrders,
      allStocks: allStocks,
    );
    final toOptions = <String>{
      'General',
      ...knownBoards,
      ...availabilityByJob.keys
    }.where((j) => j != _fromJobNo).toList()
      ..sort((a, b) {
        if (a == 'General') return -1;
        if (b == 'General') return 1;
        return a.compareTo(b);
      });

    // Keep selections valid if the underlying data changes.
    if (_fromJobNo != null && !fromOptions.contains(_fromJobNo)) {
      _fromJobNo = null;
    }
    if (!_enterNewBoard && _toJobNo != null && !toOptions.contains(_toJobNo)) {
      _toJobNo = null;
    }

    final selectedFromAvailable =
        _fromJobNo == null ? 0.0 : (availabilityByJob[_fromJobNo] ?? 0.0);

    final history = (stock?.transferHistory ?? []).toList();
    history.sort((a, b) {
      final da = _tryParseDateTime(a.dateTime);
      final db = _tryParseDateTime(b.dateTime);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Transfer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Material: ${widget.materialCode}',
                style: Theme.of(context).textTheme.titleMedium),
            if (stock != null)
              Text(stock.materialDescription,
                  style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (stock == null)
              const Text('No stock record found for this material.'),
            if (stock != null) ...[
              Text('Available Stock by Location',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: availabilityByJob.isEmpty
                      ? const Text('No available stock for this material.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: fromOptions
                              .map((job) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '$job: ${availabilityByJob[job]!.toStringAsFixed(2)} ${stock.unit}',
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fromJobNo,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      items: fromOptions
                          .map((j) => DropdownMenuItem<String>(
                                value: j,
                                child: Text(j),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _fromJobNo = value;
                          if (_toJobNo == value) _toJobNo = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _enterNewBoard
                        ? TextField(
                            controller: _newBoardController,
                            decoration: const InputDecoration(
                              labelText: 'New Board/Job No',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _toJobNo =
                                    value.trim().isEmpty ? null : value.trim();
                              });
                            },
                          )
                        : DropdownButtonFormField<String>(
                            value: _toJobNo,
                            decoration: const InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(),
                            ),
                            items: toOptions
                                .map((j) => DropdownMenuItem<String>(
                                      value: j,
                                      child: Text(j),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _toJobNo = value;
                              });
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Checkbox(
                    value: _enterNewBoard,
                    onChanged: (checked) {
                      setState(() {
                        _enterNewBoard = checked ?? false;
                        _toJobNo = null;
                        _newBoardController.clear();
                      });
                    },
                  ),
                  const Text('Enter a new Board/Job No for "To"'),
                ],
              ),
              if (_fromJobNo != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Available in $_fromJobNo: ${selectedFromAvailable.toStringAsFixed(2)} ${stock.unit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Transfer Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isSubmitting || _fromJobNo == null || _toJobNo == null)
                          ? null
                          : _submitTransfer,
                  child: const Text('Transfer'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Transfer History',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('No transfers yet.'))
                  : ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final h = history[index];
                        final dt = _tryParseDateTime(h.dateTime);
                        final dtText = dt == null
                            ? h.dateTime
                            : DateFormat('yyyy-MM-dd HH:mm')
                                .format(dt.toLocal());
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${h.fromJobNo} -> ${h.toJobNo}  (${h.quantity.toStringAsFixed(2)})',
                            ),
                            subtitle: Text(dtText),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
