import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/cloudinary_service.dart';

class CampaignController extends GetxController {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final CloudinaryService _cloudinary =
  CloudinaryService();

  StreamSubscription<QuerySnapshot>?
  _donationsSubscription;

  // ── Observables ─────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedImage = Rxn<File>();

  // Form controllers
  final titleController =
  TextEditingController();

  final descController =
  TextEditingController();

  final goalController =
  TextEditingController();

  final endDateController =
  TextEditingController();

  // Needs checkboxes
  var selectedNeeds = <String>[].obs;

  final List<String> allNeeds = [
    'Food',
    'Clothes',
    'Books',
    'Furniture',
    'Medicine',
    'Stationery',
    'Shoes',
    'Blankets',
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

    super.onClose();
  }

  // ── Raised Amount Sync ──────────────────────────────────────
  void _listenForCampaignRaisedAmounts() {
    _donationsSubscription = _db
        .collection('donations')
        .snapshots()
        .listen((snapshot) async {
      try {
        await _syncCampaignRaisedAmounts(
          snapshot.docs,
        );
      } catch (_) {
        // Campaign UI aur existing system ko crash nahi karna.
      }
    });
  }

  Future<void> _syncCampaignRaisedAmounts(
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

  // ── Pick Image ──────────────────────────────────────────────
  Future<void> pickImage() async {
    final XFile? image =
    await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      selectedImage.value =
          File(image.path);
    }
  }

  // ── Toggle Need ─────────────────────────────────────────────
  void toggleNeed(String need) {
    if (selectedNeeds.contains(need)) {
      selectedNeeds.remove(need);
    } else {
      selectedNeeds.add(need);
    }
  }

  // ── Clear Form ──────────────────────────────────────────────
  void clearForm() {
    titleController.clear();
    descController.clear();
    goalController.clear();
    endDateController.clear();

    selectedImage.value = null;
    selectedNeeds.clear();
  }

  // ── Add Campaign ────────────────────────────────────────────
  Future<bool> addCampaign() async {
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

    isLoading.value = true;

    try {
      String imageUrl = '';

      if (selectedImage.value != null) {
        final String? url =
        await _cloudinary.uploadImage(
          selectedImage.value!,
        );

        if (url != null) {
          imageUrl = url;
        }
      }

      await _db.collection('campaigns').add({
        'title':
        titleController.text.trim(),
        'description':
        descController.text.trim(),
        'goalAmount': double.tryParse(
          goalController.text.trim(),
        ) ??
            0,
        'collectedAmount': 0,
        'image': imageUrl,
        'endDate':
        endDateController.text.trim(),
        'needs':
        selectedNeeds.toList(),
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