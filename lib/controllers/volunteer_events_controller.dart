import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class VolunteerEventsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isSaving = false.obs;

  String get uid => _auth.currentUser?.uid ?? '';

  Stream<QuerySnapshot> get eventsStream =>
      _db.collection('events').where('isActive', isEqualTo: true).snapshots();

  Stream<bool> isJoinedStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<int> participantCountStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> joinEvent(String eventId, String eventTitle) async {
    isSaving.value = true;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      await _db.collection('events').doc(eventId).collection('participants').doc(uid).set({
        'volunteerId': uid,
        'volunteerName': userData['name'] ?? 'Volunteer',
        'volunteerEmail': userData['email'] ?? '',
        'volunteerPhone': userData['phone'] ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Joined!', 'You have joined "$eventTitle"',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } catch (e) {
      Get.snackbar('Error', 'Failed to join event.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> leaveEvent(String eventId) async {
    isSaving.value = true;
    try {
      await _db.collection('events').doc(eventId).collection('participants').doc(uid).delete();
      Get.snackbar('Left Event', 'You are no longer joining this event.',
          backgroundColor: Colors.orange[50], colorText: Colors.orange[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } finally {
      isSaving.value = false;
    }
  }
}