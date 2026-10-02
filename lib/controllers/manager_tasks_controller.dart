import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'inventory_controller.dart';
import '../services/email_service.dart';

class ManagerTasksController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailService _emailService = EmailService();

  var selectedTab = 0.obs;
  var isSaving = false.obs;

  // NEW — which volunteer's "Assign" button was pressed. The assign screen uses
  // it so only THAT card shows the progress spinner (before, every card's
  // button looked pressed because they all shared isSaving).
  var assigningVolunteerId = ''.obs;

  final List<String> tabLabels = const ['Pending', 'Active', 'Delivered', 'Completed'];

  Stream<QuerySnapshot> get approvedDonationsStream => _db
      .collection('donations')
      .where('status', isEqualTo: 'approved')
      .snapshots();

  Stream<QuerySnapshot> get allTasksStream => _db.collection('tasks').snapshots();

  bool isTimedOut(Map<String, dynamic> task) {
    if (task['status'] != 'assigned') return false;
    final ts = task['assignedAt'];
    if (ts == null) return false;
    try {
      final assignedAt = (ts as Timestamp).toDate();
      return DateTime.now().difference(assignedAt).inMinutes >= 60;
    } catch (_) {
      return false;
    }
  }

  Duration? timeRemaining(Map<String, dynamic> task) {
    if (task['status'] != 'assigned') return null;
    final ts = task['assignedAt'];
    if (ts == null) return null;
    try {
      final assignedAt = (ts as Timestamp).toDate();
      final elapsed = DateTime.now().difference(assignedAt);
      final remaining = const Duration(hours: 1) - elapsed;
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (_) {
      return null;
    }
  }

  // NEW — finds the donor's user id so the donor can be notified. Older
  // donations were saved without 'donorId', so those donors never got the
  // "volunteer assigned" notification. Falls back to 'userId', then to a lookup
  // by the donor's e-mail.
  Future<String> _resolveDonorId(Map<String, dynamic> donationData) async {
    final String direct = (donationData['donorId'] ?? donationData['userId'] ?? '').toString();
    if (direct.isNotEmpty) return direct;

    final String email =
    (donationData['userEmail'] ?? donationData['donorEmail'] ?? '').toString().trim();
    if (email.isEmpty || !email.contains('@')) return '';
    try {
      final snap = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first.id;
    } catch (_) {
      // best-effort only
    }
    return '';
  }

  // ── Assign volunteer to a donation (Resource Pickup) ────────────────────
  // FIXED: taskCategory is now ALWAYS the literal string 'Resource Pickup'
  // for donation-triggered tasks — previously this fell back to the item's
  // shopping category (Food/Clothes/etc), which never matched any
  // volunteer role and silently broke eligibility filtering.
  //
  // showMessage: the assign screen passes false and shows the "Assigned"
  // message itself AFTER it has closed. GetX's Get.back() closes an open
  // snackbar instead of the screen, so a message shown here made the screen
  // stay open and the message vanish instantly.
  Future<bool> assignVolunteer({
    required String donationId,
    required Map<String, dynamic> donationData,
    required String volunteerId,
    required String volunteerName,
    bool showMessage = true,
  }) async {
    isSaving.value = true;
    assigningVolunteerId.value = volunteerId; // NEW
    try {
      // NEW — never create a second task for a donation that already has a
      // live one (double tap, two managers, stale screen). A rejected task does
      // not count: that one is handled through Reassign.
      final existing = await _db
          .collection('tasks')
          .where('donationId', isEqualTo: donationId)
          .get();
      final bool alreadyAssigned = existing.docs.any((d) {
        final s = (d.data()['status'] ?? '').toString();
        return s == 'assigned' || s == 'accepted' || s == 'delivered' || s == 'completed';
      });
      if (alreadyAssigned) {
        Get.snackbar('Already Assigned', 'This donation already has a volunteer assigned.',
            backgroundColor: Colors.orange[50], colorText: Colors.orange[800],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return false;
      }

      // NEW — volunteer's phone, so the donor can be told who is coming
      // and can call them. Read-only lookup of the volunteer's own user
      // doc; nothing else from that doc (CNIC, email, reward points,
      // home address, etc.) is read or stored anywhere here.
      String volunteerPhone = '';
      try {
        final volunteerDoc = await _db.collection('users').doc(volunteerId).get();
        volunteerPhone = (volunteerDoc.data()?['mobileNumber'] ??
            volunteerDoc.data()?['phone'] ?? // FIXED (Bug 6) — volunteers who only filled the form have 'phone'
            '')
            .toString();
      } catch (_) {
        // Best-effort only — assignment must not fail if this lookup fails.
      }

      final String itemName = (donationData['itemName'] ?? '').toString();
      final quantity = donationData['quantity'] ?? 1;
      final String pickupAddress =
      (donationData['address'] ?? donationData['pickupAddress'] ?? '').toString();

      // CHANGED — resolved donor id (also stored on the task so a later
      // reassignment / completion can still notify the donor)
      final String donorId = await _resolveDonorId(donationData);

      final taskRef = await _db.collection('tasks').add({
        'donationId': donationId,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'volunteerPhone': volunteerPhone, // NEW
        'taskCategory': 'Resource Pickup', // FIXED — was donationData['category']
        'category': _normalizeInventoryCategory(donationData['category']), // FIXED (Bug 1) — task now stores the donation's category
        'title': donationData['itemName'] ?? 'Resource Pickup',
        'itemName': donationData['itemName'] ?? '',
        'quantity': donationData['quantity'] ?? 1,
        'donorId': donorId,
        'donorName': donationData['donorName'] ??
            donationData['userEmail'] ??
            donationData['donorEmail'] ??
            'Donor',
        'pickupAddress': donationData['address'] ?? donationData['pickupAddress'] ?? '',
        'location': donationData['address'] ?? donationData['pickupAddress'] ?? '',
        'status': 'assigned',
        'assignedBy': _auth.currentUser?.uid ?? '',
        'assignedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('donations').doc(donationId).update({
        'status': 'pickup_assigned',
      });

      // → the volunteer
      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'New Pickup Task Assigned',
        'message':
        'You have been assigned to collect "${donationData['itemName'] ?? 'items'}". Please respond within 1 hour.',
        'type': 'task_assigned',
        'entityId': taskRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // → the donor
      if (donorId.isNotEmpty) {
        // NEW — richer, professional donor notification: operational
        // info only (name, phone, item, quantity, pickup address).
        // Deliberately excludes CNIC, volunteer home address, email,
        // reward points, and any other personal profile detail.
        await _db.collection('notifications').add({
          'toUserId': donorId,
          'title': 'Pickup Volunteer Assigned',
          'message': '$volunteerName has been assigned to pick up your donation.',
          'type': 'pickup_assigned',
          'entityId': donationId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'volunteerName': volunteerName,
          'volunteerPhone': volunteerPhone,
          'itemName': itemName,
          'quantity': quantity,
          'pickupAddress': pickupAddress,
        });
      }

      if (showMessage) {
        Get.snackbar('Assigned', 'Task assigned to $volunteerName',
            backgroundColor: Colors.green[50], colorText: Colors.green[700],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign task.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
      assigningVolunteerId.value = ''; // NEW
    }
  }

  Future<bool> reassignVolunteer({
    required String taskId,
    required String oldVolunteerId,
    required String newVolunteerId,
    required String newVolunteerName,
    bool showMessage = true, // NEW — see assignVolunteer
  }) async {
    isSaving.value = true;
    assigningVolunteerId.value = newVolunteerId; // NEW
    try {
      // NEW — new volunteer's phone, same read-only lookup as assignVolunteer.
      String newVolunteerPhone = '';
      try {
        final volunteerDoc = await _db.collection('users').doc(newVolunteerId).get();
        newVolunteerPhone = (volunteerDoc.data()?['mobileNumber'] ??
            volunteerDoc.data()?['phone'] ?? // FIXED (Bug 6)
            '')
            .toString();
      } catch (_) {
        // Best-effort only.
      }

      await _db.collection('tasks').doc(taskId).update({
        'volunteerId': newVolunteerId,
        'volunteerName': newVolunteerName,
        'volunteerPhone': newVolunteerPhone, // NEW
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'reassignedFrom': oldVolunteerId,
        'reassignCount': FieldValue.increment(1),
      });

      await _db.collection('notifications').add({
        'toUserId': newVolunteerId,
        'title': 'New Task Assigned',
        'message': 'You have been assigned a task. Please respond within 1 hour.',
        'type': 'task_assigned',
        'entityId': taskId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // NEW — keep the donor informed when their assigned volunteer
      // changes. All fields read here (donorId, itemName, quantity,
      // pickupAddress) already live on this same task document — no
      // extra read of the donations collection is needed.
      try {
        final taskSnap = await _db.collection('tasks').doc(taskId).get();
        final taskData = taskSnap.data() ?? {};
        final String donorId = (taskData['donorId'] ?? '').toString();
        if (donorId.isNotEmpty) {
          await _db.collection('notifications').add({
            'toUserId': donorId,
            'title': 'Pickup Volunteer Updated',
            'message': '$newVolunteerName has been assigned to pick up your donation.',
            'type': 'pickup_assigned',
            'entityId': (taskData['donationId'] ?? '').toString(),
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'volunteerName': newVolunteerName,
            'volunteerPhone': newVolunteerPhone,
            'itemName': taskData['itemName'] ?? '',
            'quantity': taskData['quantity'] ?? 1,
            'pickupAddress': taskData['pickupAddress'] ?? '',
          });
        }
      } catch (_) {
        // Best-effort only — reassignment itself must not fail if this
        // notification can't be sent.
      }

      if (showMessage) {
        Get.snackbar('Reassigned', 'Task reassigned to $newVolunteerName',
            backgroundColor: Colors.green[50], colorText: Colors.green[700],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to reassign.', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
      assigningVolunteerId.value = ''; // NEW
    }
  }

  Future<bool> completeTask({
    required String taskId,
    required Map<String, dynamic> taskData,
  }) async {
    isSaving.value = true;
    try {
      final donationId = taskData['donationId'];
      final donorId = taskData['donorId'] ?? '';
      final itemName = taskData['itemName'] ?? taskData['title'] ?? 'items';
      final category = taskData['taskCategory'] ?? 'Other';
      final quantity = taskData['quantity'] is String
          ? int.tryParse(taskData['quantity']) ?? 1
          : (taskData['quantity'] as num?)?.toInt() ?? 1;
      Map<String, dynamic> donationData = {};
      if (donationId != null && donationId.toString().isNotEmpty) {
        final donationDocSnap = await _db.collection('donations').doc(donationId).get();
        donationData = donationDocSnap.data() ?? {};
      }
      final bool alreadyEmailed = donationData['completionEmailSent'] == true;
      // FIXED (Bug 1) — tasks never stored 'category', so inventory was always 'Other'
      final String inventoryCategory = _normalizeInventoryCategory(
          taskData['category'] ?? donationData['category']);

      WriteBatch batch = _db.batch();

      batch.update(_db.collection('tasks').doc(taskId), {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (donationId != null && donationId.toString().isNotEmpty) {
        batch.update(_db.collection('donations').doc(donationId), {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      if (donorId.toString().isNotEmpty && donationData['rewardGiven'] != true) {
        batch.set(
          _db.collection('donors').doc(donorId),
          {
            'rewardPoints': FieldValue.increment(10),
            'totalDonations': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
        if (donationId != null && donationId.toString().isNotEmpty) {
          batch.update(_db.collection('donations').doc(donationId), {'rewardGiven': true});
        }
      }

      final volunteerId = taskData['volunteerId'] ?? '';
      if (volunteerId.toString().isNotEmpty) {
        batch.set(
          _db.collection('users').doc(volunteerId),
          {
            'rewardPoints': FieldValue.increment(20),
            'completedTasksCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      // Inventory auto-add only applies to actual resource pickups
      if (category == 'Resource Pickup' && donationId != null && donationId.toString().isNotEmpty) {
        try {
          await InventoryController.autoAddFromVolunteer(
            db: _db,
            itemName: itemName,
            category: inventoryCategory,
            quantity: quantity.toInt(),
            donationId: donationId,
            donorName: taskData['donorName'] ?? 'Donor',
          );
        } catch (_) {}
      }

      if (donorId.toString().isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': donorId,
          'title': '🧡 Thank You — Little Smiles Orphan Home',
          'message':
          'Your donation of "$itemName" has been successfully delivered and completed. You just made a real difference in a child\'s life!',
          'type': 'donation_completed',
          'entityId': donationId ?? '',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!alreadyEmailed && donationId != null && donationId.toString().isNotEmpty) {
          final userDoc = await _db.collection('users').doc(donorId).get();
          final userData = userDoc.data() ?? {};
          final String donorEmail = userData['email'] ?? donationData['userEmail'] ?? '';
          final String donorName = userData['name'] ?? 'Donor';

          if (donorEmail.isNotEmpty) {
            final bool emailSent = await _emailService.sendDonationCompletedEmail(
              toEmail: donorEmail,
              toName: donorName,
              amount: '',
              isFund: false,
            );
            if (emailSent) {
              await _db.collection('donations').doc(donationId).update({'completionEmailSent': true});
            }
          }
        }
      }

      Get.snackbar('Completed', 'Task marked as completed!',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete task.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // FIXED (Bug 1) — donor category 'Others' == inventory category 'Other'; empty -> 'Other'.
  String _normalizeInventoryCategory(dynamic raw) {
    final String c = (raw ?? '').toString().trim();
    if (c.isEmpty || c.toLowerCase() == 'others') return 'Other';
    return c;
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}