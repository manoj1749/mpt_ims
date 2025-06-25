import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
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
import '../models/inward_item.dart';
import '../models/quality_inspection.dart';
import '../models/inspection_item.dart';
import '../models/quality_parameter.dart';
import '../models/material_request.dart';
import '../models/material_request_item.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generic method to sync data from Hive to Firestore
  Future<void> syncToFirestore<T>(String collection, Box<T> box) async {
    try {
      final batch = _firestore.batch();
      final collectionRef = _firestore.collection(collection);

      // First, mark all existing documents for deletion
      final existingDocs = await collectionRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Then add all current documents
      for (var item in box.values) {
        final docRef = collectionRef.doc();
        final data = _convertToMap(item);
        data['lastUpdated'] = FieldValue.serverTimestamp();
        data['lastUpdatedBy'] = _auth.currentUser?.email ?? 'unknown';
        batch.set(docRef, data);
      }

      await batch.commit();
      print('Successfully synced $collection to Firestore');
    } catch (e) {
      print('Error syncing $collection to Firestore: $e');
      rethrow;
    }
  }

  // Generic method to sync data from Firestore to Hive
  Future<void> syncFromFirestore<T>(String collection, Box<T> box, T Function(Map<String, dynamic>) fromMap) async {
    try {
      final querySnapshot = await _firestore.collection(collection).get();

      await box.clear(); // Clear existing data
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final item = fromMap(data);
        await box.add(item);
      }

      print('Successfully synced $collection from Firestore');
    } catch (e) {
      print('Error syncing $collection from Firestore: $e');
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

  PurchaseOrder purchaseOrderFromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      poNo: map['poNo'] ?? '',
      date: map['date'] ?? '',
      requiredBy: map['requiredBy'] ?? '',
      status: map['status'],
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => poItemFromMap(i as Map<String, dynamic>))
          .toList(),
      jobNo: map['jobNo'],
    );
  }

  POItem poItemFromMap(Map<String, dynamic> map) {
    return POItem(
      poNo: map['poNo'] ?? '',
      date: map['date'] ?? '',
      requiredBy: map['requiredBy'] ?? '',
      status: map['status'],
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => _convertToMap(i))
          .toList(),
      jobNo: map['jobNo'],
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
          ?.map((i) => inwardItemFromMap(i as Map<String, dynamic>))
          .toList() ??
          [],
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
          ?.map((i) => inspectionItemFromMap(i as Map<String, dynamic>))
          .toList() ??
          [],
      status: map['status'] ?? 'Pending',
      prNumbers: (map['prNumbers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      jobNumbers: (map['jobNumbers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      capaNo: map['capaNo'],
      capaStatus: map['capaStatus'],
      capaDescription: map['capaDescription'],
      capaAssignedTo: map['capaAssignedTo'],
      capaTargetDate: map['capaTargetDate'],
      capaCompletionDate: map['capaCompletionDate'],
      capaActions: (map['capaActions'] as List<dynamic>?)
          ?.map((e) => e.toString())
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
      items: (map['items'] as List<dynamic>?)
          ?.map((i) => materialRequestItemFromMap(i as Map<String, dynamic>))
          .toList(),
      jobNo: map['jobNo'],
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
} 