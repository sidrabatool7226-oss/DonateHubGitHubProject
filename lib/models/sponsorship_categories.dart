// ============================================================
// FILE: lib/models/sponsorship_categories.dart (NEW)
//
// PURPOSE
// Single source of truth for the 6 fixed "Sponsor a Child"
// categories and their monthly amounts (sum = Rs. 30,000 = Full
// Sponsorship). Matches Little Smiles Orphan Home's existing
// printed sponsorship flyer exactly, so the app doesn't show a
// different breakdown than what donors already see in marketing
// material.
//
// Used by:
//   - CampaignController (Admin "Add Child Sponsorship" form —
//     just displays the fixed total, doesn't let it be edited)
//   - The Donor-side Full/Partial category picker (Phase 2)
//   - Sponsorship monitoring screens (Phase 3)
//
// Deliberately a plain Dart class (no Firestore read) — these
// amounts are a fixed program policy, not admin-editable data,
// so there's nothing to fetch and nothing that can drift out of
// sync between screens.
// ============================================================

class SponsorshipCategory {
  final String name;
  final int monthlyAmount;
  final String icon; // Material icon name, resolved by the UI layer

  const SponsorshipCategory({
    required this.name,
    required this.monthlyAmount,
    required this.icon,
  });
}

class SponsorshipCategories {
  static const List<SponsorshipCategory> all = [
    SponsorshipCategory(name: 'Food & Nutrition', monthlyAmount: 12000, icon: 'restaurant_rounded'),
    SponsorshipCategory(name: 'Education & School Supplies', monthlyAmount: 5000, icon: 'menu_book_rounded'),
    SponsorshipCategory(name: 'Health & Medical', monthlyAmount: 3000, icon: 'medical_services_rounded'),
    SponsorshipCategory(name: 'Utilities', monthlyAmount: 4000, icon: 'bolt_rounded'),
    SponsorshipCategory(name: 'Clothing & Essentials', monthlyAmount: 3000, icon: 'checkroom_rounded'),
    SponsorshipCategory(name: 'Care & Daily Needs', monthlyAmount: 3000, icon: 'volunteer_activism_rounded'),
  ];

  /// Rs. 30,000 — the Full Sponsorship monthly amount. Always kept
  /// equal to the sum of [all] above; a test/assertion for this is
  /// intentionally NOT added here to keep this file dependency-free,
  /// but any future edit to the list above must keep the two in sync.
  static const int fullMonthlyAmount = 30000;

  static SponsorshipCategory? byName(String name) {
    for (final c in all) {
      if (c.name == name) return c;
    }
    return null;
  }
}