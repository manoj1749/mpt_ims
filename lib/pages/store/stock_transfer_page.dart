import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_request.dart';
import '../../models/stock_maintenance.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/stock_maintenance_provider.dart';

class StockTransferHomePage extends ConsumerStatefulWidget {
  const StockTransferHomePage({super.key});

  @override
  ConsumerState<StockTransferHomePage> createState() =>
      _StockTransferHomePageState();
}

class _StockTransferHomePageState extends ConsumerState<StockTransferHomePage> {
  String? _selectedPrNo;
  String? _selectedMaterialCode;

  @override
  Widget build(BuildContext context) {
    final prs = ref.watch(purchaseRequestListProvider);
    final stocks = ref.watch(stockMaintenanceProvider);

    final pr = _selectedPrNo == null
        ? null
        : prs.where((p) => p.prNo == _selectedPrNo).isNotEmpty
            ? prs.firstWhere((p) => p.prNo == _selectedPrNo)
            : null;

    final prMaterialCodes = pr == null
        ? <String>[]
        : pr.items.map((i) => i.materialCode).toSet().toList();
    prMaterialCodes.sort();

    final availableMaterialCodes = pr == null
        ? stocks.map((s) => s.materialCode).toSet().toList()
        : prMaterialCodes;
    availableMaterialCodes.sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Transfer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedPrNo,
              decoration: const InputDecoration(
                labelText: 'Select PR',
                border: OutlineInputBorder(),
              ),
              items: prs
                  .map((p) => DropdownMenuItem<String>(
                        value: p.prNo,
                        child: Text(p.prNo),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrNo = value;
                  _selectedMaterialCode = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMaterialCode,
              decoration: const InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              items: availableMaterialCodes
                  .map((code) => DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMaterialCode = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedPrNo == null ||
                        _selectedMaterialCode == null)
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StockTransferPage(
                              prNo: _selectedPrNo!,
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
  final String prNo;
  final String materialCode;

  const StockTransferPage({
    super.key,
    required this.prNo,
    required this.materialCode,
  });

  @override
  ConsumerState<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends ConsumerState<StockTransferPage> {
  final TextEditingController _qtyController = TextEditingController();
  bool _isSubmitting = false;

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
    super.dispose();
  }

  PurchaseRequest? _getPR() {
    return _firstWhereOrNull(
      ref.read(purchaseRequestListProvider),
      (p) => p.prNo == widget.prNo,
    );
  }

  StockMaintenance? _getStock() {
    return _firstWhereOrNull(
      ref.read(stockMaintenanceProvider),
      (s) => s.materialCode == widget.materialCode,
    );
  }

  double _availableForPRJob(StockMaintenance stock, String prNo, String jobNo) {
    // General is treated as a pooled stock bucket across all PRs.
    if (jobNo == 'General') {
      return stock.prDetails.values
          .where((p) => p.jobNo == 'General')
          .fold(0.0, (sum, p) => sum + p.availableQuantity);
    }

    double total = 0.0;
    for (final entry in stock.prDetails.entries) {
      final key = entry.key;
      final prDetail = entry.value;
      if (prDetail.jobNo != jobNo) continue;

      if (key == prNo || key.startsWith('$prNo|XFER|$jobNo|')) {
        total += prDetail.availableQuantity;
      }
    }
    return total;
  }

  Future<void> _submitTransfer({required bool boardToGeneral}) async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer quantity')),
      );
      return;
    }

    final pr = _getPR();
    if (pr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PR not found')),
      );
      return;
    }

    final boardJobNo = (pr.jobNo == null || pr.jobNo!.trim().isEmpty)
        ? 'General'
        : pr.jobNo!.trim();

    if (boardJobNo == 'General') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This PR does not have a Board/Job No')),
      );
      return;
    }

    final stock = _getStock();
    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock record not found for this material')),
      );
      return;
    }

    final fromJob = boardToGeneral ? boardJobNo : 'General';
    final toJob = boardToGeneral ? 'General' : boardJobNo;

    final available = _availableForPRJob(stock, widget.prNo, fromJob);
    if (qty > available + 0.0001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient available stock. Available: ${available.toStringAsFixed(2)}')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(stockMaintenanceProvider.notifier)
          .transferStockForPRMaterial(
            materialCode: widget.materialCode,
            basePrNo: widget.prNo,
            boardJobNo: boardJobNo,
            fromJobNo: fromJob,
            toJobNo: toJob,
            quantity: qty,
          );

      if (mounted) {
        _qtyController.clear();
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
    final pr = _firstWhereOrNull(
      ref.watch(purchaseRequestListProvider),
      (p) => p.prNo == widget.prNo,
    );

    final stock = _firstWhereOrNull(
      ref.watch(stockMaintenanceProvider),
      (s) => s.materialCode == widget.materialCode,
    );

    final boardJobNo = (pr?.jobNo == null || pr!.jobNo!.trim().isEmpty)
        ? 'General'
        : pr.jobNo!.trim();

    final boardAvailable = (stock != null && boardJobNo != 'General')
        ? _availableForPRJob(stock, widget.prNo, boardJobNo)
        : 0.0;

    final generalAvailable = stock != null
        ? _availableForPRJob(stock, widget.prNo, 'General')
        : 0.0;

    final history = (stock?.transferHistory ?? [])
        .where((e) => e.basePrNo == widget.prNo)
        .toList();
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
            Text('PR No: ${widget.prNo}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Material: ${widget.materialCode}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            if (boardJobNo != 'General')
              Text('Board/Job No: $boardJobNo', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            if (stock == null)
              const Text('No stock record found for this material.'),
            if (stock != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available (Board): ${boardAvailable.toStringAsFixed(2)} ${stock.unit}'),
                      const SizedBox(height: 4),
                      Text('Available (General): ${generalAvailable.toStringAsFixed(2)} ${stock.unit}'),
                    ],
                  ),
                ),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || boardJobNo == 'General')
                        ? null
                        : () => _submitTransfer(boardToGeneral: true),
                    child: const Text('Board -> General'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || boardJobNo == 'General')
                        ? null
                        : () => _submitTransfer(boardToGeneral: false),
                    child: const Text('General -> Board'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Transfer History', style: Theme.of(context).textTheme.titleMedium),
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
                            : DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
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
