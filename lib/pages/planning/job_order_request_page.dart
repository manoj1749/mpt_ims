import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/job_order_request_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../models/material_item.dart';
import '../../models/job_order_request.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'job_order_material_details_page.dart';
import 'create_job_order_request_page.dart';

class JobOrderRequestPage extends ConsumerStatefulWidget {
  const JobOrderRequestPage({super.key});

  @override
  ConsumerState<JobOrderRequestPage> createState() =>
      _JobOrderRequestPageState();
}

class _JobOrderRequestPageState extends ConsumerState<JobOrderRequestPage> {
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];
  String _searchQuery = '';
  bool _isLoading = false;
  Set<String> _selectedJobs = {}; // Track selected job numbers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    // Load data after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterials();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeColumns() {
    columns = [
      PlutoColumn(
        title: '',
        field: 'selected',
        type: PlutoColumnType.text(),
        width: 60,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final jobNo = rendererContext.row.cells['jobNo']?.value as String?;
          final isSelected = _selectedJobs.contains(jobNo ?? '');

          return InkWell(
            onTap: () {
              if (jobNo != null) {
                _onSelectionChanged(!isSelected, jobNo);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: isSelected ? Colors.blue : Colors.white54,
                size: 20,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 80,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.left,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job Number',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 300,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final jobNo = rendererContext.row.cells['jobNo']?.value as String?;
          final materials =
              rendererContext.row.cells['materials']?.value as List<PRItem>?;

          return InkWell(
            onTap: () {
              if (jobNo != null && materials != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobOrderMaterialDetailsPage(
                      jobNo: jobNo,
                      materials: materials,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.open_in_new,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jobNo ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Material Count',
        field: 'materialCount',
        type: PlutoColumnType.number(),
        width: 180,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total Qty',
        field: 'totalQty',
        type: PlutoColumnType.number(format: '#,##0.00'),
        width: 150,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
    ];
  }

  void _loadMaterials() {
    if (_isLoading) return; // Prevent multiple simultaneous calls

    _isLoading = true;

    try {
      final purchaseRequests = ref.read(purchaseRequestListProvider);
      final materials = ref.read(materialListProvider);

      // Group materials by job number
      final Map<String, List<PRItem>> jobMaterials = {};

      for (final pr in purchaseRequests) {
        final matchingMaterials = <PRItem>[];

        for (final item in pr.items) {
          // Get material details from material master
          final material =
              materials.where((m) => m.partNo == item.materialCode).firstOrNull;

          if (material != null) {
            final category = material.category.toLowerCase().trim();
            final subCategory = material.subCategory.toLowerCase().trim();

            // Check if category is 'inhouse fabrication' and subcategory is 'ms' or 'link'
            if (category == 'inhouse fabrication' &&
                (subCategory == 'ms' || subCategory == 'link')) {
              matchingMaterials.add(item);
            }
          }
        }

        // Only add job if it has matching materials and jobNo is not null
        if (matchingMaterials.isNotEmpty && pr.jobNo != null) {
          // Merge materials if job already exists, otherwise create new entry
          if (jobMaterials.containsKey(pr.jobNo!)) {
            // Merge with existing materials, avoiding duplicates
            final existingMaterials = jobMaterials[pr.jobNo!]!;
            final existingMaterialCodes =
                existingMaterials.map((m) => m.materialCode).toSet();

            for (final newMaterial in matchingMaterials) {
              if (!existingMaterialCodes.contains(newMaterial.materialCode)) {
                existingMaterials.add(newMaterial);
              }
            }
          } else {
            jobMaterials[pr.jobNo!] = matchingMaterials;
          }
        }
      }

      // Convert to list for further processing
      final filteredJobs = jobMaterials.entries.toList();

      // Apply search filter if any
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase().trim();
        final searchResults = filteredJobs.where((jobEntry) {
          // Search in job number
          if (jobEntry.key.toLowerCase().contains(searchLower)) {
            return true;
          }

          // Search in materials
          return jobEntry.value.any((item) {
            final material = materials
                .where((m) => m.partNo == item.materialCode)
                .firstOrNull;
            if (material == null) return false;

            return material.partNo.toLowerCase().contains(searchLower) ||
                material.description.toLowerCase().contains(searchLower) ||
                material.category.toLowerCase().contains(searchLower) ||
                material.subCategory.toLowerCase().contains(searchLower);
          });
        }).toList();
        _updateRows(searchResults);
      } else {
        _updateRows(filteredJobs);
      }

      // Update UI to show the loaded materials
      setState(() {});
    } finally {
      _isLoading = false;
    }
  }

  void _updateRows(List<MapEntry<String, List<PRItem>>> jobEntries) {
    rows = jobEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final jobEntry = entry.value;
      final jobNo = jobEntry.key;
      final materials = jobEntry.value;

      // Calculate total quantity for all materials in this job
      double totalQty = 0;
      for (final item in materials) {
        totalQty += double.tryParse(item.quantity) ?? 0.0;
      }

      return PlutoRow(
        cells: {
          'selected': PlutoCell(value: _selectedJobs.contains(jobNo)),
          'serialNo': PlutoCell(value: index + 1),
          'jobNo': PlutoCell(value: jobNo),
          'materialCount': PlutoCell(value: materials.length),
          'totalQty': PlutoCell(value: totalQty),
          'materials': PlutoCell(
              value: materials), // Store materials list for navigation
        },
      );
    }).toList();

    // Update stateManager if it's initialized, otherwise just update the UI
    if (stateManager != null) {
      stateManager!.removeAllRows();
      stateManager!.appendRows(rows);
    }
  }

  void _onSelectionChanged(bool selected, String jobNo) {
    setState(() {
      if (selected) {
        _selectedJobs.add(jobNo);
      } else {
        _selectedJobs.remove(jobNo);
      }
    });

    // Update the grid to reflect the new selection state
    _updateGridSelection();
  }

  void _updateGridSelection() {
    if (stateManager != null) {
      for (final row in stateManager!.rows) {
        final jobNo = row.cells['jobNo']?.value as String?;
        if (jobNo != null) {
          final isSelected = _selectedJobs.contains(jobNo);
          // Update the visual state without triggering another selection change
          row.cells['selected']?.value = isSelected;
        }
      }
      stateManager!.notifyListeners();
    }
  }

  void _createJobOrderRequest() {
    if (_selectedJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one job to create request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobOrderRequestPage(
          selectedJobs: _selectedJobs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for real-time updates
    final purchaseRequests = ref.watch(purchaseRequestListProvider);
    final materials = ref.watch(materialListProvider);
    final jobOrderRequests = ref.watch(jobOrderRequestProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Order Request'),
          backgroundColor: const Color(0xFF2D2D2D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Available Jobs'),
              Tab(text: 'Created Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Current implementation (Available Jobs)
            _buildAvailableJobsTab(purchaseRequests, materials),
            // Tab 2: Created Job Order Requests
            _buildCreatedRequestsTab(jobOrderRequests),
          ],
        ),
        floatingActionButton: _selectedJobs.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _createJobOrderRequest,
                icon: const Icon(Icons.add),
                label: Text('Create Request (${_selectedJobs.length})'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildAvailableJobsTab(
      List<PurchaseRequest> purchaseRequests, List<MaterialItem> materials) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search jobs...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        // Grid
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : PlutoGrid(
                  columns: columns,
                  rows: rows,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    stateManager = event.stateManager;
                    _loadMaterials();
                  },
                  configuration: PlutoGridConfigurations.darkMode(),
                  onChanged: (PlutoGridOnChangedEvent event) {
                    // Handle grid changes if needed
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreatedRequestsTab(List<JobOrderRequest> jobOrderRequests) {
    return Column(
      children: [
        // Search bar for created requests
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search requests...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        // Created requests grid
        Expanded(
          child: jobOrderRequests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No job order requests created',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create your first job order request from the Available Jobs tab',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : PlutoGrid(
                  columns: _buildCreatedRequestColumns(),
                  rows: _buildCreatedRequestRows(jobOrderRequests),
                  configuration: PlutoGridConfigurations.darkMode(),
                ),
        ),
      ],
    );
  }

  List<PlutoColumn> _buildCreatedRequestColumns() {
    return [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 60,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Request No',
        field: 'requestNo',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Request Date',
        field: 'requestDate',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Selected Jobs',
        field: 'selectedJobs',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final jobs =
              rendererContext.row.cells['selectedJobs']?.value as List<String>?;
          if (jobs == null || jobs.isEmpty) {
            return const Text(
              'No jobs',
              style: TextStyle(color: Colors.white38),
            );
          }

          return Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: jobs.take(3).map((job) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    job,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Material Groups',
        field: 'materialGroups',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 100,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final status = rendererContext.row.cells['status']?.value as String?;
          Color statusColor = Colors.white70;
          switch (status) {
            case 'pending':
              statusColor = Colors.orange;
              break;
            case 'approved':
              statusColor = Colors.green;
              break;
            case 'rejected':
              statusColor = Colors.red;
              break;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              status?.toUpperCase() ?? 'UNKNOWN',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildCreatedRequestRows(
      List<JobOrderRequest> jobOrderRequests) {
    return jobOrderRequests.asMap().entries.map((entry) {
      final index = entry.key;
      final request = entry.value;

      return PlutoRow(
        cells: {
          'serialNo': PlutoCell(value: index + 1),
          'requestNo': PlutoCell(value: request.requestNo),
          'requestDate': PlutoCell(value: request.requestDate),
          'selectedJobs': PlutoCell(value: request.selectedJobs),
          'materialGroups':
              PlutoCell(value: request.materialsByRawMaterial.length),
          'status': PlutoCell(value: request.status),
        },
      );
    }).toList();
  }
}
