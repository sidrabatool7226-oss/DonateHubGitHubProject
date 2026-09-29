// ============================================================
// FILE: backend/seed_campaigns_projects.js (NEW)
//
// PURPOSE
// Creates the real Campaign and Project entries you listed
// (Bano Khudmukhtar, Kasb-e-Halaal, Education Program, Tarbiyat &
// Moral Training, Apna Ghar, IT Lab Setup, Wall of Heroes, Food
// Drive) directly in your live Firestore 'campaigns' collection —
// the exact same collection/shape the Admin app's own "Add"
// screen writes to.
//
// GOAL AMOUNTS ARE PLACEHOLDERS. I don't know your real budget
// figures for each one, so every goalAmount below is a round
// placeholder marked "EDIT ME". Change these to your real numbers
// before running, or edit them later in the Admin app itself
// (tap the campaign/project -> Edit) — this script does not need
// to be perfectly correct on the first run.
//
// PHOTOS are left empty ('') — the app shows a placeholder icon
// until a real photo is set. Uploading a photo needs Cloudinary,
// which this script does not do; add photos afterwards from the
// Admin app's Edit screen.
//
// HOW TO RUN
//   1. Open a terminal in your project's `backend` folder.
//   2. If you haven't already: npm install firebase-admin
//   3. Edit the goalAmount / description values below to match
//      what you actually want (optional, but recommended).
//   4. Run: node seed_campaigns_projects.js
//   5. Open the app as Admin -> Campaigns & Events tab — the new
//      entries will already be there.
//   6. Delete this file once you're done (it's a one-time setup
//      script, not something that should run again and again —
//      running it twice will create duplicates).
// ============================================================

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const entries = [
  // ── PROJECTS ──────────────────────────────────────────────
  {
    category: 'project',
    title: 'Bano Khudmukhtar',
    description: 'A skill-training program helping our youth become financially self-reliant.', // EDIT ME
    goalAmount: 300000, // EDIT ME
  },
  {
    category: 'project',
    title: 'Kasb-e-Halaal',
    description: 'Supporting halal, dignified sources of livelihood for the community.', // EDIT ME
    goalAmount: 300000, // EDIT ME
  },
  {
    category: 'project',
    title: 'Education Program',
    description: 'Ongoing school fees, books, and tutoring support for our children.', // EDIT ME
    goalAmount: 500000, // EDIT ME
  },
  {
    category: 'project',
    title: 'Tarbiyat & Moral Training',
    description: 'Character-building and moral education sessions for the children.', // EDIT ME
    goalAmount: 200000, // EDIT ME
  },
  {
    category: 'project',
    title: 'Apna Ghar',
    description: 'Building a permanent home and shelter for the orphanage.', // EDIT ME
    goalAmount: 2000000, // EDIT ME
  },

  // ── CAMPAIGNS ─────────────────────────────────────────────
  {
    category: 'campaign',
    title: 'IT Lab Setup',
    description: 'Setting up a computer lab so our children can learn digital skills.', // EDIT ME
    goalAmount: 400000, // EDIT ME
  },
  {
    category: 'campaign',
    title: 'Wall of Heroes',
    description: "Recognising the donors and volunteers who've made a lasting impact on our children's lives.", // EDIT ME
    goalAmount: 100000, // EDIT ME
  },
  {
    category: 'campaign',
    title: 'Food Drive',
    description: 'Collecting daily meals and groceries for the children.', // EDIT ME
    goalAmount: 250000, // EDIT ME
  },
];

async function seed() {
  for (const entry of entries) {
    const doc = {
      category: entry.category,
      title: entry.title,
      description: entry.description,
      goalAmount: entry.goalAmount,
      collectedAmount: 0,
      image: '',
      endDate: '',
      needs: [],
      age: '',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const ref = await db.collection('campaigns').add(doc);
    console.log(`Created ${entry.category}: "${entry.title}" (id: ${ref.id})`);
  }

  console.log('\nDone! All entries created. You can now edit goal amounts,');
  console.log('descriptions, and add real photos from the Admin app.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Failed to seed:', err);
  process.exit(1);
});