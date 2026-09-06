// ============================================================
// FILE: lib/services/receipt_parser.dart (NEW)
//
// Parses raw OCR text into structured receipt data. Kept
// separate from OcrService (which only does ML Kit text
// extraction) so per-platform parsing rules can be refined
// later without touching the OCR integration.
//
// IMPORTANT: This is DATA EXTRACTION only. It does not verify
// that a payment actually occurred. Manager/Admin manual
// verification remains the final authority.
// ============================================================

class ReceiptParseResult {
  final double? amount;
  final String? transactionId;
  final String? paymentMethod;
  final String? paymentDate;
  final String rawText;

  ReceiptParseResult({
    this.amount,
    this.transactionId,
    this.paymentMethod,
    this.paymentDate,
    required this.rawText,
  });

  bool get hasAnyData =>
      amount != null || transactionId != null || paymentMethod != null;
}

class ReceiptParser {
  static ReceiptParseResult parse(String rawText) {
    return ReceiptParseResult(
      amount: _extractAmount(rawText),
      transactionId: _extractTransactionId(rawText),
      paymentMethod: _extractPaymentMethod(rawText),
      paymentDate: _extractDate(rawText),
      rawText: rawText,
    );
  }

  // Supports: Rs. 5,000 | Rs 5000 | PKR 5000 | Amount: 5000 |
  //           Paid: 5000 | Sent: 5000 | 5,000.00
  static double? _extractAmount(String text) {
    final patterns = <RegExp>[
      RegExp(r'(?:Rs\.?|PKR)\s*[:\-]?\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
      RegExp(
          r'(?:Amount|Paid|Sent|Total)\s*[:\-]?\s*(?:Rs\.?|PKR)?\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)?.replaceAll(',', '') ?? '';
        final value = double.tryParse(raw);
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  // Supports: Transaction ID | Transaction Id | Trx ID | Trx |
  //           Reference | Ref | Transaction No
  static String? _extractTransactionId(String text) {
    final pattern = RegExp(
        r'(?:Transaction\s*(?:ID|Id|No\.?)|Trx\s*(?:ID|Id)?|Ref(?:erence)?(?:\s*No\.?)?)\s*[:\-]?\s*([A-Za-z0-9]{6,25})',
        caseSensitive: false);

    final match = pattern.firstMatch(text);
    if (match != null) {
      final value = match.group(1);
      if (value != null && value.length >= 6) return value;
    }

    // Fallback: any standalone 8-20 digit sequence
    final fallback = RegExp(r'\b\d{8,20}\b').firstMatch(text);
    return fallback?.group(0);
  }

  static String? _extractPaymentMethod(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('easypaisa') || lower.contains('easy paisa')) return 'easypaisa';
    if (lower.contains('jazzcash') || lower.contains('jazz cash')) return 'jazzcash';
    if (lower.contains('nayapay') || lower.contains('naya pay')) return 'nayapay';
    if (lower.contains('sadapay') || lower.contains('sada pay')) return 'sadapay';
    if (lower.contains('meezan')) return 'meezan';
    return null;
  }

  // Best-effort date extraction — donor can correct if wrong
  static String? _extractDate(String text) {
    final patterns = <RegExp>[
      RegExp(r'\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\b'),
      RegExp(
          r'\b(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4})\b',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }
}