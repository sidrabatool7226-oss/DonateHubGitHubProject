// ============================================================
// FILE: lib/controllers/admin_donations_controller.dart
//
// CHANGE: Added 'Fund' as a type filter option alongside the
// existing Online/Desk-based/Volunteer Pickup resource filters.
// Fund donations are identified by 'type'=='fund' OR presence
// of the 'amount' field — same pattern already used elsewhere
// in the project to distinguish fund vs resource donations
// (no 'type' field exists on older resource donation docs).
// Everything else (Add Donation form, resource donation logic,
// status updates, soft-delete) is UNCHANGED.
// ============================================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
// Safely parses quantity whether Firestore stores it as int or String —
// donor-submitted item donations save quantity as String
// (FirestoreService.saveDonation), while admin-manual entries save it
// as int. This prevents the "String is not a subtype of int" crash.
int safeParseQty(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
class AdminDonationsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  var isLoading = true.obs;
  var isSaving = false.obs;
  var searchQuery = ''.obs;
  var selectedTypeFilter = 'All'.obs; // All | Online | Desk-based | Volunteer Pickup | Fund
  var selectedCategoryFilter = 'All'.obs;
  var selectedStatusFilter = 'All'.obs;

  var allDonations = <Map<String, dynamic>>[].obs;

  final List<String> typeFilters = const [
    'All', 'Online', 'Desk-based', 'Volunteer Pickup', 'Fund', // NEW: 'Fund'
  ];

  final List<String> filterCategories = const [
    'All', 'Food', 'Clothes', 'Books', 'Toys', 'Furniture', 'Medicine',
    'Stationery', 'Shoes', 'Blankets', 'Other',
  ];

  // ── Add Donation form (resource donations only — manual walk-in entries) ──
  final donorNameCtrl = TextEditingController();
  final donorContactCtrl = TextEditingController();
  final itemNameCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String selectedCategory = 'Food';
  String selectedCondition = 'Good';
  String selectedDonationType = 'desk';
  File? addFormImage;

  final List<String> categories = const [
    'Food', 'Clothes', 'Books', 'Toys', 'Furniture', 'Medicine',
    'Stationery', 'Shoes', 'Blankets', 'Other',
  ];
  final List<String> conditions = const ['New', 'Fair', 'Unused', 'Good'];

  @override
  void onInit() {
    super.onInit();
    _bindDonations();
  }

  @override
  void onClose() {
    donorNameCtrl.dispose();
    donorContactCtrl.dispose();
    itemNameCtrl.dispose();
    quantityCtrl.dispose();
    descriptionCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  // Single orderBy, no composite where+orderBy combo — avoids requiring
  // a Firestore composite index (this pattern caused silent empty
  // results earlier in the project when combined with .where()).
  void _bindDonations() {
    _db.collection('donations').orderBy('createdAt', descending: true).snapshots().listen(
          (snap) {
        final list = snap.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).where((d) => d['isDeleted'] != true).toList();
        allDonations.value = list;
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
  }

  bool _isFund(Map<String, dynamic> d) => d['type'] == 'fund' || d.containsKey('amount');
  bool _isResource(Map<String, dynamic> d) => d.containsKey('itemName');

  // ── Filtered list ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get filtered {
    var list = allDonations.toList();

    if (selectedTypeFilter.value != 'All') {
      list = list.where((d) {
        final logistics = (d['logisticsType'] ?? d['donationType'] ?? '').toString();
        switch (selectedTypeFilter.value) {
          case 'Online':
            return _isResource(d) && logistics == 'online';
          case 'Desk-based':
            return _isResource(d) && logistics == 'desk';
          case 'Volunteer Pickup':
            return _isResource(d) && logistics == 'pickup';
          case 'Fund':
            return _isFund(d);
          default:
            return true;
        }
      }).toList();
    }

    if (selectedCategoryFilter.value != 'All') {
      list = list.where((d) => (d['category'] ?? '') == selectedCategoryFilter.value).toList();
    }

    if (selectedStatusFilter.value != 'All') {
      list = list.where((d) => (d['status'] ?? '') == selectedStatusFilter.value).toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((d) {
        final id = (d['id'] ?? '').toString().toLowerCase();
        final item = (d['itemName'] ?? '').toString().toLowerCase();
        final donor = (d['userEmail'] ?? d['donorEmail'] ?? d['donorName'] ?? '').toString().toLowerCase();
        final category = (d['category'] ?? '').toString().toLowerCase();
        final logistics = (d['logisticsType'] ?? d['donationType'] ?? '').toString().toLowerCase();
        final campaign = (d['campaignName'] ?? '').toString().toLowerCase();
        return id.contains(q) || item.contains(q) || donor.contains(q) ||
            category.contains(q) || logistics.contains(q) || campaign.contains(q);
      }).toList();
    }

    return list;
  }

  // ── Summary counts ───────────────────────────────────────────────────
  int get totalCount => allDonations.length;
  int get pendingCount => allDonations.where((d) => d['status'] == 'pending').length;
  int get approvedCount => allDonations.where((d) => [
    'approved', 'in_transit', 'awaiting_physical', 'pending_pickup',
    'volunteer_assigned', 'picked_up', 'received'
  ].contains(d['status'])).length;
  int get completedCount => allDonations.where((d) => d['status'] == 'completed').length;

  // ── Fetch donor profile (for resource detail screen) ──────────────────
  Future<Map<String, dynamic>?> fetchDonorProfile(String? donorId) async {
    if (donorId == null || donorId.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(donorId).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchLinkedTask(String donationId) async {
    try {
      final snap = await _db.collection('tasks').where('donationId', isEqualTo: donationId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      final data = Map<String, dynamic>.from(snap.docs.first.data());
      data['id'] = snap.docs.first.id;
      return data;
    } catch (_) {
      return null;
    }
  }

  // ── Status transition (resource donations only) ────────────────────────
  Future<void> updateStatus(String docId, String newStatus, {String? reason}) async {
    final update = <String, dynamic>{'status': newStatus};
    final tsField = _timestampFieldForStatus(newStatus);
    if (tsField != null) update[tsField] = FieldValue.serverTimestamp();
    if (reason != null) update['rejectionReason'] = reason;

    await _db.collection('donations').doc(docId).update(update);

    _snack(
      newStatus == 'rejected' ? 'Rejected' : 'Updated',
      newStatus == 'rejected' ? 'Donation rejected.' : 'Status updated to ${_statusLabel(newStatus)}.',
      isError: newStatus == 'rejected',
    );
  }

  String? _timestampFieldForStatus(String status) {
    switch (status) {
      case 'approved': return 'approvedAt';
      case 'picked_up': return 'pickedUpAt';
      case 'received': return 'receivedAt';
      case 'completed': return 'completedAt';
      case 'rejected': return 'rejectedAt';
      default: return null;
    }
  }

  String _statusLabel(String status) =>
      status.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  // ── Add Donation form actions (resource donations only) ────────────────
  Future<void> pickAddFormImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (img != null) {
      addFormImage = File(img.path);
      update();
    }
  }

  void clearAddForm() {
    donorNameCtrl.clear();
    donorContactCtrl.clear();
    itemNameCtrl.clear();
    quantityCtrl.clear();
    descriptionCtrl.clear();
    notesCtrl.clear();
    selectedCategory = 'Food';
    selectedCondition = 'Good';
    selectedDonationType = 'desk';
    addFormImage = null;
    update();
  }

  Future<bool> addManualDonation() async {
    if (donorNameCtrl.text.trim().isEmpty || itemNameCtrl.text.trim().isEmpty || quantityCtrl.text.trim().isEmpty) {
      _snack('Missing Fields', 'Donor name, item name and quantity are required', isError: true);
      return false;
    }

    isSaving.value = true;
    try {
      String imageUrl = '';
      if (addFormImage != null) {
        final url = await _cloudinary.uploadImage(addFormImage!);
        if (url != null) imageUrl = url;
      }

      await _db.collection('donations').add({
        'type': 'resource',
        'donorName': donorNameCtrl.text.trim(),
        'donorContact': donorContactCtrl.text.trim(),
        'category': selectedCategory,
        'itemName': itemNameCtrl.text.trim(),
        'quantity': int.tryParse(quantityCtrl.text.trim()) ?? 1,
        'condition': selectedCondition,
        'description': descriptionCtrl.text.trim(),
        'logisticsType': selectedDonationType,
        'itemImageUrl': imageUrl,
        'notes': notesCtrl.text.trim(),
        'status': 'approved',
        'source': 'admin_manual',
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });

      clearAddForm();
      _snack('Added', 'Donation record added successfully!');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to add donation.', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> softDelete(String docId) async {
    await _db.collection('donations').doc(docId).update({'isDeleted': true});
    _snack('Removed', 'Donation record removed.');
  }

  void _snack(String title, String msg, {bool isError = false}) {
    Get.snackbar(
      title, msg,
      backgroundColor: isError ? Colors.red[50] : Colors.green[50],
      colorText: isError ? Colors.red[700] : Colors.green[700],
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}