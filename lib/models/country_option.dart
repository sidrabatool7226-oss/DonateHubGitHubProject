// ============================================================
// FILE: lib/models/country_option.dart (NEW)
//
// PURPOSE
// Was previously a PRIVATE class + list living only inside
// signup_screen.dart, so no other screen could reuse the same
// country/dial-code/digit-length data. Donor and Volunteer
// profile editing need the exact same "how many digits is a
// valid number for this country" rule signup already has, so
// this is now a single shared source of truth both use.
// ============================================================

class CountryOption {
  final String name;
  final String dialCode;
  final int minDigits;
  final int maxDigits;
  const CountryOption(this.name, this.dialCode, this.minDigits, this.maxDigits);
}

const List<CountryOption> countries = [
  CountryOption('Pakistan', '+92', 10, 10),
  CountryOption('Afghanistan', '+93', 9, 9),
  CountryOption('Australia', '+61', 9, 9),
  CountryOption('Austria', '+43', 10, 11),
  CountryOption('Bahrain', '+973', 8, 8),
  CountryOption('Bangladesh', '+880', 10, 10),
  CountryOption('Belgium', '+32', 9, 9),
  CountryOption('Brazil', '+55', 10, 11),
  CountryOption('Canada', '+1', 10, 10),
  CountryOption('China', '+86', 11, 11),
  CountryOption('Egypt', '+20', 10, 10),
  CountryOption('France', '+33', 9, 9),
  CountryOption('Germany', '+49', 10, 11),
  CountryOption('India', '+91', 10, 10),
  CountryOption('Indonesia', '+62', 10, 12),
  CountryOption('Iran', '+98', 10, 10),
  CountryOption('Iraq', '+964', 10, 10),
  CountryOption('Ireland', '+353', 9, 9),
  CountryOption('Italy', '+39', 9, 10),
  CountryOption('Japan', '+81', 10, 10),
  CountryOption('Jordan', '+962', 9, 9),
  CountryOption('Kenya', '+254', 9, 9),
  CountryOption('Kuwait', '+965', 8, 8),
  CountryOption('Lebanon', '+961', 8, 8),
  CountryOption('Malaysia', '+60', 9, 10),
  CountryOption('Morocco', '+212', 9, 9),
  CountryOption('Nepal', '+977', 10, 10),
  CountryOption('Netherlands', '+31', 9, 9),
  CountryOption('New Zealand', '+64', 8, 9),
  CountryOption('Nigeria', '+234', 10, 10),
  CountryOption('Norway', '+47', 8, 8),
  CountryOption('Oman', '+968', 8, 8),
  CountryOption('Philippines', '+63', 10, 10),
  CountryOption('Poland', '+48', 9, 9),
  CountryOption('Qatar', '+974', 8, 8),
  CountryOption('Russia', '+7', 10, 10),
  CountryOption('Saudi Arabia', '+966', 9, 9),
  CountryOption('Singapore', '+65', 8, 8),
  CountryOption('South Africa', '+27', 9, 9),
  CountryOption('South Korea', '+82', 9, 10),
  CountryOption('Spain', '+34', 9, 9),
  CountryOption('Sri Lanka', '+94', 9, 9),
  CountryOption('Sweden', '+46', 7, 9),
  CountryOption('Switzerland', '+41', 9, 9),
  CountryOption('Thailand', '+66', 9, 9),
  CountryOption('Turkey', '+90', 10, 10),
  CountryOption('UAE', '+971', 9, 9),
  CountryOption('United Kingdom', '+44', 10, 10),
  CountryOption('United States', '+1', 10, 10),
  CountryOption('Yemen', '+967', 9, 9),
];

/// Finds the country whose dial code the given full number (e.g.
/// "+923001234567") starts with. Checks longer dial codes first
/// (e.g. "+971" before "+97") so a number isn't matched to the
/// wrong, shorter-prefix country.
CountryOption? countryForDialCode(String fullNumber) {
  final sorted = List<CountryOption>.from(countries)
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  for (final c in sorted) {
    if (fullNumber.startsWith(c.dialCode)) return c;
  }
  return null;
}