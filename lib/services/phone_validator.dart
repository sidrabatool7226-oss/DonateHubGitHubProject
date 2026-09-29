// ============================================================
// FILE: lib/services/phone_validator.dart (NEW)
//
// PURPOSE
// One shared validator for a mobile number, used by Donor and
// Volunteer profile editing. Pakistan gets its own two explicit
// checks (the common 11-digit local format "03XXXXXXXXX", and the
// full international "+92XXXXXXXXXX") since almost every user of
// this app is in Pakistan. For every other country, it looks up
// the matching entry in country_option.dart and checks the digit
// count against THAT country's own rule — the same rule Signup
// already enforces — instead of one generic length check for
// everyone.
// ============================================================

import '../models/country_option.dart';

String? validateMobileNumber(String value) {
  final phone = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');

  if (phone.isEmpty) {
    return 'Phone number is required.';
  }

  // Pakistan local format: 03XXXXXXXXX (11 digits, starts with 0).
  if (RegExp(r'^03\d{9}$').hasMatch(phone)) {
    return null;
  }

  // Pakistan international format: +92XXXXXXXXXX.
  if (RegExp(r'^\+92\d{10}$').hasMatch(phone)) {
    return null;
  }

  // Any other country — validated using ITS OWN digit-length rule
  // from the shared country list, not a one-size-fits-all check.
  if (phone.startsWith('+')) {
    final country = countryForDialCode(phone);
    if (country != null) {
      final digits = phone.substring(country.dialCode.length);
      if (!RegExp(r'^\d+$').hasMatch(digits)) {
        return 'Enter a valid phone number.';
      }
      if (digits.length < country.minDigits || digits.length > country.maxDigits) {
        final expected = country.minDigits == country.maxDigits
            ? '${country.minDigits}'
            : '${country.minDigits}-${country.maxDigits}';
        return '${country.name} numbers must be $expected digits after ${country.dialCode}.';
      }
      return null;
    }
    // Starts with '+' but no known dial code matched — fall through
    // to a loose general check rather than blocking an otherwise
    // reasonable-looking number outright.
  }

  // Loose fallback for a number typed without a recognised country
  // code (e.g. an old profile saved before the country was tracked).
  if (RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(phone)) {
    return null;
  }

  return 'Enter a valid phone number, including your country code (e.g. +92XXXXXXXXXX).';
}