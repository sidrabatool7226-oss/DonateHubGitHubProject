// ============================================================
// FILE: lib/models/payment_account.dart (NEW)
// Little Smiles Orphan Home's confirmed payment accounts.
// These are the ONLY real accounts — do not add/invent others.
// ============================================================

class PaymentAccount {
  final String method;        // 'jazzcash' | 'easypaisa' | 'nayapay' | 'sadapay' | 'meezan'
  final String label;
  final String accountTitle;
  final String accountNumber; // mobile number or bank account number
  final String? iban;
  final String? bankName;
  final String logoAsset;

  const PaymentAccount({
    required this.method,
    required this.label,
    required this.accountTitle,
    required this.accountNumber,
    this.iban,
    this.bankName,
    required this.logoAsset,
  });
}

class PaymentAccounts {
  // NOTE: logoAsset filenames are a guess — if your actual asset
  // filenames differ, update the strings below. The widget that
  // displays these (payment_account_card.dart) falls back to an
  // icon automatically if the asset is missing, so nothing crashes.
  static const List<PaymentAccount> all = [
    PaymentAccount(
      method: 'jazzcash',
      label: 'JazzCash',
      accountTitle: 'Muhammad Haris',
      accountNumber: '03185702002',
      logoAsset: 'assets/images/jazzcash_logo.png',
    ),
    PaymentAccount(
      method: 'easypaisa',
      label: 'EasyPaisa',
      accountTitle: 'Muhammad Haris',
      accountNumber: '03126416978',
      logoAsset: 'assets/images/easypaisa_logo.png',
    ),
    PaymentAccount(
      method: 'nayapay',
      label: 'NayaPay',
      accountTitle: 'Muhammad Haris',
      accountNumber: '03355251494',
      logoAsset: 'assets/images/nayapay_logo.png',
    ),
    PaymentAccount(
      method: 'sadapay',
      label: 'SadaPay',
      accountTitle: 'Muhammad Haris',
      accountNumber: '03355251494',
      logoAsset: 'assets/images/sadapay_logo.png',
    ),
    PaymentAccount(
      method: 'meezan',
      label: 'Meezan Bank',
      accountTitle: 'LITTLE SMILES HOME',
      accountNumber: '03230114106882',
      iban: 'PK62MEZN0003230114106882',
      bankName: 'Meezan Bank',
      logoAsset: 'assets/images/meezan_logo.png',
    ),
  ];

  static PaymentAccount? byMethod(String method) {
    try {
      return all.firstWhere((a) => a.method == method);
    } catch (_) {
      return null;
    }
  }
}