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

// ── Task response-timeout reminder ──────────────────────────────────────
// FIXED (Bug 7) — the app tells volunteers "Please respond within 1 hour" and the
// Manager's Tasks tab draws a red border after 60 minutes, but nothing ever ACTED on
// that deadline: a manager only noticed if they happened to open the tab.
//
// Every 5 minutes this looks at tasks still in status 'assigned' (same rule the app's
// isTimedOut() uses: 60 minutes after 'assignedAt') and notifies the manager who
// assigned the task ('assignedBy'). The notification goes into the normal
// 'notifications' collection, so the listener above turns it into an FCM push and it
// also shows in the in-app bell — no changes needed in the Flutter app.
//
// It deliberately does NOT reassign anything: the manager still decides.
//   • Once per assignment — remembered in 'timeoutNotifiedFor' on the task. When a task
//     is reassigned, 'assignedAt' changes, so the reminder re-arms for the new volunteer.
//   • Tasks overdue by more than MAX_OVERDUE_MS are skipped, so the first run on old test
//     data does not flood the manager with reminders for long-forgotten tasks.
const TASK_TIMEOUT_MS = 60 * 60 * 1000;          // same 1 hour as the app
const MAX_OVERDUE_MS = 24 * 60 * 60 * 1000;      // ignore tasks stale for more than 24h
const TIMEOUT_CHECK_EVERY_MS = 5 * 60 * 1000;

let timeoutCheckRunning = false;

async function checkTimedOutTasks() {
  if (timeoutCheckRunning) return; // never let two runs overlap
  timeoutCheckRunning = true;
  try {
    // Single-field query on purpose: needs no composite Firestore index.
    const snap = await db.collection('tasks').where('status', '==', 'assigned').get();
    const now = Date.now();
    let reminded = 0;

    for (const doc of snap.docs) {
      const task = doc.data();

      // assignedAt can be briefly null right after creation (server timestamp pending).
      if (!task.assignedAt || typeof task.assignedAt.toMillis !== 'function') continue;
      if (!task.assignedBy) continue;

      const assignedMs = task.assignedAt.toMillis();
      const age = now - assignedMs;
      if (age < TASK_TIMEOUT_MS) continue;                       // still within the hour
      if (age > TASK_TIMEOUT_MS + MAX_OVERDUE_MS) continue;      // stale, skip
      if (task.timeoutNotifiedFor === assignedMs) continue;      // already reminded

      const volunteer = task.volunteerName || 'A volunteer';
      const title = task.title || task.itemName || 'a task';

      // One atomic batch: the reminder and the "already reminded" mark succeed or fail
      // together, so a failure can never cause a reminder to repeat every 5 minutes.
      const batch = db.batch();
      batch.set(db.collection('notifications').doc(), {
        toUserId: task.assignedBy,
        title: 'Task Not Responded To',
        message: `${volunteer} has not responded to "${title}" within 1 hour. You may want to reassign it.`,
        type: 'task_timeout',
        entityId: doc.id,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      batch.update(doc.ref, { timeoutNotifiedFor: assignedMs });
      await batch.commit();
      reminded++;
    }

    if (reminded > 0) console.log(`Task timeout check: reminded managers about ${reminded} task(s)`);
  } catch (e) {
    console.error('Task timeout check failed:', e.message);
  } finally {
    timeoutCheckRunning = false;
  }
}

checkTimedOutTasks();
setInterval(checkTimedOutTasks, TIMEOUT_CHECK_EVERY_MS);