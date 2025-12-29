// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, avoid_print, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/quality_inspection.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../provider/material_provider.dart';
import '../../models/material_item.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/category_parameter_provider.dart';

import '../../models/category.dart';
import '../../provider/category_provider.dart';
import '../../models/store_inward.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../services/supplier_rating_service.dart';

class AddQualityInspectionPage extends ConsumerStatefulWidget {
  const AddQualityInspectionPage({super.key});

  @override
  ConsumerState<AddQualityInspectionPage> createState() =>
      _AddQualityInspectionPageState();
}

// Simple holder for blocked GRN details
class _BlockedGrn {
  final String grnNo;
  final String poNo;
  final String supplier;
  final String materialCode;
  final String materialDescription;
  final String category;
  final String reason;
  final double qty;
  final String grnDate;

  _BlockedGrn({
    required this.grnNo,
    required this.poNo,
    required this.supplier,
    required this.materialCode,
    required this.materialDescription,
    required this.category,
    required this.reason,
    required this.qty,
    required this.grnDate,
  });
}

class _AddQualityInspectionPageState
    extends ConsumerState<AddQualityInspectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _inspectionDateController = TextEditingController();
  final _inspectedByController = TextEditingController();
  final _approvedByController = TextEditingController();

  List<InspectionItem> _items = [];
  final Map<String, Map<String, TextEditingController>> _prQtyControllers = {};
  final Map<String, TextEditingController> _acceptedQtyControllers = {};
  
  // Track globally selected GRN
  String? _selectedGlobalGRN;
  
  // Track when parameters were loaded for each material category
  final Map<String, String> _categoryParameterTimestamps = {};

  // Loading state
  bool _isLoading = true;

  // Track missing configuration to explain why items are not shown
  final Set<String> _categoriesQcDisabled = {};
  final Set<String> _categoriesNoParams = {};

  // Blocked GRNs needing verification but hidden due to configuration issues
  final List<_BlockedGrn> _blockedGrns = [];

  @override
  void initState() {
    super.initState();
    // Set current date as default inspection date
    _inspectionDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Load all pending items immediately
    _loadAllPendingItems();

  }

  @override
  void dispose() {
    _inspectionDateController.dispose();
    _inspectedByController.dispose();
    _approvedByController.dispose();

    // Dispose of all accepted quantity controllers
    for (var controller in _acceptedQtyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // Helper method to get or create persistent accepted quantity controller
  TextEditingController _getAcceptedQtyController(String grnNo, double acceptedQty) {
    _acceptedQtyControllers[grnNo] ??= TextEditingController(text: acceptedQty.toString());
    return _acceptedQtyControllers[grnNo]!;
  }

  // Generate a new inspection number
  String _generateInspectionNo() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return 'QI$year$month$day$random';
  }

  void _loadAllPendingItems() {
    // show loader while (re)loading
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    // Use read() for initial synchronous fetch; watch() inside non-build can
    // cause empty values on first frame.
    final materials = ref.read(materialListProvider);
    final inwards = ref.read(storeInwardProvider);
    final inspections = ref.read(qualityInspectionProvider);
    final categories = ref.read(categoryListProvider);

    // Group items by material and GRN
    final materialGRNItems =
        <String, Map<String, List<Map<String, dynamic>>>>{};
    final grnInfo = <String, Map<String, String>>{};

    // Track inspected quantities per material and GRN
    final inspectedQtys = <String, Map<String, double>>{};

    // Reset missing config trackers
    _categoriesQcDisabled.clear();
    _categoriesNoParams.clear();
    _blockedGrns.clear();

    // First, gather all inspected quantities
    for (var inspection in inspections) {
      for (var item in inspection.items) {
        inspectedQtys.putIfAbsent(item.materialCode, () => {});

        for (var grnEntry in item.grnQuantities.entries) {
          final grnNo = grnEntry.key;
          final grnQty = grnEntry.value;
          final inspectedQty = grnQty.acceptedQty + grnQty.rejectedQty;

          inspectedQtys[item.materialCode]![grnNo] =
              (inspectedQtys[item.materialCode]![grnNo] ?? 0.0) + inspectedQty;
        }
      }
    }

    // Now process GRNs and check against inspected quantities
    for (var grn in inwards) {
      // Determine if this GRN has any pending inspections that require re-inspection
      final hasPendingReinspectionForGRN = inspections.any((insp) =>
          insp.grnNo == grn.grnNo &&
          (insp.status == 'Pending' ||
              insp.status == 'Pending - Parameters Changed'));

      // Skip GRNs that are fully inspected ONLY if there is no pending re-inspection
      if (grn.isFullyInspected && !hasPendingReinspectionForGRN) continue;

      for (var inwardItem in grn.items) {
        // Find the material to get its category
        final material = materials.firstWhere(
          (m) =>
              m.partNo == inwardItem.materialCode ||
              m.slNo == inwardItem.materialCode,
          orElse: () => MaterialItem(
            slNo: inwardItem.materialCode,
            description: inwardItem.materialDescription,
            partNo: inwardItem.materialCode,
            unit: inwardItem.unit,
            category: 'General',
            subCategory: '',
          ),
        );

        // Get the category settings
        final category = categories.firstWhere(
          (c) => c.name == material.category,
          orElse: () => Category(name: material.category),
        );

        // Compute remaining qty for this material on this GRN first
        final inspectedQty =
            inspectedQtys[inwardItem.materialCode]?[grn.grnNo] ?? 0.0;
        final remainingQty = inwardItem.receivedQty - inspectedQty;

        // Skip items that don't require quality inspection
        if (!category.requiresQualityCheck) {
          _categoriesQcDisabled.add(category.name);
          if (remainingQty > 0) {
            _blockedGrns.add(_BlockedGrn(
              grnNo: grn.grnNo,
              poNo: grn.poNo,
              supplier: grn.supplierName,
              materialCode: inwardItem.materialCode,
              materialDescription: inwardItem.materialDescription,
              category: category.name,
              reason: 'Quality Check disabled',
              qty: remainingQty,
              grnDate: grn.grnDate,
            ));
          }
          continue;
        }

        // Also include if there is a pending re-inspection for this GRN/material
        final hasPendingReinspectionForItem = inspections.any((insp) =>
            insp.grnNo == grn.grnNo &&
            (insp.status == 'Pending' ||
                insp.status == 'Pending - Parameters Changed') &&
            insp.items.any((it) => it.materialCode == inwardItem.materialCode));

        // Only include if there's remaining quantity to inspect OR a re-inspection is pending
        if (remainingQty > 0 || hasPendingReinspectionForItem) {
          // Store item data
          final itemData = {
            'materialCode': inwardItem.materialCode,
            'materialDescription': inwardItem.materialDescription,
            'unit': inwardItem.unit,
            'costPerUnit': inwardItem.costPerUnit,
            // For re-inspection, allow full GRN quantity to be reconsidered if no remaining qty
            'quantity': remainingQty > 0 ? remainingQty : inwardItem.receivedQty,
            'poNo': grn.poNo,
            'poDate': grn.poDate,
          };

          // Group by material and GRN
          materialGRNItems
              .putIfAbsent(inwardItem.materialCode, () => {})
              .putIfAbsent(grn.grnNo, () => [])
              .add(itemData);

          // Store GRN info
          grnInfo[grn.grnNo] = {
            'grnDate': grn.grnDate,
            'invoiceNo': grn.invoiceNo,
            'invoiceDate': grn.invoiceDate,
            'supplierName': grn.supplierName,
          };
        }
      }
    }

    setState(() {
      _items = [];

      // Process each material
      for (var materialEntry in materialGRNItems.entries) {
        final materialCode = materialEntry.key;
        final grnItems = materialEntry.value;

        if (grnItems.isEmpty) continue;

        // Get first item to access common properties
        final firstGRN = grnItems.values.first;
        final firstItemData = firstGRN.first;

        // Find the material to get its category
        final material = materials.firstWhere(
          (m) => m.slNo == materialCode || m.partNo == materialCode,
          orElse: () => materials.firstWhere(
            (m) =>
                m.description.toLowerCase() ==
                firstItemData['materialDescription'].toLowerCase(),
            orElse: () => MaterialItem(
              slNo: materialCode,
              description: firstItemData['materialDescription'],
              partNo: materialCode,
              unit: firstItemData['unit'],
              category: 'General',
              subCategory: '',
            ),
          ),
        );

        // Initialize GRN quantities
        final grnQuantities = <String, InspectionGRNQuantity>{};

        // Process each GRN's items
        for (var grnEntry in grnItems.entries) {
          final grnNo = grnEntry.key;
          final items = grnEntry.value;

          final totalQty = items.fold(
              0.0, (sum, item) => sum + (item['quantity'] as double));

          if (totalQty > 0) {
            grnQuantities[grnNo] = InspectionGRNQuantity(
              receivedQty: totalQty,
              acceptedQty: 0,
              rejectedQty: 0,
              usageDecision: 'Lot Accepted',
              poNo: items.first['poNo'],
              poDate: items.first['poDate'],
            );
          }
        }

        // Only create inspection item if there are GRNs with remaining quantities
        if (grnQuantities.isNotEmpty) {
          // Get category-specific parameters
          final categoryParams = ref.read(categoryParameterProvider);

          print(
              'Loading parameters for material: ${material.partNo}, category: ${material.category}');

          // Get only the parameters selected for this material's category
          final categoryMapping = categoryParams
              .where((mapping) => mapping.category == material.category)
              .firstOrNull;

          final parameters = <QualityParameter>[];

          if (categoryMapping != null && categoryMapping.parameters.isNotEmpty) {
            print(
                'Found category mapping for ${material.category} with ${categoryMapping.parameters.length} parameters');
            
            // Track when these parameters were loaded
            _categoryParameterTimestamps[material.category] = categoryMapping.lastModified;
            
            parameters.addAll(
                categoryMapping.parameters.map((paramName) => QualityParameter(
                      parameter: paramName,
                      isAcceptable: true,
                    )));
          } else {
            print('No quality parameters configured for ${material.category}');
            // Track missing parameters for this category
            _categoriesNoParams.add(material.category);
            // Record blocked GRNs for missing parameters
            for (final grnEntry in grnItems.entries) {
              final grnNo = grnEntry.key;
              final grnItemsList = grnEntry.value;
              if (grnItemsList.isNotEmpty) {
                final firstItem = grnItemsList.first;
                _blockedGrns.add(_BlockedGrn(
                  grnNo: grnNo,
                  poNo: firstItem['poNo'],
                  supplier: grnInfo[grnNo]?['supplierName'] ?? '',
                  materialCode: material.partNo,
                  materialDescription: firstItem['materialDescription'],
                  category: material.category,
                  reason: 'Missing quality parameters',
                  qty: firstItem['quantity'],
                  grnDate: grnInfo[grnNo]?['grnDate'] ?? '',
                ));
              }
            }
            // Skip this material if no parameters are configured
            continue;
          }

          print(
              'Final parameters for ${material.partNo}: ${parameters.map((p) => p.parameter).toList()}');

          final inspectionItem = InspectionItem(
            materialCode: materialCode,
            materialDescription: firstItemData['materialDescription'],
            unit: firstItemData['unit'],
            category: material.category,
            receivedQty:
                0, // Initialize to 0, will be updated when GRN is selected
            costPerUnit: double.parse(firstItemData['costPerUnit']),
            totalCost:
                0, // Initialize to 0, will be updated when GRN is selected
            sampleSize: 0,
            inspectedQty: 0,
            acceptedQty: 0,
            rejectedQty: 0,
            pendingQty:
                0, // Initialize to 0, will be updated when GRN is selected
            usageDecision: 'Lot Accepted',
            receivedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            expirationDate: '',
            parameters: parameters,
            grnQuantities: grnQuantities,
          );

          _items.add(inspectionItem);
        }
      }
    });

    // Set loading to false after processing all items
    setState(() {
      _isLoading = false;
    });
  }

  // Calculate sample size based on quantity
  int _calculateSampleSize(double quantity, Category category) {
    if (quantity < 100 && category.sampleSizeLessThan100 != null) {
      return category.sampleSizeLessThan100!;
    } else if (quantity >= 100 &&
        quantity <= 500 &&
        category.sampleSize100To500 != null) {
      return category.sampleSize100To500!;
    } else if (quantity > 500 && category.sampleSizeGreaterThan500 != null) {
      return category.sampleSizeGreaterThan500!;
    }
    return 0; // Default if no sample size is configured
  }

  // Calculate expiry date based on shelf life
  String _calculateExpiryDate(Category category, String receivedDate) {
    if (category.hasShelfLife != true ||
        category.shelfLifeValue == null ||
        category.shelfLifeUnit == null) {
      return '';
    }

    final received = DateFormat('yyyy-MM-dd').parse(receivedDate);
    DateTime expiryDate;

    switch (category.shelfLifeUnit) {
      case 'days':
        expiryDate = received.add(Duration(days: category.shelfLifeValue!));
        break;
      case 'months':
        expiryDate = DateTime(
          received.year,
          received.month + category.shelfLifeValue!,
          received.day,
        );
        break;
      case 'years':
        expiryDate = DateTime(
          received.year + category.shelfLifeValue!,
          received.month,
          received.day,
        );
        break;
      default:
        return '';
    }

    return DateFormat('yyyy-MM-dd').format(expiryDate);
  }


  // Update quantities when GRN is selected
  void _updateSelectedGRNQuantities(InspectionItem item, String selectedGRNNo) {
    final selectedGRNQty = item.grnQuantities[selectedGRNNo]!;
    item.receivedQty = selectedGRNQty.receivedQty;
    item.pendingQty = selectedGRNQty.receivedQty;
    item.totalCost = selectedGRNQty.receivedQty * item.costPerUnit;

    // Get the category settings
    final categories = ref.read(categoryListProvider);
    final category = categories.firstWhere(
      (c) => c.name == item.category,
      orElse: () => Category(name: item.category),
    );

    // Calculate and set sample size based on sampling plan by default
    item.sampleSize =
        _calculateSampleSize(item.receivedQty, category).toDouble();
    // If 100% Recheck is selected, required sample size is full GR quantity
    if (selectedGRNQty.usageDecision == '100% Recheck') {
      item.sampleSize = item.receivedQty;
    }

    // Calculate expiry date if needed
    if (category.hasExpiryDate == true) {
      // Keep the expiry date field empty to let user input it
      item.expirationDate = '';
    } else if (category.hasShelfLife == true) {
      // Calculate expiry date based on shelf life
      item.expirationDate = _calculateExpiryDate(category, item.receivedDate);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Listen for data updates and refresh when inputs change
    ref.listen<List<StoreInward>>(storeInwardProvider, (prev, next) {
      if (mounted && (_items.isEmpty || _isLoading)) {
        _loadAllPendingItems();
      }
    });
    ref.listen(materialListProvider, (prev, next) {
      if (mounted && (_items.isEmpty || _isLoading)) {
        _loadAllPendingItems();
      }
    });
    ref.listen(categoryParameterProvider, (prev, next) {
      if (mounted && (_items.isEmpty || _isLoading)) {
        _loadAllPendingItems();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Quality Inspection'),
        actions: [
          FilledButton.icon(
            onPressed: _saveInspection,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info message about one GRN at a time
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[300], size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select only one GRN at a time for inspection. Selecting a different GRN will automatically deselect the previous selection.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                buildTextField(_inspectionDateController, 'Inspection Date',
                    isDate: true),


                buildTextField(_inspectedByController, 'Inspected By'),
                buildTextField(_approvedByController, 'Approved By'),

                const SizedBox(height: 20),

                // Material Groups
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading Available Inspections',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Materials Available For Inspection',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Materials may be unavailable due to:\n• No pending GRNs requiring inspection\n• No quality parameters configured for material categories\n• Quality check disabled for material categories',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Detailed reasons when available
                          if (_categoriesNoParams.isNotEmpty || _categoriesQcDisabled.isNotEmpty) ...[
                            Card(
                              color: Colors.black.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_categoriesNoParams.isNotEmpty) ...[
                                      const Text(
                                        'Categories missing quality parameters:',
                                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                      const SizedBox(height: 6),
                                      ..._categoriesNoParams.map((c) => Row(
                                            children: [
                                              const Icon(Icons.circle, size: 6, color: Colors.orange),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(c, style: const TextStyle(color: Colors.white))),
                                            ],
                                          )),
                                      const SizedBox(height: 12),
                                    ],
                                    if (_categoriesQcDisabled.isNotEmpty) ...[
                                      const Text(
                                        'Categories with Quality Check disabled:',
                                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                      const SizedBox(height: 6),
                                      ..._categoriesQcDisabled.map((c) => Row(
                                            children: [
                                              const Icon(Icons.circle, size: 6, color: Colors.redAccent),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(c, style: const TextStyle(color: Colors.white))),
                                            ],
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Blocked GRNs list
                          if (_blockedGrns.isNotEmpty) ...[
                            Card(
                              color: Colors.black.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.warning, color: Colors.amber, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'GRNs blocked from inspection:',
                                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ..._blockedGrns.map((blockedGrn) => Card(
                                          color: Colors.grey.withOpacity(0.1),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text('GRN:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                                                    const SizedBox(width: 8),
                                                    Text(blockedGrn.grnNo, style: const TextStyle(color: Colors.white)),
                                                    const SizedBox(width: 16),
                                                    const Text('PO:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                                                    const SizedBox(width: 8),
                                                    Text(blockedGrn.poNo, style: const TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${blockedGrn.materialCode} - ${blockedGrn.materialDescription}',
                                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Qty: ${blockedGrn.qty}',
                                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Text(
                                                      'Category: ${blockedGrn.category}',
                                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Text(
                                                      'Date: ${blockedGrn.grnDate}',
                                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: blockedGrn.reason == 'Quality Check disabled' 
                                                      ? Colors.redAccent.withOpacity(0.2) 
                                                      : Colors.orange.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    blockedGrn.reason,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: blockedGrn.reason == 'Quality Check disabled' 
                                                        ? Colors.redAccent 
                                                        : Colors.orange,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.settings, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Configure quality parameters in Category Settings',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...buildMaterialGroups(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {bool isDate = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: isDate || readOnly,
        onTap: isDate
            ? () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  controller.text = DateFormat('yyyy-MM-dd').format(date);
                }
              }
            : null,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Validate inspected by and approved by fields
      if (_inspectedByController.text.trim().isEmpty) {
        throw Exception('Please enter the inspector name');
      }

      if (_approvedByController.text.trim().isEmpty) {
        throw Exception('Please enter the approver name');
      }

      // Count how many materials have selected GRNs
      int materialsWithSelectedGRNs = 0;
      InspectionItem? selectedItem;

      for (var item in _items) {
        final hasSelectedGRN = item.grnQuantities.values
            .any((grnQty) => grnQty.isSelected == true);
        if (hasSelectedGRN) {
          materialsWithSelectedGRNs++;
          selectedItem = item;
        }
      }

      // Validate GRN selection
      if (materialsWithSelectedGRNs == 0) {
        throw Exception('Please select a GRN for at least one material');
      }
      if (materialsWithSelectedGRNs > 1) {
        throw Exception('Please select GRN for only one material at a time');
      }

      // Validate that exactly one GRN is selected for the chosen material
      final selectedGRNs = selectedItem!.grnQuantities.values
          .where((grnQty) => grnQty.isSelected == true)
          .length;
      if (selectedGRNs != 1) {
        throw Exception('Please select exactly one GRN for the material');
      }

      // Check if category parameters have changed since they were loaded
      await _validateParameterChanges(selectedItem);

      final incompleteParams = selectedItem.parameters.where((p) {
        final obsMissing = p.observation.trim().isEmpty;
        final resultMissing = (p.result == null || p.result!.trim().isEmpty);
        return obsMissing || resultMissing;
      }).toList();

      if (incompleteParams.isNotEmpty) {
        final missingNames = incompleteParams.map((p) => p.parameter).toList();
        throw Exception(
            'Please fill Observation and select Result for: ${missingNames.join(', ')}');
      }

      // Get the selected GRN entry
      final selectedGRNEntry = selectedItem.grnQuantities.entries
          .firstWhere((entry) => entry.value.isSelected == true);
      final selectedGRNQty = selectedGRNEntry.value;

      // Get the GRN details to find the supplier
      final inwards = ref.read(storeInwardProvider);
      final selectedGRN = inwards.firstWhere(
        (grn) => grn.grnNo == selectedGRNEntry.key,
        orElse: () => throw Exception('Selected GRN not found'),
      );

      // Set quantities based on usage decision
      if (selectedGRNQty.usageDecision == 'Lot Accepted') {
        // If lot is accepted, all received quantity is accepted
        selectedGRNQty.acceptedQty = selectedGRNQty.receivedQty;
        selectedGRNQty.rejectedQty = 0.0;
        selectedItem.acceptedQty = selectedGRNQty.receivedQty;
        selectedItem.rejectedQty = 0.0;

        // Update the grnQuantities map with the final quantities
        selectedItem.grnQuantities[selectedGRNEntry.key] = selectedGRNQty;
      } else if (selectedGRNQty.usageDecision == 'Rejected') {
        // If lot is rejected, all received quantity is rejected
        selectedGRNQty.acceptedQty = 0.0;
        selectedGRNQty.rejectedQty = selectedGRNQty.receivedQty;
        selectedItem.acceptedQty = 0.0;
        selectedItem.rejectedQty = selectedGRNQty.receivedQty;

        // Update the grnQuantities map with the final quantities
        selectedItem.grnQuantities[selectedGRNEntry.key] = selectedGRNQty;
      } else if (selectedGRNQty.usageDecision == '100% Recheck') {
        // Option B: Block save if CAPA is required
        if (selectedItem.capaRequired == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CAPA is required. Please close CAPA in CAPA Status before saving the inspection.'),
              ),
            );
          }
          return;
        }
        if (selectedGRNQty.recheckType == '100% Acceptance') {
          // For 100% acceptance after recheck
          selectedGRNQty.acceptedQty = selectedGRNQty.receivedQty;
          selectedGRNQty.rejectedQty = 0.0;
          selectedItem.acceptedQty = selectedGRNQty.receivedQty;
          selectedItem.rejectedQty = 0.0;
          selectedItem.pendingQty = 0.0; // Clear pending quantity

          // Set the final usage decision to indicate it was accepted after recheck
          selectedGRNQty.usageDecision = 'Accepted After 100% Recheck';
          selectedItem.usageDecision = 'Accepted After 100% Recheck';

          // Update the grnQuantities map with the final quantities
          selectedItem.grnQuantities[selectedGRNEntry.key] = selectedGRNQty;

          // Create a new inspection record for stock update
          final recheckInspection = QualityInspection(
              inspectionNo: _generateInspectionNo(),
              inspectionDate: _inspectionDateController.text,
              grnNo: selectedGRN.grnNo,
              supplierName: selectedGRN.supplierName,
              poNo: selectedGRN.poNo,
              billNo: selectedGRN.invoiceNo,
              billDate: selectedGRN.invoiceDate,
              receivedDate: selectedGRN.grnDate,
              grnDate: selectedGRN.grnDate,
              inspectedBy: _inspectedByController.text,
              approvedBy: _approvedByController.text,
              items: [selectedItem],
              status: 'Completed - Accepted After 100% Recheck');

          // Add the recheck inspection first
          await ref
              .read(qualityInspectionProvider.notifier)
              .addInspection(recheckInspection);

          // Update the stock maintenance with recheck result
          await ref
              .read(stockMaintenanceProvider.notifier)
              .updateStockFromInspection(recheckInspection);

          // Try to find and update the original inspection status if it exists
          final inspections = ref.read(qualityInspectionProvider);
          final originalInspection = inspections
              .where((insp) =>
                  insp.grnNo == selectedGRN.grnNo &&
                  insp.inspectionNo != recheckInspection.inspectionNo)
              .firstOrNull;

          // Only update the original inspection if it exists
          if (originalInspection != null) {
            await ref
                .read(qualityInspectionProvider.notifier)
                .updateInspectionStatus(originalInspection.inspectionNo,
                    'Completed - Accepted After 100% Recheck');
          }

          // Show success and return early since we've handled everything
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inspection saved successfully')),
            );
            Navigator.of(context).pop();
          }
          return;
        } else if (selectedGRNQty.recheckType == 'Partial Acceptance') {
          // For partial acceptance, use the quantities from PR distribution
          double totalAcceptedQty = 0.0;

          // Find the matching item in the GRN
          final grnItem = selectedGRN.items.firstWhere(
            (item) => item.materialCode == selectedItem?.materialCode,
            orElse: () => throw Exception('Material not found in selected GRN'),
          );

          for (var poEntry in grnItem.prQuantities.entries) {
            final prMap = poEntry.value;
            if (prMap != null) {
              for (var prEntry in prMap.entries) {
                final qtyController = _prQtyControllers[selectedGRNEntry.key]![
                    '${poEntry.key}_${prEntry.key}'];
                if (qtyController != null && qtyController.text.isNotEmpty) {
                  totalAcceptedQty += double.parse(qtyController.text);
                }
              }
            }
          }
          selectedGRNQty.acceptedQty = totalAcceptedQty;
          selectedGRNQty.rejectedQty =
              selectedGRNQty.receivedQty - totalAcceptedQty;
          selectedItem.acceptedQty = totalAcceptedQty;
          selectedItem.rejectedQty =
              selectedGRNQty.receivedQty - totalAcceptedQty;
          selectedItem.pendingQty = 0.0; // Clear pending quantity

          // Set the final usage decision to indicate partial acceptance after recheck
          selectedGRNQty.usageDecision =
              'Partially Accepted After 100% Recheck';
          selectedItem.usageDecision = 'Partially Accepted After 100% Recheck';

          // Update the grnQuantities map with the final quantities
          selectedItem.grnQuantities[selectedGRNEntry.key] = selectedGRNQty;

          // Create a new inspection record for stock update
          final recheckInspection = QualityInspection(
              inspectionNo: _generateInspectionNo(),
              inspectionDate: _inspectionDateController.text,
              grnNo: selectedGRN.grnNo,
              supplierName: selectedGRN.supplierName,
              poNo: selectedGRN.poNo,
              billNo: selectedGRN.invoiceNo,
              billDate: selectedGRN.invoiceDate,
              receivedDate: selectedGRN.grnDate,
              grnDate: selectedGRN.grnDate,
              inspectedBy: _inspectedByController.text,
              approvedBy: _approvedByController.text,
              items: [selectedItem],
              status: 'Completed - Partially Accepted After Recheck');

          // Update the stock maintenance with recheck result
          await ref
              .read(stockMaintenanceProvider.notifier)
              .updateStockFromInspection(recheckInspection);

          // Update the original inspection status
          final originalInspection = ref
              .read(qualityInspectionProvider)
              .firstWhere((insp) => insp.grnNo == selectedGRN.grnNo);
          await ref
              .read(qualityInspectionProvider.notifier)
              .updateInspectionStatus(originalInspection.inspectionNo,
                  'Completed - Partially Accepted After Recheck');
        }
      }

      // Update pending quantity
      selectedItem.pendingQty = selectedGRNQty.receivedQty -
          (selectedGRNQty.acceptedQty + selectedGRNQty.rejectedQty);

      // Update the grnQuantities map with the final quantities
      selectedItem.grnQuantities[selectedGRNEntry.key] = selectedGRNQty;

      // Option B: Block save if CAPA is required for this item
      if (selectedItem.capaRequired == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CAPA is required. Please close CAPA in CAPA Status before saving the inspection.'),
            ),
          );
        }
        return;
      }

      // Create the inspection with appropriate status
      final inspection = QualityInspection(
        inspectionNo: ref
            .read(qualityInspectionProvider.notifier)
            .generateInspectionNumber(),
        inspectionDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        grnNo: selectedGRNEntry.key,
        supplierName: selectedGRN.supplierName,
        poNo: selectedGRN.poNo,
        billNo: selectedGRN.invoiceNo,
        billDate: selectedGRN.invoiceDate,
        receivedDate: selectedGRN.grnDate,
        grnDate: selectedGRN.grnDate,
        inspectedBy: _inspectedByController.text.trim(),
        approvedBy: _approvedByController.text.trim(),
        items: [selectedItem],
        status: _determineInspectionStatus(selectedItem),
      );

      // Add the inspection (this will automatically update stock and GRN status)
      await ref
          .read(qualityInspectionProvider.notifier)
          .addInspection(inspection);

      // If there was a previous pending inspection for this GRN (including parameter-changed),
      // mark it completed to avoid it lingering in the Add page re-inspection list
      final currentInspections = ref.read(qualityInspectionProvider);
      for (final prev in currentInspections) {
        if (prev.grnNo == selectedGRNEntry.key &&
            (prev.status == 'Pending' ||
             prev.status == 'Pending - Parameters Changed')) {
          await ref
              .read(qualityInspectionProvider.notifier)
              .updateInspectionStatus(prev.inspectionNo, inspection.status);
        }
      }

      // Update supplier quality rating based on this inspection
      try {
        await SupplierRatingService.updateSupplierRating(
          ref,
          inspection.supplierName,
        );
      } catch (e) {
        print('Warning: Could not update supplier rating: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<Widget> buildMaterialGroups() {
    final groups = <String, List<InspectionItem>>{};
    for (var item in _items) {
      groups.putIfAbsent(item.materialCode, () => []).add(item);
    }

    return groups.entries.map((entry) {
      final items = entry.value;
      final firstItem = items.first;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material Info
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstItem.materialDescription,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Code: ${firstItem.materialCode} | Unit: ${firstItem.unit}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Cost/Unit: ₹${firstItem.costPerUnit}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // GRN Selection
              const Row(
                children: [
                  Text('Select GRN:'),
                ],
              ),
              const SizedBox(height: 16),

              // Individual GRN Inspection
              ...firstItem.grnQuantities.entries.map((entry) {
                final grnNo = entry.key;
                final grnQty = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GRN Header with Radio button
                      Row(
                        children: [
                          Radio<String>(
                            value: grnNo,
                            groupValue: _selectedGlobalGRN,
                            onChanged: (value) {
                              setState(() {
                                _selectedGlobalGRN = value;
                                // Deselect all GRNs across all materials
                                for (var item in _items) {
                                  for (var grnEntry in item.grnQuantities.entries) {
                                    grnEntry.value.isSelected = false;
                                  }
                                }
                                // Select only this specific GRN for this specific item
                                if (firstItem.grnQuantities.containsKey(grnNo)) {
                                  firstItem.grnQuantities[grnNo]!.isSelected = true;
                                }
                                // Update quantities based on selected GRN
                                _updateSelectedGRNQuantities(firstItem, grnNo);
                              });
                            },
                          ),
                          Text('GRN: $grnNo'),
                          const SizedBox(width: 16),
                          Text('Received Qty: ${grnQty.receivedQty}'),
                        ],
                      ),
                      if (grnQty.isSelected == true) ...[
                        const SizedBox(height: 16),
                        // Usage Decision and CAPA in one row
                        Row(
                          children: [
                            // Usage Decision Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: grnQty.usageDecision == 'Partially Accepted After 100% Recheck' ||
                                       grnQty.usageDecision == 'Accepted After 100% Recheck'
                                       ? '100% Recheck' : grnQty.usageDecision,
                                decoration: const InputDecoration(
                                  labelText: 'Usage Decision',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Lot Accepted',
                                    child: Text('Lot Accepted'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Rejected',
                                    child: Text('Rejected'),
                                  ),
                                  DropdownMenuItem(
                                    value: '100% Recheck',
                                    child: Text('100% Recheck'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  // Show confirmation dialog for rejection
                                  if (value == 'Rejected') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Rejection'),
                                        content: const Text(
                                            'Are you sure you want to reject this lot? This will require CAPA.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                  }

                                  setState(() {
                                    grnQty.usageDecision = value!;
                                    firstItem.usageDecision = value;

                                    // Set CAPA requirement based on decision
                                    if (value == 'Rejected') {
                                      firstItem.capaRequired = true;
                                    }

                                    if (value != '100% Recheck') {
                                      grnQty.recheckType = null;
                                    }

                                    // Auto-update accepted/rejected quantities
                                    if (value == 'Lot Accepted') {
                                      // Validate parameters before accepting
                                      bool hasInvalidParams = firstItem
                                          .parameters
                                          .any((param) => !param.isAcceptable);
                                      if (hasInvalidParams) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Cannot accept lot with failed parameters'),
                                          ),
                                        );
                                        grnQty.usageDecision = 'Rejected';
                                        firstItem.usageDecision = 'Rejected';
                                        grnQty.acceptedQty = 0;
                                        grnQty.rejectedQty = grnQty.receivedQty;
                                        return;
                                      }
                                      grnQty.acceptedQty = grnQty.receivedQty;
                                      grnQty.rejectedQty = 0;
                                      firstItem.usageDecision = 'Lot Accepted';
                                      // When not 100% Recheck, use sampling plan for sample size
                                      final categories = ref.read(categoryListProvider);
                                      final category = categories.firstWhere(
                                        (c) => c.name == firstItem.category,
                                        orElse: () => Category(name: firstItem.category),
                                      );
                                      firstItem.sampleSize = _calculateSampleSize(firstItem.receivedQty, category).toDouble();
                                    } else if (value == 'Rejected') {
                                      grnQty.acceptedQty = 0;
                                      grnQty.rejectedQty = grnQty.receivedQty;
                                      firstItem.usageDecision = 'Rejected';
                                      // When not 100% Recheck, use sampling plan for sample size
                                      final categories = ref.read(categoryListProvider);
                                      final category = categories.firstWhere(
                                        (c) => c.name == firstItem.category,
                                        orElse: () => Category(name: firstItem.category),
                                      );
                                      firstItem.sampleSize = _calculateSampleSize(firstItem.receivedQty, category).toDouble();
                                    } else if (value == '100% Recheck') {
                                      grnQty.acceptedQty = 0;
                                      grnQty.rejectedQty = 0;
                                      firstItem.usageDecision = '100% Recheck';
                                      grnQty.recheckType ??= '100% Acceptance';
                                      firstItem.capaRequired =
                                          grnQty.recheckType == 'Partial Acceptance';
                                      // For 100% Recheck, required sample size equals full GR Qty
                                      firstItem.sampleSize = firstItem.receivedQty;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // CAPA Required Checkbox
                            if (grnQty.usageDecision == 'Rejected' ||
                                grnQty.usageDecision == '100% Recheck')
                              Expanded(
                                child: CheckboxListTile(
                                  title: const Text('CAPA Required'),
                                  value: grnQty.usageDecision == 'Rejected' ||
                                          (grnQty.usageDecision ==
                                                  '100% Recheck' &&
                                              grnQty.recheckType ==
                                                  'Partial Acceptance')
                                      ? true
                                      : (firstItem.capaRequired ?? false),
                                  onChanged: (grnQty.usageDecision == 'Rejected' ||
                                          (grnQty.usageDecision ==
                                                  '100% Recheck' &&
                                              grnQty.recheckType ==
                                                  'Partial Acceptance'))
                                      ? null
                                      : (bool? value) {
                                          setState(() {
                                            firstItem.capaRequired = value;
                                          });
                                        },
                                ),
                              ),
                          ],
                        ),

                        // Recheck Settings (only if 100% Recheck)
                        if (grnQty.usageDecision == '100% Recheck') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.refresh, size: 16),
                              const SizedBox(width: 8),
                              const Text('Recheck Settings',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  )),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value:
                                      grnQty.recheckType ?? '100% Acceptance',
                                  decoration: const InputDecoration(
                                    labelText: 'Recheck Type',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: '100% Acceptance',
                                      child: Text('100% Acceptance'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Partial Acceptance',
                                      child: Text('Partial Acceptance'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      grnQty.recheckType = value;
                                      if (value == 'Partial Acceptance') {
                                        firstItem.capaRequired = true;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Partial Acceptance Quantities (only if Partial Acceptance)
                        if (grnQty.usageDecision == '100% Recheck' &&
                            grnQty.recheckType == 'Partial Acceptance') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('acceptedQty_$grnNo'),
                                  decoration: InputDecoration(
                                    labelText: 'Accepted Quantity',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    hintText:
                                        'Max: ${grnQty.receivedQty.toString()}',
                                    hintStyle: TextStyle(
                                        fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  controller: _getAcceptedQtyController(grnNo, grnQty.acceptedQty),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return null;
                                    }
                                    final qty = double.tryParse(value);
                                    if (qty == null) return 'Invalid number';
                                    if (qty < 0) return 'Cannot be negative';
                                    if (qty > grnQty.receivedQty) {
                                      return 'Exceeds received qty';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // Allow empty value during editing
                                    if (value.isEmpty) {
                                      setState(() {
                                        grnQty.acceptedQty = 0;
                                        grnQty.rejectedQty = grnQty.receivedQty;
                                      });
                                      return;
                                    }

                                    final qty = double.tryParse(value) ?? 0;
                                    setState(() {
                                      // Do not rewrite controller text here (it breaks caret/focus)
                                      // Clamp only when editing completes.
                                      grnQty.acceptedQty = qty;
                                      grnQty.rejectedQty = grnQty.receivedQty -
                                          grnQty.acceptedQty;
                                    });
                                  },
                                  onEditingComplete: () {
                                    final controller = _acceptedQtyControllers[grnNo];
                                    if (controller != null) {
                                      final parsed = double.tryParse(controller.text);
                                      if (parsed != null) {
                                        final double clamped = parsed > grnQty.receivedQty
                                            ? grnQty.receivedQty
                                            : (parsed < 0 ? 0.0 : parsed);
                                        if (clamped != parsed) {
                                          controller.text = clamped.toString();
                                          controller.selection = TextSelection.fromPosition(
                                            TextPosition(offset: controller.text.length),
                                          );
                                        }
                                        setState(() {
                                          grnQty.acceptedQty = clamped;
                                          grnQty.rejectedQty = grnQty.receivedQty - clamped;
                                        });
                                      }
                                    }

                                    // Allow zero value when focus is lost
                                    if (grnQty.acceptedQty == 0) {
                                      setState(() {
                                        grnQty.rejectedQty = grnQty.receivedQty;
                                      });
                                    }
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Rejected Quantity',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                  readOnly: true,
                                  controller: TextEditingController(
                                      text: grnQty.rejectedQty.toString()),
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // PR/Job-wise Distribution for Partial Acceptance
                          if (grnQty.acceptedQty > 0) ...[
                            const Text('PR/Job Distribution',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                )),
                            const SizedBox(height: 8),
                            // Get the GRN from store inward provider
                            Builder(builder: (context) {
                              final inwards = ref.watch(storeInwardProvider);
                              final grn = inwards.firstWhere(
                                  (g) => g.grnNo == grnNo,
                                  orElse: () => StoreInward(
                                      grnNo: '',
                                      grnDate: '',
                                      supplierName: '',
                                      poNo: '',
                                      poDate: '',
                                      invoiceNo: '',
                                      invoiceDate: '',
                                      invoiceAmount: 0,
                                      receivedBy: '',
                                      checkedBy: '',
                                      items: []));

                              if (grn.grnNo.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final grnItem = grn.items.firstWhere(
                                  (i) =>
                                      i.materialCode == firstItem.materialCode,
                                  orElse: () => InwardItem(
                                      materialCode: '',
                                      materialDescription: '',
                                      unit: '',
                                      orderedQty: 0,
                                      receivedQty: 0,
                                      acceptedQty: 0,
                                      rejectedQty: 0,
                                      costPerUnit: '0'));

                              if (grnItem.materialCode.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                children:
                                    grnItem.prQuantities.entries.map((poEntry) {
                                  final poNo = poEntry.key;
                                  final prMap = poEntry.value;
                                  if (prMap == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('PO: $poNo',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      ...prMap.entries.map((prEntry) {
                                        final prNo = prEntry.key;
                                        final jobNo = grnItem.prJobNumbers[poNo]
                                                ?[prNo] ??
                                            'General';

                                        // Initialize controller if not exists
                                        _prQtyControllers[grnNo] ??= {};
                                        _prQtyControllers[grnNo]![
                                                '${poNo}_$prNo'] ??=
                                            TextEditingController(text: '0');

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              left: 16, bottom: 8),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('PR: $prNo'),
                                                    Text('Job: $jobNo',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[500])),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _prQtyControllers[
                                                      grnNo]!['${poNo}_$prNo'],
                                                  decoration: InputDecoration(
                                                    labelText: 'Accepted Qty',
                                                    border:
                                                        const OutlineInputBorder(),
                                                    isDense: true,
                                                    hintText:
                                                        'Max: ${grnQty.acceptedQty.toString()}',
                                                  ),
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                          decimal: true),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return null;
                                                    }
                                                    final qty =
                                                        double.tryParse(value);
                                                    if (qty == null) {
                                                      return 'Invalid number';
                                                    }
                                                    if (qty < 0) {
                                                      return 'Cannot be negative';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    // Validate total doesn't exceed accepted qty
                                                    double total = 0;
                                                    _prQtyControllers[grnNo]!
                                                        .forEach(
                                                            (key, controller) {
                                                      if (key !=
                                                          '${poNo}_$prNo') {
                                                        total += double.tryParse(
                                                                controller
                                                                    .text) ??
                                                            0;
                                                      }
                                                    });
                                                    total += double.tryParse(
                                                            value) ??
                                                        0;

                                                    if (total >
                                                        grnQty.acceptedQty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Total PR quantities cannot exceed accepted quantity'),
                                                        ),
                                                      );
                                                      _prQtyControllers[grnNo]![
                                                              '${poNo}_$prNo']!
                                                          .text = (grnQty
                                                                  .acceptedQty -
                                                              (total -
                                                                  (double.tryParse(
                                                                          value) ??
                                                                      0)))
                                                          .toString();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }).toList(),
                              );
                            }),
                          ],
                        ],

                        // Quality Parameters
                        const SizedBox(height: 16),
                        const Text('Quality Parameters',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 8),
                        ...firstItem.parameters.map((param) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(param.parameter),
                                ),
                                const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: param.observation,
                                    decoration: const InputDecoration(
                                      labelText: 'Observation',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        param.observation = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    value: param.result,
                                    decoration: const InputDecoration(
                                      labelText: 'Result',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    hint: const Text('Select'),
                                    items: const [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Select'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'OK',
                                        child: Text('OK'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'NOT OK',
                                        child: Text('NOT OK'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        param.result = value;
                                        param.isAcceptable = value == 'OK';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),

              // Add expiry date field after the GRN selection
              if (firstItem.grnQuantities.isNotEmpty)
                _buildExpiryDateField(firstItem),

              // Show sample size if calculated
              if (firstItem.sampleSize > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${firstItem.usageDecision == '100% Recheck' ? 'Required Lot Size' : 'Required Sample Size'}: ${firstItem.sampleSize.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExpiryDateField(InspectionItem item) {
    final categories = ref.watch(categoryListProvider);
    final category = categories.firstWhere(
      (c) => c.name == item.category,
      orElse: () => Category(name: item.category),
    );

    if (category.hasExpiryDate != true && category.hasShelfLife != true) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Expiry Date',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
          enabled: category.hasExpiryDate ==
              true, // Only enable if manual expiry date is needed
        ),
        initialValue: item.expirationDate,
        readOnly: true,
        onTap: category.hasExpiryDate != true
            ? null
            : () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    item.expirationDate = DateFormat('yyyy-MM-dd').format(date);
                  });
                }
              },
      ),
    );
  }

  // Validate if category parameters have changed since they were loaded
  Future<void> _validateParameterChanges(InspectionItem selectedItem) async {
    final categoryParams = ref.read(categoryParameterProvider);
    final currentMapping = categoryParams
        .where((mapping) => mapping.category == selectedItem.category)
        .firstOrNull;
    
    final loadedTimestamp = _categoryParameterTimestamps[selectedItem.category];
    final currentTimestamp = currentMapping?.lastModified ?? DateTime.now().toIso8601String();
    
    // Check if parameters have changed since they were loaded
    if (loadedTimestamp != null && loadedTimestamp != currentTimestamp) {
      // Parameters have changed - show dialog and force re-inspection
      final shouldReload = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Category Parameters Changed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The quality parameters for category "${selectedItem.category}" have been modified since this inspection was started.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'To ensure compliance, the inspection must be restarted with the updated parameters.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel Inspection'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reload with Updated Parameters'),
            ),
          ],
        ),
      );
      
      if (shouldReload == true) {
        // Reload all pending items with updated parameters
        _loadAllPendingItems();
        throw Exception('Inspection reloaded with updated parameters. Please restart the inspection process.');
      } else {
        throw Exception('Inspection cancelled due to parameter changes.');
      }
    }
  }

  // Helper method to determine inspection status
  String _determineInspectionStatus(InspectionItem item) {
    if (item.usageDecision == 'Lot Accepted') {
      return 'Completed - Accepted';
    } else if (item.usageDecision == 'Rejected') {
      return 'Completed - Rejected';
    } else if (item.usageDecision == 'Accepted After 100% Recheck') {
      return 'Completed - Accepted After 100% Recheck';
    } else if (item.usageDecision == 'Partially Accepted After 100% Recheck') {
      return 'Completed - Partially Accepted After 100% Recheck';
    } else {
      return 'Completed - ${item.usageDecision}';
    }
  }
}
