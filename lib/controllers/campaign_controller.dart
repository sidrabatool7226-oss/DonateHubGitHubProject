import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../services/picked_image.dart';
import '../models/sponsorship_categories.dart';

class CampaignController extends GetxController {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final CloudinaryService _cloudinary =
  CloudinaryService();

  StreamSubscription<QuerySnapshot>?
  _donationsSubscription;

  var isLoading = false.obs;
  var selectedImage = Rxn<PickedImage>();


  var selectedCategory = 'campaign'.obs;

  // Form controllers
  final titleController =
  TextEditingController();

  final descController =
  TextEditingController();

  final goalController =
  TextEditingController();

  final endDateController =
  TextEditingController();
  final ageController = TextEditingController();

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

  void _listenForCampaignRaisedAmounts() {
    _donationsSubscription = _db
        .collection('donations')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) async {
      if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) return;
      try {
        await _syncCampaignRaisedAmounts(
          snapshot.docs,
        );
      } catch (_) {
      }
    });
  }

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
        }
        next = _pendingRaisedSyncDocs;
      }
    } finally {
      _raisedSyncRunning = false;
    }
  }

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

  // Pick Image
  Future<void> pickImage() async {
    final XFile? image =
    await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    selectedImage.value = await PickedImage.fromXFile(image);
  }

  // Toggle Need
  void toggleNeed(String need) {
    if (selectedNeeds.contains(need)) {
      selectedNeeds.remove(need);
    } else {
      selectedNeeds.add(need);
    }
  }

  void selectCategory(String value) {
    selectedCategory.value = value;
    if (value == 'sponsorship') {
      goalController.text = '30000';
    } else if (goalController.text == '30000') {

      goalController.clear();
    }
  }

  // Clear Form
  void clearForm() {
    titleController.clear();
    descController.clear();
    goalController.clear();
    endDateController.clear();
    ageController.clear();

    selectedImage.value = null;
    selectedNeeds.clear();
    selectedCategory.value = 'campaign';
  }

  // Add Campaign
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
        'category': selectedCategory.value,
        'age': ageController.text.trim(),
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

  //  Delete Campaign
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

  //  Toggle Active
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

  Stream<QuerySnapshot>
  get campaignsStream => _db
      .collection('campaigns')
      .orderBy(
    'createdAt',
    descending: true,
  )
      .snapshots();
}