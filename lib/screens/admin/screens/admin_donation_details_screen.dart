import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/admin_donation_kit.dart';

class AdminDonationDetailsScreen extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> initialData;

  const AdminDonationDetailsScreen({
    super.key,
    required this.donationId,
    required this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data = Map<String, dynamic>.from(initialData);

        if (snapshot.hasData && snapshot.data!.exists) {
          final freshData = snapshot.data!.data() as Map<String, dynamic>?;
          if (freshData != null) {
            data = freshData;
          }
        }

        final bool isFund = DonationKit.isFund(data);

        return Scaffold(
          backgroundColor: DonationKit.bg,
          appBar: AppBar(
            backgroundColor: DonationKit.green,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              isFund ? 'Fund Donation' : 'Resource Donation',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          body: _DetailsBody(donationId: donationId, data: data, isFund: isFund),
        );
      },
    );
  }
}

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Copied'),
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DonationKit.green,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}

Widget _stack(List<Widget> items) {
  if (items.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        items[i],
      ],
    ],
  );
}

class _Proof {
  final String label;
  final String url;
  const _Proof(this.label, this.url);
}

List<_Proof> _proofsOf(Map<String, dynamic> data) {
  final List<_Proof> out = [];
  final Set<String> seen = {};

  void add(String label, dynamic value) {
    if (value == null) return;
    final String url = value.toString().trim();
    if (url.isEmpty || !seen.add(url)) return;
    out.add(_Proof(label, url));
  }

  add('Payment proof', data['paymentProofUrl']);
  add('Screenshot', data['screenshotUrl']);
  add('Courier receipt', data['receiptImageUrl']);
  add('Item photo', data['itemImageUrl']);

  final images = data['imageUrls'];
  if (images is List) {
    int n = 0;
    for (final image in images) {
      n++;
      add(images.length > 1 ? 'Item photo $n' : 'Item photo', image);
    }
  }
  return out;
}

void _openProof(BuildContext context, _Proof proof) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  proof.url,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'Image could not be loaded',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                proof.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailsBody extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> data;
  final bool isFund;

  const _DetailsBody({
    required this.donationId,
    required this.data,
    required this.isFund,
  });

  static const Set<String> _shownKeys = {
    'type', 'amount', 'verifiedAmount', 'itemName', 'category', 'quantity',
    'condition', 'description', 'campaignName', 'campaignId',
    'donationTargetType', 'donationTargetId', 'donationTargetName',
    'generalFundPurpose', 'logisticsType', 'donationType', 'address',
    'pickupAddress', 'donorPhone', 'donorCnic', 'donorName', 'donorEmail',
    'userEmail', 'paymentMethod', 'transactionId', 'txnId', 'referenceId',
    'status', 'createdAt', 'verifiedAt', 'completedAt', 'receivedAt',
    'approvedAt', 'rejectedAt', 'rejectionReason', 'paymentProofUrl',
    'screenshotUrl', 'receiptImageUrl', 'itemImageUrl', 'imageUrls',
  };

  static const Set<String> _hiddenKeys = {
    'imageHash', 'fundsAdded', 'rewardGiven', 'verifiedBy', 'rejectedBy',
    'donorId', 'completionEmailSent', 'isDeleted', 'ocrProcessed',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final bool wide = c.maxWidth >= 860;
        final double side = c.maxWidth > 1040 ? (c.maxWidth - 1040) / 2 : 0;
        final double hp = (wide ? 24.0 : 16.0) + side;

        final bool rejected = DonationKit.stage(data['status']) == -1;

        final Widget? main = isFund ? _paymentCard() : _itemCard();
        final Widget? donor = _donorCard();
        final Widget? purpose = _purposeCard();
        final Widget? logistics = isFund ? null : _logisticsCard();
        final Widget? proofs = _proofCard();
        final Widget? more = _moreCard(context);

        final Widget cards;
        if (wide) {
          cards = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _stack([
                  if (main != null) main,
                  if (purpose != null) purpose,
                  if (logistics != null) logistics,
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _stack([
                  if (donor != null) donor,
                  if (proofs != null) proofs,
                ]),
              ),
            ],
          );
        } else {
          cards = _stack([
            if (main != null) main,
            if (donor != null) donor,
            if (purpose != null) purpose,
            if (logistics != null) logistics,
            if (proofs != null) proofs,
          ]);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hp, wide ? 24 : 16, hp, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(donationId: donationId, data: data, isFund: isFund, wide: wide),
              const SizedBox(height: 16),
              if (rejected) ...[
                _RejectedBanner(data: data),
                const SizedBox(height: 16),
              ],
              _ProgressCard(data: data, isFund: isFund),
              const SizedBox(height: 16),
              cards,
              if (more != null) ...[
                const SizedBox(height: 16),
                more,
              ],
            ],
          ),
        );
      },
    );
  }

  void _addKV(List<Widget> rows, String label, dynamic value, {bool copy = false}) {
    final String text = DonationKit.valueText(value);
    if (text.isEmpty) return;
    rows.add(_KV(label: label, value: text, copy: copy));
  }

  Widget? _paymentCard() {
    final double submitted = DonationKit.numOf(data['amount']);
    final double verified = DonationKit.numOf(data['verifiedAmount']);
    final bool differs = data['amount'] != null &&
        data['verifiedAmount'] != null &&
        (verified - submitted).abs() > 0.009;

    final List<Widget> rows = [];
    if (differs) {
      rows.add(_KV(label: 'Submitted', value: DonationKit.money(submitted)));
      rows.add(_KV(label: 'Verified', value: DonationKit.money(verified), emphasize: true));
    } else {
      rows.add(_KV(
        label: 'Amount',
        value: DonationKit.money(DonationKit.amountOf(data)),
        emphasize: true,
      ));
    }
    _addKV(rows, 'Method', data['paymentMethod']);
    _addKV(rows, 'Transaction ID', data['transactionId'] ?? data['txnId'], copy: true);
    _addKV(rows, 'Reference ID', data['referenceId'], copy: true);

    return _InfoCard(
      icon: Icons.payments_rounded,
      color: DonationKit.green,
      title: 'Payment',
      child: Column(children: rows),
    );
  }

  Widget? _itemCard() {
    final List<Widget> rows = [];
    _addKV(rows, 'Item', data['itemName']);
    _addKV(rows, 'Category', data['category']);
    _addKV(rows, 'Quantity', data['quantity']);
    _addKV(rows, 'Condition', data['condition']);
    final String description = DonationKit.valueText(data['description']);
    if (description.isNotEmpty) {
      rows.add(_Block(label: 'Description', text: description));
    }
    if (rows.isEmpty) return null;
    return _InfoCard(
      icon: Icons.inventory_2_rounded,
      color: DonationKit.teal,
      title: 'Item',
      child: Column(children: rows),
    );
  }

  // Donor
  Widget? _donorCard() {
    final String name = DonationKit.valueText(data['donorName']);
    final String email = DonationKit.valueText(data['userEmail'] ?? data['donorEmail']);
    final String phone = DonationKit.valueText(data['donorPhone']);
    final String cnic = isFund ? '' : DonationKit.valueText(data['donorCnic']);
    if (name.isEmpty && email.isEmpty && phone.isEmpty && cnic.isEmpty) return null;

    final String initialSource = name.isNotEmpty ? name : email;
    final String initial =
    initialSource.isEmpty ? '' : initialSource[0].toUpperCase();

    final List<Widget> rows = [];
    if (phone.isNotEmpty) rows.add(_KV(label: 'Phone', value: phone, copy: true));
    if (cnic.isNotEmpty) rows.add(_KV(label: 'CNIC', value: cnic, copy: true));

    return _InfoCard(
      icon: Icons.person_rounded,
      color: const Color(0xFF6A1B9A),
      title: 'Donor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFF3E5F5),
                child: initial.isEmpty
                    ? const Icon(Icons.person_rounded, color: Color(0xFF6A1B9A))
                    : Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF6A1B9A),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Donor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: DonationKit.ink,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...rows,
          ],
        ],
      ),
    );
  }

  Widget? _purposeCard() {
    if (isFund) {
      final String key = DonationKit.purposeKey(data);
      final DonationPurposeStyle ps = DonationKit.purposeStyle(key);
      final String name = DonationKit.targetName(data);
      final String note = DonationKit.valueText(data['generalFundPurpose']);

      return _InfoCard(
        icon: ps.icon,
        color: ps.color,
        title: 'Donated to',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ps.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ps.icon, size: 14, color: ps.color),
                  const SizedBox(width: 6),
                  Text(
                    ps.single,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ps.color,
                    ),
                  ),
                ],
              ),
            ),
            if (name.isNotEmpty && key != 'general_fund') ...[
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DonationKit.ink,
                ),
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Block(label: 'Purpose', text: note),
            ],
          ],
        ),
      );
    }

    final String campaign = DonationKit.valueText(data['campaignName']);
    if (campaign.isEmpty) return null;
    return _InfoCard(
      icon: Icons.campaign_rounded,
      color: DonationKit.green,
      title: 'Donated to',
      child: Text(
        campaign,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: DonationKit.ink,
        ),
      ),
    );
  }

  Widget? _logisticsCard() {
    final String raw =
    DonationKit.valueText(data['logisticsType'] ?? data['donationType']);
    final String address =
    DonationKit.valueText(data['address'] ?? data['pickupAddress']);
    if (raw.isEmpty && address.isEmpty) return null;

    String label = DonationKit.pretty(raw);
    IconData icon = Icons.local_shipping_rounded;
    switch (raw.toLowerCase()) {
      case 'online':
        label = 'Courier (online)';
        icon = Icons.local_shipping_rounded;
        break;
      case 'desk':
        label = 'Drop-off at desk';
        icon = Icons.store_mall_directory_rounded;
        break;
      case 'pickup':
        label = 'Volunteer pickup';
        icon = Icons.directions_walk_rounded;
        break;
    }

    return _InfoCard(
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFFE65100),
      title: 'Delivery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (raw.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: const Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
          if (address.isNotEmpty) ...[
            SizedBox(height: raw.isNotEmpty ? 12 : 0),
            _Block(label: 'Address', text: address),
          ],
        ],
      ),
    );
  }

  // Proof images
  Widget? _proofCard() {
    final List<_Proof> proofs = _proofsOf(data);
    if (proofs.isEmpty) return null;
    return _InfoCard(
      icon: Icons.image_rounded,
      color: const Color(0xFF1565C0),
      title: 'Proof & photos',
      child: _ProofGrid(proofs: proofs),
    );
  }
  Widget? _moreCard(BuildContext context) {
    final entries = data.entries
        .where((e) =>
    !_shownKeys.contains(e.key) &&
        !_hiddenKeys.contains(e.key) &&
        DonationKit.hasValue(e.value))
        .toList();
    if (entries.isEmpty) return null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF455A64)),
          ),
          title: Text(
            'More details (${entries.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DonationKit.ink,
            ),
          ),
          children: [
            for (final e in entries)
              _KV(
                label: DonationKit.pretty(e.key),
                value: DonationKit.valueText(e.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> data;
  final bool isFund;
  final bool wide;

  const _Hero({
    required this.donationId,
    required this.data,
    required this.isFund,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final DonationStatusStyle st = DonationKit.statusStyle(data['status']);

    final String item = DonationKit.valueText(data['itemName']);
    final String category = DonationKit.valueText(data['category']);
    final String qty = DonationKit.valueText(data['quantity']);

    final String primary = isFund
        ? DonationKit.money(DonationKit.amountOf(data))
        : (item.isNotEmpty
        ? item
        : (category.isNotEmpty ? category : 'Resource donation'));

    String secondary;
    if (isFund) {
      final String key = DonationKit.purposeKey(data);
      final DonationPurposeStyle ps = DonationKit.purposeStyle(key);
      final String name = DonationKit.targetName(data);
      secondary = (name.isEmpty || key == 'general_fund') ? ps.single : '${ps.single}  ·  $name';
    } else {
      secondary = [
        if (category.isNotEmpty && category != primary) category,
        if (qty.isNotEmpty) 'Qty $qty',
      ].join('  ·  ');
    }

    final List<Color> colors = isFund
        ? const [Color(0xFF1B6B3A), Color(0xFF2D8A52)]
        : const [Color(0xFF00695C), Color(0xFF00838F)];

    final String donor = DonationKit.valueText(data['donorName']).isNotEmpty
        ? DonationKit.valueText(data['donorName'])
        : DonationKit.valueText(data['userEmail'] ?? data['donorEmail']);
    final String submitted = DonationKit.fmtDate(data['createdAt']);
    final String ref = donationId.length > 8
        ? donationId.substring(0, 8).toUpperCase()
        : donationId.toUpperCase();

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              isFund ? Icons.payments_rounded : Icons.inventory_2_rounded,
              size: wide ? 180 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFund ? Icons.payments_rounded : Icons.inventory_2_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isFund ? 'FUND DONATION' : 'RESOURCE DONATION',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: st.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          st.label,
                          style: TextStyle(
                            color: st.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: wide ? 24 : 18),
              Text(
                primary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 40 : 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: wide ? 15 : 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              SizedBox(height: wide ? 22 : 18),
              Divider(height: 1, color: Colors.white.withOpacity(0.2)),
              SizedBox(height: wide ? 18 : 14),
              Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  _HeroMeta(label: 'REFERENCE', value: ref, copyValue: donationId),
                  if (donor.isNotEmpty) _HeroMeta(label: 'DONOR', value: donor),
                  if (submitted.isNotEmpty) _HeroMeta(label: 'SUBMITTED', value: submitted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  final String label;
  final String value;
  final String? copyValue;
  const _HeroMeta({required this.label, required this.value, this.copyValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (copyValue != null) ...[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _copy(context, copyValue!),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
class _RejectedBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RejectedBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final String reason = DonationKit.valueText(data['rejectionReason']);
    final String when = DonationKit.fmtDate(data['rejectedAt']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5C2C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_rounded, color: Color(0xFFC62828), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This donation was rejected',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: DonationKit.ink,
                      height: 1.35,
                    ),
                  ),
                ],
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(when, style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final dynamic when;
  const _Step(this.label, this.when);
}

class _ProgressCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFund;
  const _ProgressCard({required this.data, required this.isFund});

  @override
  Widget build(BuildContext context) {
    final int stage = DonationKit.stage(data['status']);
    final bool rejected = stage == -1;

    final List<_Step> steps;
    final int current;
    if (rejected) {
      steps = [
        _Step('Submitted', data['createdAt']),
        _Step('Rejected', data['rejectedAt']),
      ];
      current = 1;
    } else if (isFund) {
      steps = [
        _Step('Submitted', data['createdAt']),
        _Step('Verified', data['approvedAt'] ?? data['verifiedAt']),
      ];
      current = stage >= 1 ? 1 : 0;
    } else {
      steps = [
        _Step('Submitted', data['createdAt']),
        _Step('Approved', data['approvedAt'] ?? data['verifiedAt']),
        _Step('In progress', data['receivedAt']),
        _Step('Completed', data['completedAt']),
      ];
      current = stage;
    }

    const Color red = Color(0xFFC62828);
    const Color grey = Color(0xFFD5DBD9);

    Color nodeColor(int i) =>
        (rejected && i == steps.length - 1) ? red : DonationKit.green;

    return _InfoCard(
      icon: Icons.timeline_rounded,
      color: rejected ? red : DonationKit.green,
      title: 'Progress',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++)
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= current ? nodeColor(i) : grey),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: i <= current ? nodeColor(i) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i <= current ? nodeColor(i) : grey,
                            width: 2,
                          ),
                          boxShadow: i == current
                              ? [
                            BoxShadow(
                              color: nodeColor(i).withOpacity(0.25),
                              spreadRadius: 4,
                              blurRadius: 0,
                            ),
                          ]
                              : null,
                        ),
                        child: i <= current
                            ? Icon(
                          (rejected && i == steps.length - 1)
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i == steps.length - 1
                              ? Colors.transparent
                              : (i < current ? nodeColor(i + 1) : grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    steps[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: i <= current ? FontWeight.w800 : FontWeight.w500,
                      color: i <= current ? DonationKit.ink : Colors.grey[500],
                    ),
                  ),
                  if (DonationKit.shortDate(steps[i].when).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      DonationKit.shortDate(steps[i].when),
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: DonationKit.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  final bool copy;
  final bool emphasize;

  const _KV({
    required this.label,
    required this.value,
    this.copy = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                label,
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: emphasize ? 15.5 : 13.5,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? DonationKit.green : DonationKit.ink,
                height: 1.3,
              ),
            ),
          ),
          if (copy)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _copy(context, value),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String label;
  final String text;
  const _Block({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: DonationKit.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// PROOF IMAGES
class _ProofGrid extends StatelessWidget {
  final List<_Proof> proofs;
  const _ProofGrid({required this.proofs});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 12;
        final int cols = constraints.maxWidth >= 460 ? 3 : 2;
        final double w = ((constraints.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final p in proofs) _ProofTile(proof: p, width: w),
          ],
        );
      },
    );
  }
}

class _ProofTile extends StatelessWidget {
  final _Proof proof;
  final double width;
  const _ProofTile({required this.proof, required this.width});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openProof(context, proof),
        child: SizedBox(
          width: width,
          height: width * 0.82,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFFEFF2F1)),
                Image.network(
                  proof.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DonationKit.green,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 30),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.62)],
                      ),
                    ),
                    child: Text(
                      proof.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_out_map_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}