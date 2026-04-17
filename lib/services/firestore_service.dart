import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/delivery_challan.dart';
import '../models/material_issue.dart';
import '../models/material_request.dart';
import '../models/purchase_order.dart';
import '../models/purchase_request.dart';
import '../models/stock_maintenance.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Convert Timestamp to DateTime
  DateTime _timestampToDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  // Convert DateTime to Timestamp
  Timestamp _dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  // Generic method to save data to Firestore
  Future<void> saveData<T>(String collection, String documentId, T data) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .doc(documentId);

      // Convert the data to a Map
      final Map<String, dynamic> dataMap;
      if (data is DeliveryChallan) {
        dataMap = _deliveryChallanToMap(data);
      } else if (data is MaterialIssue) {
        dataMap = _materialIssueToMap(data);
      } else if (data is MaterialRequest) {
        dataMap = _materialRequestToMap(data);
      } else if (data is PurchaseOrder) {
        dataMap = _purchaseOrderToMap(data);
      } else if (data is PurchaseRequest) {
        dataMap = _purchaseRequestToMap(data);
      } else if (data is StockMaintenance) {
        dataMap = _stockMaintenanceToMap(data);
      } else {
        throw Exception('Unsupported data type');
      }

      // Add metadata
      dataMap['lastUpdated'] = FieldValue.serverTimestamp();
      dataMap['lastUpdatedBy'] = currentUserId;

      await docRef.set(dataMap, SetOptions(merge: true));
    } catch (e) {
      print('Error saving data to Firestore: $e');
      rethrow;
    }
  }

  // Generic method to load data from Firestore
  Future<List<T>> loadData<T>(String collection) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        if (T == DeliveryChallan) {
          return _mapToDeliveryChallan(data) as T;
        } else if (T == MaterialIssue) {
          return _mapToMaterialIssue(data) as T;
        } else if (T == MaterialRequest) {
          return _mapToMaterialRequest(data) as T;
        } else if (T == PurchaseOrder) {
          return _mapToPurchaseOrder(data) as T;
        } else if (T == PurchaseRequest) {
          return _mapToPurchaseRequest(data) as T;
        } else if (T == StockMaintenance) {
          return _mapToStockMaintenance(data) as T;
        } else {
          throw Exception('Unsupported data type');
        }
      }).toList();
    } catch (e) {
      print('Error loading data from Firestore: $e');
      rethrow;
    }
  }

  // Generic method to delete data from Firestore
  Future<void> deleteData(String collection, String documentId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .doc(documentId)
          .delete();
    } catch (e) {
      print('Error deleting data from Firestore: $e');
      rethrow;
    }
  }

  // Conversion methods for DeliveryChallan
  Map<String, dynamic> _deliveryChallanToMap(DeliveryChallan dc) {
    return {
      'dcNo': dc.dcNo,
      'dcDate': dc.dcDate,
      'vendorName': dc.vendorName,
      'vendorEmail': dc.vendorEmail,
      'vendorGstin': dc.vendorGstin,
      'isReturnable': dc.isReturnable,
      'note': dc.note,
      'items': dc.items
          .map((item) => {
                'materialCode': item.materialCode,
                'materialDescription': item.materialDescription,
                'unit': item.unit,
                'quantity': item.quantity,
                'jobNo': item.jobNo,
                'prNo': item.prNo,
                'price': item.price,
              })
          .toList(),
    };
  }

  DeliveryChallan _mapToDeliveryChallan(Map<String, dynamic> data) {
    return DeliveryChallan(
      dcNo: data['dcNo'],
      dcDate: data['dcDate'],
      vendorName: data['vendorName'],
      vendorEmail: data['vendorEmail'],
      vendorGstin: data['vendorGstin'],
      isReturnable: data['isReturnable'],
      note: data['note'],
      items: (data['items'] as List)
          .map((item) => DeliveryChallanItem(
                materialCode: item['materialCode'],
                materialDescription: item['materialDescription'],
                unit: item['unit'],
                quantity: item['quantity'].toDouble(),
                jobNo: item['jobNo'],
                prNo: item['prNo'],
                price: (item['price'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList(),
    );
  }

  // Add similar conversion methods for other models (MaterialIssue, MaterialRequest, etc.)
  // For brevity, I'm showing just the DeliveryChallan methods
  // You'll need to implement the rest based on your model structures

  Map<String, dynamic> _materialIssueToMap(MaterialIssue mi) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  MaterialIssue _mapToMaterialIssue(Map<String, dynamic> data) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  Map<String, dynamic> _materialRequestToMap(MaterialRequest mr) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  MaterialRequest _mapToMaterialRequest(Map<String, dynamic> data) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  Map<String, dynamic> _purchaseOrderToMap(PurchaseOrder po) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  PurchaseOrder _mapToPurchaseOrder(Map<String, dynamic> data) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  Map<String, dynamic> _purchaseRequestToMap(PurchaseRequest pr) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  PurchaseRequest _mapToPurchaseRequest(Map<String, dynamic> data) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  Map<String, dynamic> _stockMaintenanceToMap(StockMaintenance stock) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }

  StockMaintenance _mapToStockMaintenance(Map<String, dynamic> data) {
    // TODO: Implement conversion
    throw UnimplementedError();
  }
}
