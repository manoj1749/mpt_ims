// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/material_request.dart';
import '../models/material_issue.dart';
import '../models/material_issue_item.dart';
import '../models/stock_maintenance.dart';
import 'base_provider.dart';
import 'stock_maintenance_provider.dart';
import 'material_request_provider.dart';

final materialIssueBoxProvider = Provider<Box<MaterialIssue>>((ref) {
  return Hive.box<MaterialIssue>('material_issues');
});

final materialIssueListProvider = Provider<List<MaterialIssue>>((ref) {
  final box = ref.watch(materialIssueBoxProvider);
  return box.values.toList();
});

// StateNotifier provider for backward compatibility
final materialIssueProvider = StateNotifierProvider<MaterialIssueNotifier, List<MaterialIssue>>((ref) {
  final issueBox = ref.watch(materialIssueBoxProvider);
  final requestBox = Hive.box<MaterialRequest>('material_requests');
  final stockBox = Hive.box<StockMaintenance>('stock_maintenance');
  return MaterialIssueNotifier(issueBox, requestBox, stockBox, ref);
});

class MaterialIssueNotifier extends BaseProvider<MaterialIssue> {
  final Box<MaterialRequest> _requestBox;
  final Box<StockMaintenance> _stockBox;
  final Ref ref;

  MaterialIssueNotifier(
      Box<MaterialIssue> issueBox, this._requestBox, this._stockBox, this.ref)
      : super(issueBox, 'material_issues');

  @override
  Map<String, dynamic> modelToMap(MaterialIssue issue) {
    return {
      'issueNo': issue.issueNo,
      'issueDate': issue.issueDate,
      'issuedTo': issue.issuedTo,
      'items': issue.items.map((item) => {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'mrDetails': item.mrDetails.map((key, value) => MapEntry(key, {
          'mrNo': value.mrNo,
          'jobNo': value.jobNo,
          'quantity': value.quantity,
          'prNo': value.prNo,
        })),
        'issuedQuantities': item.issuedQuantities,
        'prMapping': item.prMapping,
      }).toList(),
    };
  }

  @override
  MaterialIssue mapToModel(Map<String, dynamic> map) {
    return MaterialIssue(
      issueNo: map['issueNo'] ?? '',
      issueDate: map['issueDate'] ?? '',
      issuedTo: map['issuedTo'] ?? '',
      items: (map['items'] as List<dynamic>?)?.map((item) {
        final mrDetailsMap = <String, ItemMRDetails>{};
        if (item['mrDetails'] != null) {
          (item['mrDetails'] as Map<String, dynamic>).forEach((key, value) {
            mrDetailsMap[key] = ItemMRDetails(
              mrNo: value['mrNo'] ?? '',
              jobNo: value['jobNo'] ?? '',
              quantity: (value['quantity'] as num?)?.toDouble() ?? 0.0,
              prNo: value['prNo'],
            );
          });
        }

        return MaterialIssueItem(
          materialCode: item['materialCode'] ?? '',
          materialDescription: item['materialDescription'] ?? '',
          unit: item['unit'] ?? '',
          quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
          mrDetails: mrDetailsMap,
          issuedQuantities: Map<String, double>.from(item['issuedQuantities'] ?? {}),
          prMapping: Map<String, String>.from(item['prMapping'] ?? {}),
        );
      }).toList() ?? [],
    );
  }

  @override
  String getModelId(MaterialIssue issue) => issue.issueNo;

  // Override add method to update stock after issue
  @override
  Future<void> add(MaterialIssue issue) async {
    await super.add(issue);
    // Update stock after material issue is created
    await updateStockAfterIssue(issue);
    // Update material request status
    await updateMaterialRequestStatus(issue);
  }

  // Backward compatibility methods
  Future<void> loadMaterialIssues() => loadData();
  Future<void> addIssue(MaterialIssue issue) => add(issue);
  Future<void> createMaterialIssue(MaterialIssue issue) => add(issue);
  Future<void> updateIssue(MaterialIssue issue) => update(issue);
  Future<void> updateMaterialIssue(MaterialIssue issue) => update(issue);
  Future<bool> deleteIssue(MaterialIssue issue) => delete(issue);
  Future<bool> deleteMaterialIssue(String issueNo) async {
    final issue = getIssueByNo(issueNo);
    if (issue != null) {
      return await delete(issue);
    }
    return false;
  }

  // Search and filter methods
  List<MaterialIssue> searchIssues(String query) {
    return search(query, (issue, query) =>
        issue.issueNo.toLowerCase().contains(query) ||
        issue.issuedTo.toLowerCase().contains(query) ||
        issue.formattedJobNo.toLowerCase().contains(query));
  }

  List<MaterialIssue> getIssuesByDateRange(DateTime startDate, DateTime endDate) {
    return state.where((issue) {
      try {
        final issueDate = DateTime.parse(issue.issueDate);
        return issueDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               issueDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<MaterialIssue> getIssuesByDepartment(String department) {
    return state.where((issue) => 
        issue.issuedTo.toLowerCase() == department.toLowerCase()).toList();
  }

  List<MaterialIssue> getIssuesByJobNo(String jobNo) {
    return state.where((issue) => issue.jobNumbers.contains(jobNo)).toList();
  }

  MaterialIssue? getIssueByNo(String issueNo) {
    try {
      return state.firstWhere((issue) => issue.issueNo == issueNo);
    } catch (e) {
      return null;
    }
  }

  // Issue number generation
  String generateIssueNo() => generateIssueNumber();
  
  String generateIssueNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    
    // Find existing issues for current month
    final existingIssues = state.where((issue) {
      return issue.issueNo.startsWith('MI$year$month');
    }).toList();
    
    final nextNumber = existingIssues.length + 1;
    return 'MI$year$month${nextNumber.toString().padLeft(3, '0')}';
  }

  // Stock management methods
  Future<void> updateStockAfterIssue(MaterialIssue issue) async {
    print('\n=== Updating Stock After Material Issue ===');
    print('Issue No: ${issue.issueNo}');
    
    for (var item in issue.items) {
      print('\nProcessing item: ${item.materialCode} - Quantity: ${item.quantity}');
      
      final stockItems = _stockBox.values.where((stock) => 
          stock.materialCode == item.materialCode).toList();
      
      print('Found ${stockItems.length} stock records for ${item.materialCode}');
      
      for (var stock in stockItems) {
        // Use proper stock tracking for each job
        for (var mrDetail in item.mrDetails.values) {
          final jobNo = mrDetail.jobNo;
          final issueQty = mrDetail.quantity;
          
          print('Processing job: $jobNo, quantity: $issueQty');
          
          try {
            // Use the proper stock tracking method
            stock.issueStockForJob(jobNo, issue.issueNo, issueQty);
            print('Successfully issued stock for job $jobNo');
          } catch (e) {
            print('Error issuing stock for job $jobNo: $e');
            // Fallback to simple stock update if proper tracking fails
            if (stock.currentStock >= issueQty) {
              stock.currentStock -= issueQty;
              if (stock.jobDetails.containsKey(jobNo)) {
                stock.jobDetails[jobNo]!.consumedQuantity += issueQty;
              }
              print('Fallback: Updated current stock to: ${stock.currentStock}');
            } else {
              print('Insufficient stock for job $jobNo');
            }
          }
        }
        
        // Use StockMaintenanceNotifier to update stock (this ensures Firestore sync)
        final stockMaintenanceNotifier = ref.read(stockMaintenanceProvider.notifier);
        await stockMaintenanceNotifier.update(stock);
        print('Successfully updated stock for ${stock.materialCode}');
      }
    }
    print('=== End Stock Update After Material Issue ===\n');
  }

  // Material Request integration
  Future<void> updateMaterialRequestStatus(MaterialIssue issue) async {
    print('\n=== Updating Material Request Status ===');
    print('Issue No: ${issue.issueNo}');
    
    for (var item in issue.items) {
      print('\nProcessing item: ${item.materialCode}');
      
      for (var mrDetail in item.mrDetails.values) {
        final mrNo = mrDetail.mrNo;
        print('Updating MR: $mrNo for job: ${mrDetail.jobNo}');
        
        // Use material request provider to update status
        final materialRequestNotifier = ref.read(materialRequestProvider.notifier);
        final mr = materialRequestNotifier.state.where((request) => 
            request.issueNo == mrNo).firstOrNull;
        
        if (mr != null) {
          // Create updated MR with 'Issued' status
          final updatedMR = MaterialRequest(
            issueNo: mr.issueNo,
            date: mr.date,
            issuedBy: mr.issuedBy,
            status: 'Issued', // Update status to Issued
            items: mr.items,
            jobNo: mr.jobNo,
          );
          
          print('Updated MR $mrNo status to: ${updatedMR.status}');
          
          // Use material request provider to update
          await materialRequestNotifier.update(updatedMR);
          print('Successfully updated MR $mrNo');
          
          // Force refresh of material request data
          await materialRequestNotifier.loadData();
        } else {
          print('MR $mrNo not found');
        }
      }
    }
    print('=== End Material Request Status Update ===\n');
  }

  // Analytics methods
  Map<String, double> getMaterialUsageStats() {
    final usage = <String, double>{};
    
    for (var issue in state) {
      for (var item in issue.items) {
        usage[item.materialCode] = (usage[item.materialCode] ?? 0.0) + item.quantity;
      }
    }
    
    return usage;
  }

  Map<String, double> getDepartmentUsageStats() {
    final usage = <String, double>{};
    
    for (var issue in state) {
      double totalValue = 0.0;
      for (var item in issue.items) {
        // Assuming we have a way to get material rate
        totalValue += item.quantity; // This could be multiplied by rate
      }
      usage[issue.issuedTo] = (usage[issue.issuedTo] ?? 0.0) + totalValue;
    }
    
    return usage;
  }

  Map<String, int> getJobWiseIssueCount() {
    final jobCount = <String, int>{};
    
    for (var issue in state) {
      for (var jobNo in issue.jobNumbers) {
        jobCount[jobNo] = (jobCount[jobNo] ?? 0) + 1;
      }
    }
    
    return jobCount;
  }

  // Validation methods
  bool canIssueQuantity(String materialCode, double requestedQuantity) {
    final availableStock = _stockBox.values
        .where((stock) => stock.materialCode == materialCode)
        .fold(0.0, (sum, stock) => sum + stock.currentStock);
    
    return availableStock >= requestedQuantity;
  }

  List<String> validateIssue(MaterialIssue issue) {
    final errors = <String>[];
    
    // Check if issue number already exists
    if (state.any((existingIssue) => existingIssue.issueNo == issue.issueNo)) {
      errors.add('Issue number ${issue.issueNo} already exists');
    }
    
    // Check stock availability for each item
    for (var item in issue.items) {
      if (!canIssueQuantity(item.materialCode, item.quantity)) {
        errors.add('Insufficient stock for ${item.materialDescription}');
      }
    }
    
    return errors;
  }
}
