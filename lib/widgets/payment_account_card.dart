// ============================================================
// FILE: lib/widgets/payment_account_card.dart (NEW)
// Reusable payment method selector + account details display.
// Used by BOTH Direct Donate Funds and Campaign Fund Donation.
// ============================================================

import 'package:flutter/material.dart';
import '../models/payment_account.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final ValueChanged<String> onSelect;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onSelect,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentAccounts.all.map((account) {
        final isSelected = selectedMethod == account.method;
        return GestureDetector(
          onTap: () => onSelect(account.method),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? _green.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _green : Colors.grey[200]!,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.06 : 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      account.logoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        account.method == 'meezan'
                            ? Icons.account_balance_rounded
                            : Icons.account_balance_wallet_rounded,
                        color: _green,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    account.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? _green : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? _green : Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaymentAccountDetailsCard extends StatelessWidget {
  final PaymentAccount account;

  const PaymentAccountDetailsCard({super.key, required this.account});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Send your donation to this account',
                style: TextStyle(
                    fontSize: 12, color: _green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Account Title', account.accountTitle),
          _row(
            account.bankName != null ? 'Account Number' : 'Mobile Number',
            account.accountNumber,
          ),
          if (account.bankName != null) _row('Bank', account.bankName!),
          if (account.iban != null) _row('IBAN', account.iban!),
          const SizedBox(height: 4),
          Text(
            'Then upload your payment receipt below.',
            style: TextStyle(fontSize: 11.5, color: _green.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF14251E))),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _green),
            ),
          ),
        ],
      ),
    );
  }
}