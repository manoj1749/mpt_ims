import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/supplier.dart';
import '../services/sync_service.dart';

final supplierBoxProvider =
    Provider<Box<Supplier>>((ref) => throw UnimplementedError());

final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, List<Supplier>>((ref) {
  final box = ref.watch(supplierBoxProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SupplierListNotifier(box, syncService);
});

class SupplierListNotifier extends StateNotifier<List<Supplier>> {
  final Box<Supplier> box;
  final SyncService _syncService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SupplierListNotifier(this.box, this._syncService) : super(box.values.toList()) {
    // Load suppliers when initialized
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    try {
      print('Loading suppliers from Firestore...');
      final querySnapshot = await _firestore.collection('suppliers').get();
      print('Found ${querySnapshot.docs.length} suppliers in Firestore');

      // Clear existing suppliers from Hive
      await box.clear();

      // Add new suppliers to Hive
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final supplier = _syncService.supplierFromMap(data);
        await box.add(supplier);
      }

      // Update state
      state = box.values.toList();
      print('Successfully loaded suppliers');
    } catch (e) {
      print('Error loading suppliers: $e');
      rethrow;
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      // Add to Firestore first
      final docRef = await _firestore.collection('suppliers').add({
        'name': supplier.name,
        'contact': supplier.contact,
        'phone': supplier.phone,
        'email': supplier.email,
        'vendorCode': supplier.vendorCode,
        'address1': supplier.address1,
        'address2': supplier.address2,
        'address3': supplier.address3,
        'address4': supplier.address4,
        'state': supplier.state,
        'stateCode': supplier.stateCode,
        'paymentTerms': supplier.paymentTerms,
        'pan': supplier.pan,
        'gstNo': supplier.gstNo,
        'igst': supplier.igst,
        'cgst': supplier.cgst,
        'sgst': supplier.sgst,
        'totalGst': supplier.totalGst,
        'bank': supplier.bank,
        'branch': supplier.branch,
        'account': supplier.account,
        'ifsc': supplier.ifsc,
        'email1': supplier.email1,
        'lastModifiedBy': _auth.currentUser?.email,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
      print('Added supplier to Firestore with ID: ${docRef.id}');

      // Then add to local storage
      await box.add(supplier);
      state = box.values.toList();
    } catch (e) {
      print('Error adding supplier: $e');
      rethrow;
    }
  }

  Future<void> updateSupplier(int key, Supplier updated) async {
    try {
      // Find the Firestore document with matching name
      final querySnapshot = await _firestore
          .collection('suppliers')
          .where('name', isEqualTo: updated.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        // Update in Firestore
        await _firestore.collection('suppliers').doc(docId).update({
          'name': updated.name,
          'contact': updated.contact,
          'phone': updated.phone,
          'email': updated.email,
          'vendorCode': updated.vendorCode,
          'address1': updated.address1,
          'address2': updated.address2,
          'address3': updated.address3,
          'address4': updated.address4,
          'state': updated.state,
          'stateCode': updated.stateCode,
          'paymentTerms': updated.paymentTerms,
          'pan': updated.pan,
          'gstNo': updated.gstNo,
          'igst': updated.igst,
          'cgst': updated.cgst,
          'sgst': updated.sgst,
          'totalGst': updated.totalGst,
          'bank': updated.bank,
          'branch': updated.branch,
          'account': updated.account,
          'ifsc': updated.ifsc,
          'email1': updated.email1,
          'lastModifiedBy': _auth.currentUser?.email,
          'lastModifiedAt': FieldValue.serverTimestamp(),
        });
        print('Updated supplier in Firestore with ID: $docId');
      }

      // Update in local storage
      await box.put(key, updated);
      state = box.values.toList();
    } catch (e) {
      print('Error updating supplier: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(Supplier supplier) async {
    try {
      // Find and delete from Firestore
      final querySnapshot = await _firestore
          .collection('suppliers')
          .where('name', isEqualTo: supplier.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection('suppliers').doc(docId).delete();
        print('Deleted supplier from Firestore with ID: $docId');
      }

      // Delete from local storage
      await supplier.delete();
      state = state.where((s) => s.key != supplier.key).toList();
    } catch (e) {
      print('Error deleting supplier: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadSuppliers();
  }
}
