import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/utilization_model.dart';
import '../services/cloudinary_service.dart';

class UtilizationController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var isSaving = false.obs;
  var uploadProgress = 0.0.obs;

  // Filter
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  // Form fields
  var selectedDonationType = 'fund'.obs;
  var selectedCampaignId = ''.obs;
  var selectedCampaignName = ''.obs;
  var selectedStatus = 'draft'.obs;
  var utilizationDate = ''.obs;

  // Images and documents
  var impactImages = <File>[].obs;
  var impactImageUrls = <String>[].obs;
  var proofDocuments = <Map<String, dynamic>>[].obs;
  // {file: File, type: String, name: String, url: String}

  // Inventory items for utilization
  var selectedInventoryItems =
      <Map<String, dynamic>>[].obs;
  // {itemName, category, quantity, docId}

  // Campaigns list
  var campaigns = <Map<String, dynamic>>[].obs;

  // Inventory list
  var inventoryItems = <Map<String, dynamic>>[].obs;

  // Form controllers
  final fundAmountController = TextEditingController();
  final beneficiariesController = TextEditingController();
  final descriptionController = TextEditingController();

  final List<String> filterOptions = [
    'All',
    'Draft',
    'Completed',
    'Fund',
    'Resource',
    'Both',
  ];

  final List<String> documentTypes = [
    'Receipt',
    'Bill',
    'Invoice',
    'School Fee Slip',
    'Medical Bill',
  ];

  final List<String> impactCategories = [
    'Food Distribution',
    'Educational Activities',
    'Medical Camp',
    'Winter Distribution',
    'Event',
    'Purchased Items',
    'Children Activities',
  ];

  @override
  void onInit() {
    super.onInit();
    loadCampaigns();
    loadInventory();
  }

  @override
  void onClose() {
    fundAmountController.dispose();
    beneficiariesController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // ── Load Campaigns ───────────────────────────────────────────────────
  Future<void> loadCampaigns() async {
    final snap = await _db.collection('campaigns').get();
    campaigns.value = snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  // ── Load Inventory ───────────────────────────────────────────────────
  Future<void> loadInventory() async {
    final snap = await _db.collection('inventory').get();
    inventoryItems.value = snap.docs.map((d) {
      final data = d.data();
      data['docId'] = d.id;
      return data;
    }).toList();
  }

  // ── Real-time Stream ─────────────────────────────────────────────────
  Stream<QuerySnapshot> get utilizationStream {
    Query query = _db
        .collection('utilization')
        .orderBy('createdAt', descending: true);
    return query.snapshots();
  }

  // ── Filtered list ────────────────────────────────────────────────────
  List<Map<String, dynamic>> filterRecords(
      List<Map<String, dynamic>> records) {
    List<Map<String, dynamic>> result = records;

    if (selectedFilter.value != 'All') {
      final f = selectedFilter.value.toLowerCase();
      result = result.where((r) {
        if (f == 'draft' || f == 'completed') {
          return (r['status'] ?? '') == f;
        }
        if (f == 'fund' || f == 'resource' || f == 'both') {
          return (r['donationType'] ?? '') == f;
        }
        return true;
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where((r) =>
      (r['campaignName'] ?? '')
          .toLowerCase()
          .contains(q) ||
          (r['description'] ?? '')
              .toLowerCase()
              .contains(q))
          .toList();
    }

    return result;
  }

  // ── Pick Impact Images ───────────────────────────────────────────────
  Future<void> pickImpactImages() async {
    final List<XFile> images =
    await _picker.pickMultiImage(imageQuality: 70);
    for (var img in images) {
      impactImages.add(File(img.path));
    }
  }

  // ── Pick Proof Document ──────────────────────────────────────────────
  Future<void> pickProofDocument(String type) async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      proofDocuments.add({
        'file': File(image.path),
        'type': type,
        'name': '$type - ${DateTime.now().millisecondsSinceEpoch}',
        'url': '',
      });
    }
  }

  // ── Remove Impact Image ──────────────────────────────────────────────
  void removeImpactImage(int index) {
    if (index < impactImages.length) {
      impactImages.removeAt(index);
    }
  }

  // ── Remove Proof Document ────────────────────────────────────────────
  void removeProofDoc(int index) {
    if (index < proofDocuments.length) {
      proofDocuments.removeAt(index);
    }
  }

  // ── Toggle Inventory Item ────────────────────────────────────────────
  void toggleInventoryItem(Map<String, dynamic> item) {
    final exists = selectedInventoryItems
        .any((i) => i['docId'] == item['docId']);
    if (exists) {
      selectedInventoryItems
          .removeWhere((i) => i['docId'] == item['docId']);
    } else {
      selectedInventoryItems.add({
        'docId': item['docId'],
        'itemName': item['itemName'],
        'category': item['category'],
        'quantity': 1,
        'maxQty': item['quantity'],
      });
    }
  }

  // ── Update Item Quantity ─────────────────────────────────────────────
  void updateItemQty(String docId, int qty) {
    final index = selectedInventoryItems
        .indexWhere((i) => i['docId'] == docId);
    if (index != -1) {
      final max = selectedInventoryItems[index]['maxQty'];
      selectedInventoryItems[index] = {
        ...selectedInventoryItems[index],
        'quantity': qty.clamp(1, max),
      };
      selectedInventoryItems.refresh();
    }
  }

  // ── Clear Form ───────────────────────────────────────────────────────
  void clearForm() {
    selectedDonationType.value = 'fund';
    selectedCampaignId.value = '';
    selectedCampaignName.value = '';
    selectedStatus.value = 'draft';
    utilizationDate.value = '';
    impactImages.clear();
    impactImageUrls.clear();
    proofDocuments.clear();
    selectedInventoryItems.clear();
    fundAmountController.clear();
    beneficiariesController.clear();
    descriptionController.clear();
  }

  // ── Save Utilization Record ──────────────────────────────────────────
  Future<bool> saveRecord() async {
    // Validation
    if (selectedCampaignName.value.isEmpty) {
      _snack('Missing', 'Please select a campaign', isError: true);
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      _snack('Missing', 'Please add a description',
          isError: true);
      return false;
    }
    if (utilizationDate.value.isEmpty) {
      _snack('Missing', 'Please select utilization date',
          isError: true);
      return false;
    }

    isSaving.value = true;
    uploadProgress.value = 0;

    try {
      // Upload impact images
      List<String> imageUrls = [];
      for (int i = 0; i < impactImages.length; i++) {
        String? url =
        await _cloudinary.uploadImage(impactImages[i]);
        if (url != null) imageUrls.add(url);
        uploadProgress.value =
            (i + 1) / (impactImages.length + proofDocuments.length);
      }

      // Upload proof documents
      List<Map<String, dynamic>> docList = [];
      for (int i = 0; i < proofDocuments.length; i++) {
        final doc = proofDocuments[i];
        String? url =
        await _cloudinary.uploadImage(doc['file']);
        if (url != null) {
          docList.add({
            'type': doc['type'],
            'name': doc['name'],
            'url': url,
          });
        }
        uploadProgress.value =
            (impactImages.length + i + 1) /
                (impactImages.length + proofDocuments.length);
      }

      // Prepare items utilized
      List<Map<String, dynamic>> itemsList =
      selectedInventoryItems
          .map((item) => {
        'itemName': item['itemName'],
        'category': item['category'],
        'quantity': item['quantity'],
      })
          .toList();

      // Save to Firestore
      final docRef = await _db.collection('utilization').add({
        'campaignName': selectedCampaignName.value,
        'campaignId': selectedCampaignId.value,
        'donationType': selectedDonationType.value,
        'fundAmountUsed': double.tryParse(
            fundAmountController.text.trim()) ??
            0,
        'itemsUtilized': itemsList,
        'beneficiaries':
        int.tryParse(beneficiariesController.text.trim()) ??
            0,
        'description': descriptionController.text.trim(),
        'utilizationDate': utilizationDate.value,
        'status': selectedStatus.value,
        'impactImages': imageUrls,
        'proofDocuments': docList,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? '',
      });

      // If completed — update inventory quantities
      if (selectedStatus.value == 'completed') {
        await _updateInventoryAfterUtilization(itemsList);
      }

      clearForm();
      _snack('Saved', 'Utilization record saved!');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to save. Try again.',
          isError: true);
      return false;
    } finally {
      isSaving.value = false;
      uploadProgress.value = 0;
    }
  }

  // ── Update Inventory After Utilization ───────────────────────────────
  Future<void> _updateInventoryAfterUtilization(
      List<Map<String, dynamic>> items) async {
    for (var item in items) {
      final snap = await _db
          .collection('inventory')
          .where('itemNameLower',
          isEqualTo:
          (item['itemName'] as String).toLowerCase())
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final currentQty = (doc.data()['quantity'] ?? 0) as int;
        final usedQty = item['quantity'] as int;
        final newQty =
        (currentQty - usedQty).clamp(0, 9999);

        await _db
            .collection('inventory')
            .doc(doc.id)
            .update({
          'quantity': newQty,
          'isUrgent': newQty <= 5,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ── Mark as Completed ────────────────────────────────────────────────
  Future<void> markCompleted(String docId,
      List<Map<String, dynamic>> items) async {
    try {
      await _db
          .collection('utilization')
          .doc(docId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      await _updateInventoryAfterUtilization(items);

      _snack('Completed',
          'Record marked as completed. Inventory updated.');
    } catch (e) {
      _snack('Error', 'Could not update.',
          isError: true);
    }
  }

  // ── Delete Record ────────────────────────────────────────────────────
  Future<void> deleteRecord(String docId) async {
    try {
      await _db
          .collection('utilization')
          .doc(docId)
          .delete();
      _snack('Deleted', 'Record deleted.');
    } catch (e) {
      _snack('Error', 'Could not delete.', isError: true);
    }
  }

  // ── Pick Date ────────────────────────────────────────────────────────
  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B6B3A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      utilizationDate.value =
      '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  void _snack(String title, String message,
      {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor:
      isError ? Colors.red[50] : Colors.green[50],
      colorText:
      isError ? Colors.red[700] : Colors.green[700],
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}