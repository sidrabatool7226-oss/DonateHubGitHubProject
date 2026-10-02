import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../services/picked_image.dart';
import '../models/sponsorship_categories.dart'; // NEW

class CampaignController extends GetxController {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final CloudinaryService _cloudinary =
  CloudinaryService();

  StreamSubscription<QuerySnapshot>?
  _donationsSubscription;

  // ── Observables ─────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedImage = Rxn<PickedImage>();

  // NEW — lets one entry be a Campaign, a Project, or a Sponsor-a-Child
  // card, all stored in the SAME 'campaigns' collection (no new
  // collection/controller needed — reuses everything that already works).
  // Existing docs without this field are treated as 'campaign' everywhere
  // they're read.
  var selectedCategory = 'campaign'.obs; // 'campaign' | 'project' | 'sponsorship'

  // Form controllers
  final titleController =
  TextEditingController();

  final descController =
  TextEditingController();

  final goalController =
  TextEditingController();

  final endDateController =
  TextEditingController();

  // NEW — only used when selectedCategory == 'sponsorship'. A child
  // entry has no start/end date (it's an open-ended program, not a
  // time-bound drive), so this replaces endDateController for that case.
  final ageController = TextEditingController();

  // Needs checkboxes
  var selectedNeeds = <String>[].obs;

  final List<String> allNeeds = [
    'Food',
    'Clothes',
    'Stationery',
    'Toys',
    'Shoes',
    'Medicine',
    'Furniture',
    'Blankets',
    'Hygiene Kits',
  ];

  @override
  void onInit() {
    super.onInit();

    _listenForCampaignRaisedAmounts();
  }

  @override
  void onClose() {
    _donationsSubscription?.cancel();

    titleController.dispose();
    descController.dispose();
    goalController.dispose();
    endDateController.dispose();
    ageController.dispose(); // NEW

    super.onClose();
  }

  // ── Raised Amount Sync ──────────────────────────────────────
  void _listenForCampaignRaisedAmounts() {
    _donationsSubscription = _db
        .collection('donations')
        .snapshots(includeMetadataChanges: true) // FIXED (Bug 10) — so the cache -> server transition also raises an event
        .listen((snapshot) async {
      // FIXED (Bug 10) — never recompute totals from data that is only in the local
      // cache or still has unacknowledged local writes. On mobile the first snapshot
      // can come from a partial cache and used to WRITE a too-small total to Firestore.
      if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) return;
      try {
        await _syncCampaignRaisedAmounts(
          snapshot.docs,
        );
      } catch (_) {
        // Campaign UI aur existing system ko crash nahi karna.
      }
    });
  }

  // FIXED (Bug 10) — this listener used to start a new async sync for every donations
  // change without waiting for the previous one. Two overlapping runs could finish out
  // of order, so an OLDER snapshot's total could overwrite a newer, correct one and
  // stay wrong until the next donation change. Now only one sync runs at a time, and
  // while it runs only the LATEST snapshot is remembered and processed afterwards.
  bool _raisedSyncRunning = false;
  List<QueryDocumentSnapshot>? _pendingRaisedSyncDocs;

  Future<void> _syncCampaignRaisedAmounts(
      List<QueryDocumentSnapshot> donations,
      ) async {
    if (_raisedSyncRunning) {
      _pendingRaisedSyncDocs = donations;
      return;
    }
    _raisedSyncRunning = true;
    try {
      List<QueryDocumentSnapshot>? next = donations;
      while (next != null) {
        _pendingRaisedSyncDocs = null;
        try {
          await _doSyncCampaignRaisedAmounts(next);
        } catch (_) {
          // Same as before: a failed sync must never crash the Campaign UI.
        }
        next = _pendingRaisedSyncDocs;
      }
    } finally {
      _raisedSyncRunning = false;
    }
  }

  // The original sync body — unchanged, only renamed so the wrapper above can call it.
  Future<void> _doSyncCampaignRaisedAmounts(
      List<QueryDocumentSnapshot> donations,
      ) async {
    final campaignSnapshot =
    await _db.collection('campaigns').get();

    if (campaignSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();
    bool hasUpdates = false;

    for (final campaignDoc
    in campaignSnapshot.docs) {
      final campaignData =
      campaignDoc.data();

      // NEW — a child's "collected" amount means current active
      // monthly sponsorship coverage, not a lifetime donation sum —
      // a different concept computed separately (sponsorships
      // collection), so this generic campaign/project sync must not
      // touch sponsorship-category docs.
      if ((campaignData['category'] ?? 'campaign') == 'sponsorship') {
        continue;
      }

      final campaignTitle =
      (campaignData['title'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      double raised = 0;

      for (final donationDoc in donations) {
        final data = donationDoc.data()
        as Map<String, dynamic>;

        if (data['isDeleted'] == true) {
          continue;
        }

        final status =
        (data['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final validStatus =
            status == 'approved' ||
                status == 'completed' ||
                status == 'complete';

        if (!validStatus) {
          continue;
        }

        final isFund =
            data['type'] == 'fund' ||
                data.containsKey('amount') ||
                data.containsKey(
                    'paymentProofUrl');

        if (!isFund) {
          continue;
        }

        final donationCampaignId =
        (data['campaignId'] ?? '')
            .toString()
            .trim();

        final donationCampaignName =
        (data['campaignName'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final matchesById =
            donationCampaignId.isNotEmpty &&
                donationCampaignId ==
                    campaignDoc.id;

        final matchesByName =
            campaignTitle.isNotEmpty &&
                donationCampaignName.isNotEmpty &&
                donationCampaignName ==
                    campaignTitle;

        if (!matchesById &&
            !matchesByName) {
          continue;
        }

        final dynamic amountValue =
            data['verifiedAmount'] ??
                data['amount'];

        if (amountValue is num) {
          raised += amountValue.toDouble();
        } else {
          raised += double.tryParse(
            amountValue?.toString() ?? '',
          ) ??
              0;
        }
      }

      final currentValue =
      campaignData['collectedAmount'];

      final double current =
      currentValue is num
          ? currentValue.toDouble()
          : double.tryParse(
        currentValue?.toString() ??
            '',
      ) ??
          0;

      if ((current - raised).abs() > 0.01) {
        batch.update(
          campaignDoc.reference,
          {
            'collectedAmount': raised,
          },
        );

        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  // ── Pick Image ────────────────────────────────────────────── (CHANGED)
  Future<void> pickImage() async {
    final XFile? image =
    await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    selectedImage.value = await PickedImage.fromXFile(image);
  }

  // ── Toggle Need ─────────────────────────────────────────────
  void toggleNeed(String need) {
    if (selectedNeeds.contains(need)) {
      selectedNeeds.remove(need);
    } else {
      selectedNeeds.add(need);
    }
  }

  // ── Select Type (Campaign / Project / Sponsor a Child) ───────
  // NEW — centralizes what changes when the Admin switches the
  // "Type" chip, instead of the UI setting selectedCategory.value
  // directly. A child's monthly amount is a FIXED, program-wide
  // figure (the 6 sponsorship categories always sum to Rs. 30,000 —
  // see SponsorshipCategories.fullMonthlyAmount in
  // lib/models/sponsorship_categories.dart), so it is set
  // automatically here rather than left for the Admin to type and
  // possibly get wrong.
  void selectCategory(String value) {
    selectedCategory.value = value;
    if (value == 'sponsorship') {
      goalController.text = '30000';
    } else if (goalController.text == '30000') {
      // Only clear if it still holds the auto-filled sponsorship
      // value — an Admin's own typed 30000 for a real campaign is
      // left untouched.
      goalController.clear();
    }
  }

  // ── Clear Form ──────────────────────────────────────────────
  void clearForm() {
    titleController.clear();
    descController.clear();
    goalController.clear();
    endDateController.clear();
    ageController.clear(); // NEW

    selectedImage.value = null;
    selectedNeeds.clear();
    selectedCategory.value = 'campaign'; // NEW
  }

  // ── Add Campaign ──────────────────────────────────────────── (CHANGED upload line only)
  Future<bool> addCampaign() async {
    final bool isSponsorship = selectedCategory.value == 'sponsorship';

    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        goalController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill all required fields',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return false;
    }

    // NEW — a child card is far less useful without a photo and age,
    // so these are required only for the sponsorship type. Campaign
    // and Project keep exactly the validation they had before.
    if (isSponsorship &&
        (ageController.text.trim().isEmpty || selectedImage.value == null)) {
      Get.snackbar(
        'Missing Fields',
        'Please add the child\'s age and a photo.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return false;
    }

    isLoading.value = true;

    try {
      String imageUrl = '';

      if (selectedImage.value != null) {
        final String? url =
        await selectedImage.value!.upload(_cloudinary);

        if (url != null) {
          imageUrl = url;
        }
      }

      await _db.collection('campaigns').add({
        'title':
        titleController.text.trim(),
        'description':
        descController.text.trim(),
        // NEW — sponsorship's monthly amount is always the fixed
        // program total, never a typed value. Campaign/Project keep
        // reading whatever the Admin entered, unchanged.
        'goalAmount': isSponsorship
            ? SponsorshipCategories.fullMonthlyAmount
            : (double.tryParse(goalController.text.trim()) ?? 0),
        'collectedAmount': 0,
        'image': imageUrl,
        'endDate':
        endDateController.text.trim(),
        'needs':
        selectedNeeds.toList(),
        'category': selectedCategory.value, // NEW — campaign | project | sponsorship
        'age': ageController.text.trim(), // NEW — sponsorship only; empty otherwise
        'isActive': true,
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      clearForm();

      Get.snackbar(
        'Success',
        'Campaign added successfully!',
        backgroundColor:
        Colors.green[50],
        colorText:
        Colors.green[700],
        snackPosition:
        SnackPosition.BOTTOM,
        margin:
        const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add campaign. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition:
        SnackPosition.BOTTOM,
        margin:
        const EdgeInsets.all(16),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete Campaign ─────────────────────────────────────────
  Future<void> deleteCampaign(
      String docId,
      ) async {
    try {
      await _db
          .collection('campaigns')
          .doc(docId)
          .delete();

      Get.snackbar(
        'Deleted',
        'Campaign removed.',
        backgroundColor:
        Colors.orange[50],
        colorText:
        Colors.orange[700],
        snackPosition:
        SnackPosition.BOTTOM,
        margin:
        const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete. Try again.',
        snackPosition:
        SnackPosition.BOTTOM,
      );
    }
  }

  // ── Toggle Active ───────────────────────────────────────────
  Future<void> toggleActive(
      String docId,
      bool current,
      ) async {
    await _db
        .collection('campaigns')
        .doc(docId)
        .update({
      'isActive': !current,
    });
  }

  // ── Real-time Stream ────────────────────────────────────────
  Stream<QuerySnapshot>
  get campaignsStream => _db
      .collection('campaigns')
      .orderBy(
    'createdAt',
    descending: true,
  )
      .snapshots();
}