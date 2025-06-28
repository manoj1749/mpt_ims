import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sync_status_widget.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/universal_parameter.dart';
import '../models/category_parameter_mapping.dart';
import '../models/material_item.dart';
import '../models/sale_order.dart';
import '../models/purchase_request.dart';
import '../models/pr_item.dart';
import '../models/purchase_order.dart';
import '../models/po_item.dart';
import '../models/store_inward.dart';
import '../models/quality_inspection.dart';
import '../models/material_request.dart';
import '../models/material_request_item.dart';
import '../models/material_issue.dart';
import '../models/material_issue_item.dart';
import '../models/stock_maintenance.dart';
import '../models/delivery_challan.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  SyncService(this._ref);

  // Generic method to sync data from Hive to Firestore
  Future<void> syncToFirestore<T>(String collection, Box<T> box) async {
    try {
      final status = 'Syncing $collection to Firestore...';
      print('\n=== FIREBASE SYNC STATUS ===');
      print(status);
      _ref.read(syncStatusProvider.notifier).state = status;
      _ref.read(syncErrorProvider.notifier).state = null;

      final batch = _firestore.batch();
      final collectionRef = _firestore.collection(collection);

      // First, mark all existing documents for deletion
      final existingDocs = await collectionRef.get();
      print('Found ${existingDocs.docs.length} existing documents in $collection');
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Then add all current documents
      print('Preparing to sync ${box.values.length} items from Hive');
      if (box.values.isNotEmpty) {
        for (var item in box.values) {
          final docRef = collectionRef.doc();
          final data = _convertToMap(item);
          data['lastUpdated'] = FieldValue.serverTimestamp();
          data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
          batch.set(docRef, data);
        }

        // Only commit if there are items to sync
        await batch.commit();
      } else {
        print('No items in Hive box to sync');
      }

      final successStatus = 'Successfully synced $collection to Firestore';
      print(successStatus);
      print('=== END SYNC STATUS ===\n');
      _ref.read(syncStatusProvider.notifier).state = successStatus;
      
      // Clear status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _ref.read(syncStatusProvider.notifier).state = null;
      });
    } catch (e) {
      final errorMsg = 'Error syncing $collection to Firestore: $e';
      print('\n=== FIREBASE SYNC ERROR ===');
      print(errorMsg);
      print('=== END SYNC ERROR ===\n');
      _ref.read(syncErrorProvider.notifier).state = 'Error syncing $collection: $e';
      
      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _ref.read(syncErrorProvider.notifier).state = null;
      });
      rethrow;
    }
  }

  // Generic method to sync data from Firestore to Hive
  Future<void> syncFromFirestore<T>(String collection, Box<T> box, T Function(Map<String, dynamic>) fromMap) async {
    try {
      final status = 'Syncing $collection from Firestore...';
      print('\n=== FIREBASE SYNC STATUS ===');
      print(status);
      _ref.read(syncStatusProvider.notifier).state = status;
      _ref.read(syncErrorProvider.notifier).state = null;

      final querySnapshot = await _firestore.collection(collection).get();
      print('Found ${querySnapshot.docs.length} documents in Firestore');

      // Only clear and sync if there are documents in Firestore
      if (querySnapshot.docs.isNotEmpty) {
        print('Clearing existing data from Hive box: $collection');
        await box.clear();
        
        print('Starting to sync items to Hive');
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final item = fromMap(data);
          await box.add(item);
        }
      } else {
        print('No documents found in Firestore, keeping existing Hive data');
      }

      final successStatus = 'Successfully synced $collection from Firestore';
      print(successStatus);
      print('=== END SYNC STATUS ===\n');
      _ref.read(syncStatusProvider.notifier).state = successStatus;
      
      // Clear status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _ref.read(syncStatusProvider.notifier).state = null;
      });
    } catch (e) {
      final errorMsg = 'Error syncing $collection from Firestore: $e';
      print('\n=== FIREBASE SYNC ERROR ===');
      print(errorMsg);
      print('=== END SYNC ERROR ===\n');
      _ref.read(syncErrorProvider.notifier).state = 'Error syncing $collection: $e';
      
      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _ref.read(syncErrorProvider.notifier).state = null;
      });
      rethrow;
    }
  }

  // Convert Hive objects to Map
  Map<String, dynamic> _convertToMap(dynamic item) {
    if (item is Supplier) {
      return {
        'name': item.name,
        'contact': item.contact,
        'phone': item.phone,
        'email': item.email,
        'vendorCode': item.vendorCode,
        'address1': item.address1,
        'address2': item.address2,
        'address3': item.address3,
        'address4': item.address4,
        'state': item.state,
        'stateCode': item.stateCode,
        'paymentTerms': item.paymentTerms,
        'pan': item.pan,
        'gstNo': item.gstNo,
        'igst': item.igst,
        'cgst': item.cgst,
        'sgst': item.sgst,
        'totalGst': item.totalGst,
        'bank': item.bank,
        'branch': item.branch,
        'account': item.account,
        'ifsc': item.ifsc,
        'email1': item.email1,
      };
    } else if (item is Customer) {
      return {
        'name': item.name,
        'address1': item.address1,
        'address2': item.address2,
        'address3': item.address3,
        'address4': item.address4,
        'gstNo': item.gstNo,
        'email': item.email,
        'contact': item.contact,
        'paymentTerms': item.paymentTerms,
        'phone': item.phone,
        'customerCode': item.customerCode,
        'state': item.state,
        'stateCode': item.stateCode,
        'pan': item.pan,
        'igst': item.igst,
        'cgst': item.cgst,
        'sgst': item.sgst,
        'totalGst': item.totalGst,
        'bank': item.bank,
        'branch': item.branch,
        'account': item.account,
        'ifsc': item.ifsc,
        'email1': item.email1,
      };
    } else if (item is Category) {
      return {
        'name': item.name,
        'requiresQualityCheck': item.requiresQualityCheck,
        'sampleSizeLessThan100': item.sampleSizeLessThan100,
        'sampleSize100To500': item.sampleSize100To500,
        'sampleSizeGreaterThan500': item.sampleSizeGreaterThan500,
        'hasExpiryDate': item.hasExpiryDate,
        'hasShelfLife': item.hasShelfLife,
        'shelfLifeValue': item.shelfLifeValue,
        'shelfLifeUnit': item.shelfLifeUnit,
      };
    } else if (item is SubCategory) {
      return {
        'name': item.name,
        'categoryName': item.categoryName,
      };
    } else if (item is UniversalParameter) {
      return {
        'name': item.name,
      };
    } else if (item is CategoryParameterMapping) {
      return {
        'category': item.category,
        'parameters': item.parameters,
        'requiresExpiryDate': item.requiresExpiryDate,
      };
    } else if (item is MaterialItem) {
      return {
        'slNo': item.slNo,
        'description': item.description,
        'partNo': item.partNo,
        'unit': item.unit,
        'category': item.category,
        'subCategory': item.subCategory,
        'storageLocation': item.storageLocation,
        'rackNumber': item.rackNumber,
        'actualWeight': item.actualWeight,
      };
    } else if (item is SaleOrder) {
      return {
        'orderNo': item.orderNo,
        'orderDate': item.orderDate,
        'customerName': item.customerName,
        'boardNo': item.boardNo,
        'jobStartDate': item.jobStartDate,
        'targetDate': item.targetDate,
        'endDate': item.endDate,
      };
    } else if (item is PurchaseRequest) {
      return {
        'prNo': item.prNo,
        'date': item.date,
        'requiredBy': item.requiredBy,
        'status': item.status,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
        'jobNo': item.jobNo,
      };
    } else if (item is PRItem) {
      return {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'orderedQuantities': item.orderedQuantities,
        'prNo': item.prNo,
        'totalReceivedQuantity': item.totalReceivedQuantity,
      };
    } else if (item is PurchaseOrder) {
      return {
        'poNo': item.poNo,
        'poDate': item.poDate,
        'supplierName': item.supplierName,
        'transport': item.transport,
        'deliveryRequirements': item.deliveryRequirements,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
        'total': item.total,
        'igst': item.igst,
        'cgst': item.cgst,
        'sgst': item.sgst,
        'grandTotal': item.grandTotal,
        'status': item.status,
      };
    } else if (item is POItem) {
      return {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'costPerUnit': item.costPerUnit,
        'totalCost': item.totalCost,
        'saleRate': item.saleRate,
        'marginPerUnit': item.marginPerUnit,
        'totalMargin': item.totalMargin,
        'prDetails': item.prDetails.map((key, value) => MapEntry(key, {
              'prNo': value.prNo,
              'jobNo': value.jobNo,
              'quantity': value.quantity,
            })),
        'receivedQuantities': item.receivedQuantities,
      };
    } else if (item is StoreInward) {
      return {
        'grnNo': item.grnNo,
        'grnDate': item.grnDate,
        'supplierName': item.supplierName,
        'poNo': item.poNo,
        'poDate': item.poDate,
        'invoiceNo': item.invoiceNo,
        'invoiceDate': item.invoiceDate,
        'invoiceAmount': item.invoiceAmount,
        'receivedBy': item.receivedBy,
        'checkedBy': item.checkedBy,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
        'status': item.status,
      };
    } else if (item is InwardItem) {
      return {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'orderedQty': item.orderedQty,
        'receivedQty': item.receivedQty,
        'acceptedQty': item.acceptedQty,
        'rejectedQty': item.rejectedQty,
        'costPerUnit': item.costPerUnit,
        'prQuantities': item.prQuantities,
        'inspectionStatus': item.inspectionStatus.map((key, value) => MapEntry(key, {
              'inspectedQty': value.inspectedQty,
              'acceptedQty': value.acceptedQty,
              'rejectedQty': value.rejectedQty,
              'status': value.status,
            })),
        'prJobNumbers': item.prJobNumbers,
      };
    } else if (item is QualityInspection) {
      return {
        'inspectionNo': item.inspectionNo,
        'inspectionDate': item.inspectionDate,
        'grnNo': item.grnNo,
        'supplierName': item.supplierName,
        'poNo': item.poNo,
        'billNo': item.billNo,
        'billDate': item.billDate,
        'receivedDate': item.receivedDate,
        'grnDate': item.grnDate,
        'inspectedBy': item.inspectedBy,
        'approvedBy': item.approvedBy,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
        'status': item.status,
        'prNumbers': item.prNumbers,
        'jobNumbers': item.jobNumbers,
        'capaNo': item.capaNo,
        'capaStatus': item.capaStatus,
        'capaDescription': item.capaDescription,
        'capaAssignedTo': item.capaAssignedTo,
        'capaTargetDate': item.capaTargetDate,
        'capaCompletionDate': item.capaCompletionDate,
        'capaActions': item.capaActions,
      };
    } else if (item is InspectionItem) {
      return {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'category': item.category,
        'receivedQty': item.receivedQty,
        'costPerUnit': item.costPerUnit,
        'totalCost': item.totalCost,
        'sampleSize': item.sampleSize,
        'inspectedQty': item.inspectedQty,
        'acceptedQty': item.acceptedQty,
        'rejectedQty': item.rejectedQty,
        'pendingQty': item.pendingQty,
        'usageDecision': item.usageDecision,
        'receivedDate': item.receivedDate,
        'expirationDate': item.expirationDate,
        'parameters': item.parameters.map((p) => _convertToMap(p)).toList(),
        'isPartialRecheck': item.isPartialRecheck,
        'poQuantities': item.poQuantities.map((key, value) => MapEntry(key, {
              'receivedQty': value.receivedQty,
              'acceptedQty': value.acceptedQty,
              'rejectedQty': value.rejectedQty,
              'usageDecision': value.usageDecision,
              'recheckType': value.recheckType,
              'conditionalAcceptance': value.conditionalAcceptance,
            })),
        'grnNo': item.grnNo,
        'grnDate': item.grnDate,
        'invoiceNo': item.invoiceNo,
        'invoiceDate': item.invoiceDate,
        'grnDetails': item.grnDetails,
        'grnQuantities': item.grnQuantities.map((key, value) => MapEntry(key, {
              'receivedQty': value.receivedQty,
              'acceptedQty': value.acceptedQty,
              'rejectedQty': value.rejectedQty,
              'usageDecision': value.usageDecision,
              'poNo': value.poNo,
              'poDate': value.poDate,
              'recheckType': value.recheckType,
              'isSelected': value.isSelected,
            })),
        'inspectionRemark': item.inspectionRemark,
        'capaRequired': item.capaRequired,
        'recheckType': item.recheckType,
        'conditionalAcceptance': item.conditionalAcceptance,
      };
    } else if (item is QualityParameter) {
      return {
        'parameter': item.parameter,
        'isAcceptable': item.isAcceptable,
        'observation': item.observation,
        'result': item.result,
      };
    } else if (item is MaterialRequest) {
      return {
        'issueNo': item.issueNo,
        'date': item.date,
        'issuedBy': item.issuedBy,
        'status': item.status,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
        'jobNo': item.jobNo,
      };
    } else if (item is MaterialRequestItem) {
      return {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'quantity': item.quantity,
        'issueNo': item.issueNo,
        'issuedQuantities': item.issuedQuantities,
      };
    } else if (item is MaterialIssue) {
      return {
        'issueNo': item.issueNo,
        'issueDate': item.issueDate,
        'issuedTo': item.issuedTo,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
      };
    } else if (item is MaterialIssueItem) {
      return {
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
      };
    } else if (item is StockMaintenance) {
      return {
        'materialCode': item.materialCode,
        'materialDescription': item.materialDescription,
        'unit': item.unit,
        'currentStock': item.currentStock,
        'stockUnderInspection': item.stockUnderInspection,
        'storageLocation': item.storageLocation,
        'rackNumber': item.rackNumber,
        'grnDetails': item.grnDetails.map((key, value) => MapEntry(key, {
              'grnNo': value.grnNo,
              'grnDate': value.grnDate,
              'receivedQuantity': value.receivedQuantity,
              'acceptedQuantity': value.acceptedQuantity,
              'rejectedQuantity': value.rejectedQuantity,
              'vendorId': value.vendorId,
              'rate': value.rate,
            })),
        'poDetails': item.poDetails.map((key, value) => MapEntry(key, {
              'poNo': value.poNo,
              'poDate': value.poDate,
              'orderedQuantity': value.orderedQuantity,
              'receivedQuantity': value.receivedQuantity,
              'vendorId': value.vendorId,
              'rate': value.rate,
            })),
      };
    } else if (item is DeliveryChallan) {
      return {
        'dcNo': item.dcNo,
        'dcDate': item.dcDate,
        'vendorName': item.vendorName,
        'isReturnable': item.isReturnable,
        'items': item.items.map((i) => _convertToMap(i)).toList(),
      };
    } else {
      throw Exception('Unsupported type for conversion: ${item.runtimeType}');
    }
  }

  // Convert Map to Hive objects
  Supplier supplierFromMap(Map<String, dynamic> map) {
    return Supplier(
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      vendorCode: map['vendorCode'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'] ?? '',
      address3: map['address3'] ?? '',
      address4: map['address4'] ?? '',
      state: map['state'] ?? '',
      stateCode: map['stateCode'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      pan: map['pan'] ?? '',
      gstNo: map['gstNo'] ?? '',
      igst: map['igst'] ?? '',
      cgst: map['cgst'] ?? '',
      sgst: map['sgst'] ?? '',
      totalGst: map['totalGst'] ?? '',
      bank: map['bank'] ?? '',
      branch: map['branch'] ?? '',
      account: map['account'] ?? '',
      ifsc: map['ifsc'] ?? '',
      email1: map['email1'] ?? '',
    );
  }

  Customer customerFromMap(Map<String, dynamic> map) {
    return Customer(
      name: map['name'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'] ?? '',
      address3: map['address3'] ?? '',
      address4: map['address4'] ?? '',
      gstNo: map['gstNo'] ?? '',
      email: map['email'] ?? '',
      contact: map['contact'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      phone: map['phone'] ?? '',
      customerCode: map['customerCode'] ?? '',
      state: map['state'] ?? '',
      stateCode: map['stateCode'] ?? '',
      pan: map['pan'] ?? '',
      igst: map['igst'] ?? '',
      cgst: map['cgst'] ?? '',
      sgst: map['sgst'] ?? '',
      totalGst: map['totalGst'] ?? '',
      bank: map['bank'] ?? '',
      branch: map['branch'] ?? '',
      account: map['account'] ?? '',
      ifsc: map['ifsc'] ?? '',
      email1: map['email1'] ?? '',
    );
  }

  Category categoryFromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'] ?? '',
      requiresQualityCheck: map['requiresQualityCheck'] ?? true,
      sampleSizeLessThan100: map['sampleSizeLessThan100'],
      sampleSize100To500: map['sampleSize100To500'],
      sampleSizeGreaterThan500: map['sampleSizeGreaterThan500'],
      hasExpiryDate: map['hasExpiryDate'],
      hasShelfLife: map['hasShelfLife'],
      shelfLifeValue: map['shelfLifeValue'],
      shelfLifeUnit: map['shelfLifeUnit'],
    );
  }

  SubCategory subCategoryFromMap(Map<String, dynamic> map) {
    return SubCategory(
      name: map['name'] ?? '',
      categoryName: map['categoryName'] ?? '',
    );
  }

  UniversalParameter universalParameterFromMap(Map<String, dynamic> map) {
    return UniversalParameter(
      name: map['name'] ?? '',
    );
  }

  CategoryParameterMapping categoryParameterMappingFromMap(Map<String, dynamic> map) {
    return CategoryParameterMapping(
      category: map['category'] ?? '',
      parameters: List<String>.from(map['parameters'] ?? []),
      requiresExpiryDate: map['requiresExpiryDate'] ?? false,
    );
  }

  MaterialItem materialFromMap(Map<String, dynamic> map) {
    return MaterialItem(
      slNo: map['slNo'] ?? '',
      description: map['description'] ?? '',
      partNo: map['partNo'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      storageLocation: map['storageLocation'],
      rackNumber: map['rackNumber'],
      actualWeight: map['actualWeight'],
    );
  }

  SaleOrder saleOrderFromMap(Map<String, dynamic> map) {
    return SaleOrder(
      orderNo: map['orderNo'] ?? '',
      orderDate: map['orderDate'] ?? '',
      customerName: map['customerName'] ?? '',
      boardNo: map['boardNo'] ?? '',
      jobStartDate: map['jobStartDate'] ?? '',
      targetDate: map['targetDate'] ?? '',
      endDate: map['endDate'],
    );
  }

  PurchaseRequest purchaseRequestFromMap(Map<String, dynamic> map) {
    return PurchaseRequest(
      prNo: map['prNo'] ?? '',
      date: map['date'] ?? '',
      requiredBy: map['requiredBy'] ?? '',
      status: map['status'],
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => prItemFromMap(i as Map<String, dynamic>))
          .toList(),
      jobNo: map['jobNo'],
    );
  }

  PRItem prItemFromMap(Map<String, dynamic> map) {
    return PRItem(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? '',
      prNo: map['prNo'] ?? '',
      orderedQuantities: (map['orderedQuantities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toDouble()),
          ) ??
          {},
      totalReceivedQuantity: (map['totalReceivedQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  POItem poItemFromMap(Map<String, dynamic> map) {
    return POItem(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity']?.toString() ?? '0',
      costPerUnit: map['costPerUnit']?.toString() ?? '0',
      totalCost: map['totalCost']?.toString() ?? '0',
      saleRate: map['saleRate']?.toString() ?? '0',
      marginPerUnit: map['marginPerUnit']?.toString() ?? '0',
      totalMargin: map['totalMargin']?.toString() ?? '0',
      prDetails: (map['prDetails'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          ItemPRDetails(
            prNo: value['prNo']?.toString() ?? '',
            jobNo: value['jobNo']?.toString() ?? 'General',
            quantity: (value['quantity'] as num?)?.toDouble() ?? 0.0,
          ),
        ),
      ),
      receivedQuantities: (map['receivedQuantities'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        ),
      ),
    );
  }

  PurchaseOrder purchaseOrderFromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      poNo: map['poNo'] ?? '',
      poDate: map['poDate'] ?? '',
      supplierName: map['supplierName'] ?? '',
      transport: map['transport'] ?? '',
      deliveryRequirements: map['deliveryRequirements'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => poItemFromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      igst: (map['igst'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      status: map['status'],
    );
  }

  StoreInward storeInwardFromMap(Map<String, dynamic> map) {
    return StoreInward(
      grnNo: map['grnNo'] ?? '',
      grnDate: map['grnDate'] ?? '',
      supplierName: map['supplierName'] ?? '',
      poNo: map['poNo'] ?? '',
      poDate: map['poDate'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      invoiceDate: map['invoiceDate'] ?? '',
      invoiceAmount: StoreInward.parseInvoiceAmount(map['invoiceAmount']),
      receivedBy: map['receivedBy'] ?? '',
      checkedBy: map['checkedBy'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => InwardItem(
                materialCode: i['materialCode'] ?? '',
                materialDescription: i['materialDescription'] ?? '',
                unit: i['unit'] ?? '',
                orderedQty: (i['orderedQty'] as num?)?.toDouble() ?? 0.0,
                receivedQty: (i['receivedQty'] as num?)?.toDouble() ?? 0.0,
                acceptedQty: (i['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                rejectedQty: (i['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                costPerUnit: i['costPerUnit']?.toString() ?? '0',
                prQuantities: (i['prQuantities'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    (value as Map<String, dynamic>).map(
                      (k, v) => MapEntry(k, (v as num).toDouble()),
                    ),
                  ),
                ),
                inspectionStatus: (i['inspectionStatus'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    InspectionQuantityStatus(
                      inspectedQty: (value['inspectedQty'] as num?)?.toDouble() ?? 0.0,
                      acceptedQty: (value['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                      rejectedQty: (value['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                      status: value['status'] ?? 'Pending',
                    ),
                  ),
                ),
                prJobNumbers: (i['prJobNumbers'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    (value as Map<String, dynamic>).map(
                      (k, v) => MapEntry(k, v.toString()),
                    ),
                  ),
                ),
              ))
          .toList() ?? [],
      status: map['status'],
    );
  }

  InwardItem inwardItemFromMap(Map<String, dynamic> map) {
    return InwardItem(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      orderedQty: (map['orderedQty'] as num?)?.toDouble() ?? 0.0,
      receivedQty: (map['receivedQty'] as num?)?.toDouble() ?? 0.0,
      acceptedQty: (map['acceptedQty'] as num?)?.toDouble() ?? 0.0,
      rejectedQty: (map['rejectedQty'] as num?)?.toDouble() ?? 0.0,
      costPerUnit: map['costPerUnit'] ?? '',
      prQuantities: InwardItem.castPRQuantities(map['prQuantities']),
      inspectionStatus: (map['inspectionStatus'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              InspectionQuantityStatus(
                inspectedQty: (value['inspectedQty'] as num?)?.toDouble() ?? 0.0,
                acceptedQty: (value['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                rejectedQty: (value['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                status: value['status'] ?? 'Pending',
              ),
            ),
          ) ??
          {},
      prJobNumbers: InwardItem.castPRJobNumbers(map['prJobNumbers']),
    );
  }

  QualityInspection qualityInspectionFromMap(Map<String, dynamic> map) {
    return QualityInspection(
      inspectionNo: map['inspectionNo'] ?? '',
      inspectionDate: map['inspectionDate'] ?? '',
      grnNo: map['grnNo'] ?? '',
      supplierName: map['supplierName'] ?? '',
      poNo: map['poNo'] ?? '',
      billNo: map['billNo'] ?? '',
      billDate: map['billDate'] ?? '',
      receivedDate: map['receivedDate'] ?? '',
      grnDate: map['grnDate'] ?? '',
      inspectedBy: map['inspectedBy'] ?? '',
      approvedBy: map['approvedBy'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => InspectionItem(
                materialCode: i['materialCode'] ?? '',
                materialDescription: i['materialDescription'] ?? '',
                unit: i['unit'] ?? '',
                category: i['category'] ?? '',
                receivedQty: (i['receivedQty'] as num?)?.toDouble() ?? 0.0,
                costPerUnit: (i['costPerUnit'] as num?)?.toDouble() ?? 0.0,
                totalCost: (i['totalCost'] as num?)?.toDouble() ?? 0.0,
                sampleSize: (i['sampleSize'] as num?)?.toDouble() ?? 0.0,
                inspectedQty: (i['inspectedQty'] as num?)?.toDouble() ?? 0.0,
                acceptedQty: (i['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                rejectedQty: (i['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                pendingQty: (i['pendingQty'] as num?)?.toDouble() ?? 0.0,
                usageDecision: i['usageDecision'] ?? 'Lot Accepted',
                receivedDate: i['receivedDate'] ?? '',
                expirationDate: i['expirationDate'] ?? '',
                parameters: (i['parameters'] as List<dynamic>?)
                    ?.map((p) => QualityParameter(
                          parameter: p['parameter'] ?? '',
                          isAcceptable: p['isAcceptable'] ?? true,
                          observation: p['observation'] ?? '',
                          result: p['result'] ?? 'OK',
                        ))
                    .toList() ?? [],
                isPartialRecheck: i['isPartialRecheck'],
                poQuantities: (i['poQuantities'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    InspectionPOQuantity(
                      receivedQty: (value['receivedQty'] as num?)?.toDouble() ?? 0.0,
                      acceptedQty: (value['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                      rejectedQty: (value['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                      usageDecision: value['usageDecision'] ?? 'Lot Accepted',
                      recheckType: value['recheckType'],
                      conditionalAcceptance: value['conditionalAcceptance'],
                    ),
                  ),
                ),
                grnNo: i['grnNo'],
                grnDate: i['grnDate'],
                invoiceNo: i['invoiceNo'],
                invoiceDate: i['invoiceDate'],
                grnDetails: (i['grnDetails'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    (value as Map<String, dynamic>).map(
                      (k, v) => MapEntry(k, v.toString()),
                    ),
                  ),
                ),
                grnQuantities: (i['grnQuantities'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    InspectionGRNQuantity(
                      receivedQty: (value['receivedQty'] as num?)?.toDouble() ?? 0.0,
                      acceptedQty: (value['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                      rejectedQty: (value['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                      usageDecision: value['usageDecision'] ?? 'Lot Accepted',
                      poNo: value['poNo'],
                      poDate: value['poDate'],
                      recheckType: value['recheckType'],
                      isSelected: value['isSelected'],
                    ),
                  ),
                ),
                inspectionRemark: i['inspectionRemark'],
                recheckType: i['recheckType'],
                conditionalAcceptance: i['conditionalAcceptance'],
                capaRequired: i['capaRequired'],
              ))
          .toList() ?? [],
      status: map['status'] ?? 'Pending',
      prNumbers: (map['prNumbers'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      jobNumbers: (map['jobNumbers'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      capaNo: map['capaNo'],
      capaStatus: map['capaStatus'] ?? 'Not Required',
      capaDescription: map['capaDescription'],
      capaAssignedTo: map['capaAssignedTo'],
      capaTargetDate: map['capaTargetDate'],
      capaCompletionDate: map['capaCompletionDate'],
      capaActions: (map['capaActions'] as List<dynamic>?)
          ?.map((a) => a.toString())
          .toList(),
    );
  }

  InspectionItem inspectionItemFromMap(Map<String, dynamic> map) {
    return InspectionItem(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      receivedQty: (map['receivedQty'] as num?)?.toDouble() ?? 0.0,
      costPerUnit: (map['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      sampleSize: (map['sampleSize'] as num?)?.toDouble() ?? 0.0,
      inspectedQty: (map['inspectedQty'] as num?)?.toDouble() ?? 0.0,
      acceptedQty: (map['acceptedQty'] as num?)?.toDouble() ?? 0.0,
      rejectedQty: (map['rejectedQty'] as num?)?.toDouble() ?? 0.0,
      pendingQty: (map['pendingQty'] as num?)?.toDouble() ?? 0.0,
      usageDecision: map['usageDecision'] ?? 'Lot Accepted',
      receivedDate: map['receivedDate'] ?? '',
      expirationDate: map['expirationDate'] ?? '',
      parameters: (map['parameters'] as List<dynamic>?)
          ?.map((p) => qualityParameterFromMap(p as Map<String, dynamic>))
          .toList() ??
          [],
      isPartialRecheck: map['isPartialRecheck'],
      poQuantities: (map['poQuantities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              InspectionPOQuantity(
                receivedQty: (value['receivedQty'] as num?)?.toDouble() ?? 0.0,
                acceptedQty: (value['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                rejectedQty: (value['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                usageDecision: value['usageDecision'] ?? 'Lot Accepted',
                recheckType: value['recheckType'],
                conditionalAcceptance: value['conditionalAcceptance'],
              ),
            ),
          ) ??
          {},
      grnNo: map['grnNo'],
      grnDate: map['grnDate'],
      invoiceNo: map['invoiceNo'],
      invoiceDate: map['invoiceDate'],
      grnDetails: (map['grnDetails'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v.toString()),
              ),
            ),
          ) ??
          {},
      grnQuantities: (map['grnQuantities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              InspectionGRNQuantity(
                receivedQty: (value['receivedQty'] as num?)?.toDouble() ?? 0.0,
                acceptedQty: (value['acceptedQty'] as num?)?.toDouble() ?? 0.0,
                rejectedQty: (value['rejectedQty'] as num?)?.toDouble() ?? 0.0,
                usageDecision: value['usageDecision'] ?? 'Lot Accepted',
                poNo: value['poNo'],
                poDate: value['poDate'],
                recheckType: value['recheckType'],
                isSelected: value['isSelected'] ?? false,
              ),
            ),
          ) ??
          {},
      inspectionRemark: map['inspectionRemark'],
      capaRequired: map['capaRequired'],
      recheckType: map['recheckType'],
      conditionalAcceptance: map['conditionalAcceptance'],
    );
  }

  QualityParameter qualityParameterFromMap(Map<String, dynamic> map) {
    return QualityParameter(
      parameter: map['parameter'] ?? '',
      isAcceptable: map['isAcceptable'] ?? true,
      observation: map['observation'] ?? '',
      result: map['result'],
    );
  }

  MaterialRequest materialRequestFromMap(Map<String, dynamic> map) {
    return MaterialRequest(
      issueNo: map['issueNo'] ?? '',
      date: map['date'] ?? '',
      issuedBy: map['issuedBy'] ?? '',
      status: map['status'],
      jobNo: map['jobNo'],
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => MaterialRequestItem(
                materialCode: i['materialCode'] ?? '',
                materialDescription: i['materialDescription'] ?? '',
                unit: i['unit'] ?? '',
                quantity: i['quantity']?.toString() ?? '0',
                issueNo: i['issueNo'] ?? '',
                issuedQuantities: (i['issuedQuantities'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ),
              ))
          .toList() ?? [],
    );
  }

  MaterialRequestItem materialRequestItemFromMap(Map<String, dynamic> map) {
    return MaterialRequestItem(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? '',
      issueNo: map['issueNo'] ?? '',
      issuedQuantities: (map['issuedQuantities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
    );
  }

  MaterialIssue materialIssueFromMap(Map<String, dynamic> map) {
    return MaterialIssue(
      issueNo: map['issueNo'] ?? '',
      issueDate: map['issueDate'] ?? '',
      issuedTo: map['issuedTo'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => MaterialIssueItem(
                materialCode: i['materialCode'] ?? '',
                materialDescription: i['materialDescription'] ?? '',
                unit: i['unit'] ?? '',
                quantity: (i['quantity'] as num?)?.toDouble() ?? 0.0,
                mrDetails: (i['mrDetails'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                    key,
                    ItemMRDetails(
                      mrNo: value['mrNo'] ?? '',
                      jobNo: value['jobNo'] ?? '',
                      quantity: (value['quantity'] as num?)?.toDouble() ?? 0.0,
                      prNo: value['prNo'],
                    ),
                  ),
                ) ?? {},
                issuedQuantities: (i['issuedQuantities'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ) ?? {},
                prMapping: (i['prMapping'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(key, value.toString()),
                ) ?? {},
              ))
          .toList() ?? [],
    );
  }

  DeliveryChallan deliveryChallanFromMap(Map<String, dynamic> map) {
    return DeliveryChallan(
      dcNo: map['dcNo'] ?? '',
      dcDate: map['dcDate'] ?? '',
      vendorName: map['vendorName'] ?? '',
      isReturnable: map['isReturnable'] ?? false,
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => DeliveryChallanItem(
                materialCode: i['materialCode'] ?? '',
                materialDescription: i['materialDescription'] ?? '',
                unit: i['unit'] ?? '',
                quantity: (i['quantity'] as num?)?.toDouble() ?? 0.0,
                jobNo: i['jobNo'],
                prNo: i['prNo'],
              ))
          .toList() ?? [],
    );
  }

  StockMaintenance stockMaintenanceFromMap(Map<String, dynamic> map) {
    return StockMaintenance(
      materialCode: map['materialCode'] ?? '',
      materialDescription: map['materialDescription'] ?? '',
      unit: map['unit'] ?? '',
      storageLocation: map['storageLocation'] ?? '',
      rackNumber: map['rackNumber'] ?? '',
    )
      ..currentStock = (map['currentStock'] as num?)?.toDouble() ?? 0.0
      ..stockUnderInspection = (map['stockUnderInspection'] as num?)?.toDouble() ?? 0.0
      ..grnDetails = (map['grnDetails'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              StockGRNDetails(
                grnNo: value['grnNo'] ?? '',
                grnDate: value['grnDate'] ?? '',
                receivedQuantity: (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
                acceptedQuantity: (value['acceptedQuantity'] as num?)?.toDouble() ?? 0.0,
                rejectedQuantity: (value['rejectedQuantity'] as num?)?.toDouble() ?? 0.0,
                vendorId: value['vendorId'] ?? '',
                rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              ),
            ),
          ) ??
          {}
      ..poDetails = (map['poDetails'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              StockPODetails(
                poNo: value['poNo'] ?? '',
                poDate: value['poDate'] ?? '',
                orderedQuantity: (value['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
                receivedQuantity: (value['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
                vendorId: value['vendorId'] ?? '',
                rate: (value['rate'] as num?)?.toDouble() ?? 0.0,
              ),
            ),
          ) ??
          {};
  }

  Future<void> syncAllData() async {
    try {
      _ref.read(syncStatusProvider.notifier).state = 'Starting full sync...';
      _ref.read(syncErrorProvider.notifier).state = null;

      print('\n=== STARTING FULL SYNC ===');

      // Sync suppliers
      if (Hive.isBoxOpen('suppliers')) {
        await syncToFirestore('suppliers', Hive.box<Supplier>('suppliers'));
      }

      // Sync customers
      if (Hive.isBoxOpen('customers')) {
        await syncToFirestore('customers', Hive.box<Customer>('customers'));
      }

      // Sync categories
      if (Hive.isBoxOpen('categories')) {
        await syncToFirestore('categories', Hive.box<Category>('categories'));
      }

      // Sync sub-categories
      if (Hive.isBoxOpen('subCategories')) {
        await syncToFirestore('subCategories', Hive.box<SubCategory>('subCategories'));
      }

      // Sync universal parameters
      if (Hive.isBoxOpen('universalParameters')) {
        await syncToFirestore('universalParameters', Hive.box<UniversalParameter>('universalParameters'));
      }

      // Sync category parameter mappings
      if (Hive.isBoxOpen('categoryParameterMappings')) {
        await syncToFirestore('categoryParameterMappings', Hive.box<CategoryParameterMapping>('categoryParameterMappings'));
      }

      // Sync materials
      if (Hive.isBoxOpen('materials')) {
        await syncToFirestore('materials', Hive.box<MaterialItem>('materials'));
      }

      // Sync sale orders
      if (Hive.isBoxOpen('saleOrders')) {
        await syncToFirestore('saleOrders', Hive.box<SaleOrder>('saleOrders'));
      }

      // Sync stock maintenance
      if (Hive.isBoxOpen('stockMaintenance')) {
        await syncToFirestore('stockMaintenance', Hive.box<StockMaintenance>('stockMaintenance'));
      }

      // Sync purchase requests
      if (Hive.isBoxOpen('purchaseRequests')) {
        await syncToFirestore('purchaseRequests', Hive.box<PurchaseRequest>('purchaseRequests'));
      }

      // Sync purchase orders
      if (Hive.isBoxOpen('purchaseOrders')) {
        await syncToFirestore('purchaseOrders', Hive.box<PurchaseOrder>('purchaseOrders'));
      }

      // Sync store inwards
      if (Hive.isBoxOpen('storeInwards')) {
        await syncToFirestore('storeInwards', Hive.box<StoreInward>('storeInwards'));
      }

      // Sync quality inspections
      if (Hive.isBoxOpen('qualityInspections')) {
        await syncToFirestore('qualityInspections', Hive.box<QualityInspection>('qualityInspections'));
      }

      // Sync material requests
      if (Hive.isBoxOpen('materialRequests')) {
        await syncToFirestore('materialRequests', Hive.box<MaterialRequest>('materialRequests'));
      }

      // Sync material issues
      if (Hive.isBoxOpen('materialIssues')) {
        await syncToFirestore('materialIssues', Hive.box<MaterialIssue>('materialIssues'));
      }

      print('\n=== SYNC COMPLETED SUCCESSFULLY ===');
      _ref.read(syncStatusProvider.notifier).state = 'Sync completed successfully';
      _ref.read(syncErrorProvider.notifier).state = null;

      // Clear status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _ref.read(syncStatusProvider.notifier).state = null;
      });
    } catch (e) {
      final errorMsg = 'Error during full sync: $e';
      print('\n=== SYNC ERROR ===');
      print(errorMsg);
      print('=== END SYNC ERROR ===\n');
      _ref.read(syncErrorProvider.notifier).state = errorMsg;
      
      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _ref.read(syncErrorProvider.notifier).state = null;
      });
      rethrow;
    }
  }

  Future<void> syncFromAllData() async {
    try {
      _ref.read(syncStatusProvider.notifier).state = 'Starting full sync from Firestore...';
      _ref.read(syncErrorProvider.notifier).state = null;

      print('\n=== STARTING FULL SYNC FROM FIRESTORE ===');

      // Sync suppliers
      if (Hive.isBoxOpen('suppliers')) {
        await syncFromFirestore('suppliers', Hive.box<Supplier>('suppliers'), supplierFromMap);
      }

      // Sync customers
      if (Hive.isBoxOpen('customers')) {
        await syncFromFirestore('customers', Hive.box<Customer>('customers'), customerFromMap);
      }

      // Sync categories
      if (Hive.isBoxOpen('categories')) {
        await syncFromFirestore('categories', Hive.box<Category>('categories'), categoryFromMap);
      }

      // Sync sub-categories
      if (Hive.isBoxOpen('subCategories')) {
        await syncFromFirestore('subCategories', Hive.box<SubCategory>('subCategories'), subCategoryFromMap);
      }

      // Sync universal parameters
      if (Hive.isBoxOpen('universalParameters')) {
        await syncFromFirestore('universalParameters', Hive.box<UniversalParameter>('universalParameters'), universalParameterFromMap);
      }

      // Sync category parameter mappings
      if (Hive.isBoxOpen('categoryParameterMappings')) {
        await syncFromFirestore('categoryParameterMappings', Hive.box<CategoryParameterMapping>('categoryParameterMappings'), categoryParameterMappingFromMap);
      }

      // Sync materials
      if (Hive.isBoxOpen('materials')) {
        await syncFromFirestore('materials', Hive.box<MaterialItem>('materials'), materialFromMap);
      }

      // Sync sale orders
      if (Hive.isBoxOpen('saleOrders')) {
        await syncFromFirestore('saleOrders', Hive.box<SaleOrder>('saleOrders'), saleOrderFromMap);
      }

      // Sync stock maintenance
      if (Hive.isBoxOpen('stockMaintenance')) {
        await syncFromFirestore('stockMaintenance', Hive.box<StockMaintenance>('stockMaintenance'), stockMaintenanceFromMap);
      }

      // Sync purchase requests
      if (Hive.isBoxOpen('purchaseRequests')) {
        await syncFromFirestore('purchaseRequests', Hive.box<PurchaseRequest>('purchaseRequests'), purchaseRequestFromMap);
      }

      // Sync purchase orders
      if (Hive.isBoxOpen('purchaseOrders')) {
        await syncFromFirestore('purchaseOrders', Hive.box<PurchaseOrder>('purchaseOrders'), purchaseOrderFromMap);
      }

      // Sync store inwards
      if (Hive.isBoxOpen('storeInwards')) {
        await syncFromFirestore('storeInwards', Hive.box<StoreInward>('storeInwards'), storeInwardFromMap);
      }

      // Sync quality inspections
      if (Hive.isBoxOpen('qualityInspections')) {
        await syncFromFirestore('qualityInspections', Hive.box<QualityInspection>('qualityInspections'), qualityInspectionFromMap);
      }

      // Sync material requests
      if (Hive.isBoxOpen('materialRequests')) {
        await syncFromFirestore('materialRequests', Hive.box<MaterialRequest>('materialRequests'), materialRequestFromMap);
      }

      // Sync material issues
      if (Hive.isBoxOpen('materialIssues')) {
        await syncFromFirestore('materialIssues', Hive.box<MaterialIssue>('materialIssues'), materialIssueFromMap);
      }

      print('\n=== SYNC FROM FIRESTORE COMPLETED SUCCESSFULLY ===');
      _ref.read(syncStatusProvider.notifier).state = 'Sync from Firestore completed successfully';
      _ref.read(syncErrorProvider.notifier).state = null;

      // Clear status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _ref.read(syncStatusProvider.notifier).state = null;
      });
    } catch (e) {
      final errorMsg = 'Error during full sync from Firestore: $e';
      print('\n=== SYNC ERROR ===');
      print(errorMsg);
      print('=== END SYNC ERROR ===\n');
      _ref.read(syncErrorProvider.notifier).state = errorMsg;
      
      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _ref.read(syncErrorProvider.notifier).state = null;
      });
      rethrow;
    }
  }
} 