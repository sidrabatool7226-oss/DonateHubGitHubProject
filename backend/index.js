// ============================================================
// DonateHub Notification Backend
// Listens to Firestore 'notifications' collection, sends FCM
// push via Admin SDK (v1 API). No Cloud Functions, no Blaze plan.
// Run: node index.js (keep this running on your PC during testing/demo)
// ============================================================

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

// Only process notifications created AFTER this backend started.
// Prevents replaying old history if the script restarts.
const startupTime = admin.firestore.Timestamp.now();

console.log('DonateHub notification backend started at', startupTime.toDate());

// ── Route mapping: notification 'type' → data payload for Flutter ──────
function buildRoutingData(notif) {
  return {
    notificationId: notif.id || '',
    type: notif.type || '',
    entityId: notif.entityId || '',
  };
}

// ── Get FCM tokens for a user (supports multiple devices) ──────────────
async function getTokensForUser(uid) {
  if (!uid) return [];
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) return [];
  const tokens = userDoc.data().fcmTokens;
  if (!Array.isArray(tokens)) return [];
  return tokens.filter((t) => typeof t === 'string' && t.length > 0);
}

// ── Send push to all of a user's devices ────────────────────────────────
async function sendPush(uid, title, body, dataPayload) {
  const tokens = await getTokensForUser(uid);
  if (tokens.length === 0) {
    console.log(`No FCM tokens for user ${uid} — skipping push`);
    return { sent: 0, failed: 0 };
  }

  const message = {
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(dataPayload).map(([k, v]) => [k, String(v)])
    ),
    // NAYA — manifest ke sath match
    android: {
      priority: 'high',
      notification: {
        channelId: 'donatehub_android_studio_channel',
        sound: 'default',
        priority: 'high',
        icon: 'ic_launcher', // optional polish — status bar icon
      },
    },
    tokens,
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(`Push sent to ${uid}: ${response.successCount} ok, ${response.failureCount} failed`);

    // Clean up invalid/expired tokens
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code;
        if (
          errCode === 'messaging/invalid-registration-token' ||
          errCode === 'messaging/registration-token-not-registered'
        ) {
          db.collection('users').doc(uid).update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(tokens[idx]),
          }).catch(() => {});
        }
      }
    });

    return { sent: response.successCount, failed: response.failureCount };
  } catch (e) {
    console.error(`Push send error for ${uid}:`, e.message);
    return { sent: 0, failed: tokens.length };
  }
}

// ── Main listener ────────────────────────────────────────────────────────
db.collection('notifications')
  .where('createdAt', '>', startupTime)
  .onSnapshot(
    (snapshot) => {
      snapshot.docChanges().forEach(async (change) => {
        if (change.type !== 'added') return;

        const doc = change.doc;
        const data = doc.data();

        // Idempotency — skip if already processed (e.g. listener hiccup)
        if (data.pushSent === true) return;

        const toUserId = data.toUserId;
        if (!toUserId) return;

        const routingData = buildRoutingData({ ...data, id: doc.id });

        const result = await sendPush(
          toUserId,
          data.title || 'DonateHub',
          data.message || '',
          routingData
        );

        // Mark as processed ONLY after attempting send (success or not,
        // to avoid infinite retry loop on permanently-bad data; failures
        // are logged above for manual investigation)
        await doc.ref.update({
          pushSent: result.sent > 0,
          pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
        }).catch((e) => console.error('Failed to mark pushSent:', e.message));
      });
    },
    (error) => {
      console.error('Firestore listener error:', error);
    }
  );