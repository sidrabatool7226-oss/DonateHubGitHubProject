import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedCategory = 'All'.obs;
  var selectedEntrySource = 'desktop'.obs;
  // 'desktop' = donor khud laya
  // 'tcs'     = courier/TCS se aaya
  // 'volunteer' = volunteer ne deliver kiya (auto)

  // Form controllers
  final itemNameController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  final donorNameController = TextEditingController();
  final trackingController = TextEditingController();

  final List<String> categories = [
    'All',
    'Food',
    'Clothes',
    'Books',
    'Furniture',
    'Medicine',
    'Stationery',
    'Shoes',
    'Blankets',
    'Other',
  ];

  @override
  void onClose() {
    itemNameController.dispose();
    quantityController.dispose();
    notesController.dispose();
    donorNameController.dispose();
    trackingController.dispose();
    super.onClose();
  }

  // ── Clear Form ───────────────────────────────────────────────────────
  void clearForm() {
    itemNameController.clear();
    quantityController.clear();
    notesController.clear();
    donorNameController.clear();
    trackingController.clear();
    selectedEntrySource.value = 'desktop';
  }

  // ── Real-time Stream ─────────────────────────────────────────────────
  Stream<QuerySnapshot> get inventoryStream {
    if (selectedCategory.value == 'All') {
      return _db
          .collection('inventory')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _db
        .collection('inventory')
        .where('category', isEqualTo: selectedCategory.value)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Add Item Manually (Desktop / TCS entry) ──────────────────────────
  Future<bool> addManualItem(String category) async {
    if (itemNameController.text.trim().isEmpty ||
        quantityController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill item name and quantity',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    int? qty = int.tryParse(quantityController.text.trim());
    if (qty == null || qty <= 0) {
      Get.snackbar(
        'Invalid Quantity',
        'Please enter a valid quantity',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isLoading.value = true;

    try {
      // Check existing item
      QuerySnapshot existing = await _db
          .collection('inventory')
          .where(
        'itemNameLower',
        isEqualTo: itemNameController.text.trim().toLowerCase(),
      )
          .where('category', isEqualTo: category)
          .get();

      if (existing.docs.isNotEmpty) {
        // Quantity add karo existing item mein
        String docId = existing.docs.first.id;
        int currentQty =
            (existing.docs.first.data() as Map)['quantity'] ?? 0;

        await _db.collection('inventory').doc(docId).update({
          'quantity': currentQty + qty,
          'isUrgent': (currentQty + qty) <= 5,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Stock history log
        await _db.collection('inventory_logs').add({
          'itemId': docId,
          'itemName': itemNameController.text.trim(),
          'category': category,
          'quantityAdded': qty,
          'source': selectedEntrySource.value,
          'donorName': donorNameController.text.trim(),
          'trackingNumber': trackingController.text.trim(),
          'notes': notesController.text.trim(),
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Naya item
        DocumentReference docRef =
        await _db.collection('inventory').add({
          'itemName': itemNameController.text.trim(),
          'itemNameLower':
          itemNameController.text.trim().toLowerCase(),
          'category': category,
          'quantity': qty,
          'isUrgent': qty <= 5,
          'source': selectedEntrySource.value,
          'donorName': donorNameController.text.trim(),
          'notes': notesController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Log
        await _db.collection('inventory_logs').add({
          'itemId': docRef.id,
          'itemName': itemNameController.text.trim(),
          'category': category,
          'quantityAdded': qty,
          'source': selectedEntrySource.value,
          'donorName': donorNameController.text.trim(),
          'trackingNumber': trackingController.text.trim(),
          'notes': notesController.text.trim(),
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      clearForm();
      Get.snackbar(
        'Added',
        'Item added to inventory successfully!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add item. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Auto Add from Volunteer Delivery (called internally) ─────────────
  // Yeh function tab call hoga jab Manager delivery proof accept kare
  static Future<void> autoAddFromVolunteer({
    required FirebaseFirestore db,
    required String itemName,
    required String category,
    required int quantity,
    required String donationId,
    required String donorName,
  }) async {
    try {
      QuerySnapshot existing = await db
          .collection('inventory')
          .where('itemNameLower', isEqualTo: itemName.toLowerCase())
          .where('category', isEqualTo: category)
          .get();

      if (existing.docs.isNotEmpty) {
        String docId = existing.docs.first.id;
        int currentQty =
            (existing.docs.first.data() as Map)['quantity'] ?? 0;

        await db.collection('inventory').doc(docId).update({
          'quantity': currentQty + quantity,
          'isUrgent': (currentQty + quantity) <= 5,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        await db.collection('inventory_logs').add({
          'itemId': docId,
          'itemName': itemName,
          'category': category,
          'quantityAdded': quantity,
          'source': 'volunteer',
          'donorName': donorName,
          'donationId': donationId,
          'notes': 'Auto-added after volunteer delivery',
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        DocumentReference docRef = await db.collection('inventory').add({
          'itemName': itemName,
          'itemNameLower': itemName.toLowerCase(),
          'category': category,
          'quantity': quantity,
          'isUrgent': quantity <= 5,
          'source': 'volunteer',
          'donorName': donorName,
          'notes': 'Auto-added after volunteer delivery',
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        await db.collection('inventory_logs').add({
          'itemId': docRef.id,
          'itemName': itemName,
          'category': category,
          'quantityAdded': quantity,
          'source': 'volunteer',
          'donorName': donorName,
          'donationId': donationId,
          'notes': 'Auto-added after volunteer delivery',
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Auto inventory update failed: $e');
    }
  }

  // ── Update Quantity ──────────────────────────────────────────────────
  Future<void> updateQuantity(String docId, int newQty) async {
    await _db.collection('inventory').doc(docId).update({
      'quantity': newQty,
      'isUrgent': newQty <= 5,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ── Delete Item ──────────────────────────────────────────────────────
  Future<void> deleteItem(String docId) async {
    try {
      await _db.collection('inventory').doc(docId).delete();
      Get.snackbar(
        'Deleted',
        'Item removed from inventory.',
        backgroundColor: Colors.orange[50],
        colorText: Colors.orange[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not delete.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Toggle Urgent ────────────────────────────────────────────────────
  Future<void> toggleUrgent(String docId, bool current) async {
    await _db
        .collection('inventory')
        .doc(docId)
        .update({'isUrgent': !current});
  }
}