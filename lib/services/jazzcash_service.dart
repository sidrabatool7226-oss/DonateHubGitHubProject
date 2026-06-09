// ============================================================
// FILE: lib/services/jazzcash_service.dart
// ============================================================

class JazzCashService {
  static String getPaymentUrl({
    required double amount,
  }) {
    final amt = amount.toStringAsFixed(0);

    return "https://donatehub.infinityfreeapp.com/pay.php?amount=$amt";
  }
}