import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/state.dart';
import '../../provider/state_provider.dart';
import 'add_state_page.dart';

class StateMasterPage extends ConsumerStatefulWidget {
  const StateMasterPage({super.key});

  @override
  ConsumerState<StateMasterPage> createState() => _StateMasterPageState();
}

class _StateMasterPageState extends ConsumerState<StateMasterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final double slNoWidth = 80.0;
  final double nameWidth = 300.0;
  final double codeWidth = 200.0;
  final double actionsWidth = 180.0;

  @override
  void initState() {
    super.initState();
    // Load states when page is opened
    Future.microtask(() => ref.read(stateListProvider.notifier).loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildExcelCell(String text,
      {double width = 150, bool center = false}) {
    return Container(
      width: width,
      height: 44,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActionCell(StateModel state, int index) {
    return Container(
      width: actionsWidth,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddStatePage(
                    stateToEdit: state,
                    index: ref.read(stateListProvider).indexOf(state),
                  ),
                ),
              );
            },
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context, state),
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(StateModel state, int index) {
    return Container(
      color: index.isEven ? const Color(0xFF121212) : const Color(0xFF1E1E1E),
      child: Row(
        children: [
          _buildExcelCell('${index + 1}', width: slNoWidth, center: true),
          _buildExcelCell(state.name, width: nameWidth),
          _buildExcelCell(state.stateCode.isNotEmpty ? state.stateCode : '--',
              width: codeWidth),
          _buildActionCell(state, index),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StateModel state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete State'),
        content: Text('Are you sure you want to delete ${state.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(stateListProvider.notifier).delete(state);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('State deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final states = ref.watch(stateListProvider);
    final filteredStates = _searchQuery.isEmpty
        ? states
        : ref.read(stateListProvider.notifier).searchStates(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('State Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(stateListProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddStatePage()),
            ),
            tooltip: 'Add State',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search States',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (filteredStates.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? 'No states yet'
                          : 'No states found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddStatePage()),
                        ),
                        child: const Text('Add New State'),
                      ),
                    ]
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    child: Row(
                      children: [
                        _buildExcelCell('Sl No',
                            width: slNoWidth, center: true),
                        _buildExcelCell('State Name', width: nameWidth),
                        _buildExcelCell('State Code', width: codeWidth),
                        _buildExcelCell('Actions',
                            width: actionsWidth, center: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredStates.length,
                      itemBuilder: (context, index) => _buildTableRow(
                        filteredStates[index],
                        index,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
