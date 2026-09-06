import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDonationDetailsScreen
    extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> initialData;

  const AdminDonationDetailsScreen({
    super.key,
    required this.donationId,
    required this.initialData,
  });

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  bool _isFund(Map<String, dynamic> data) {
    return data['type'] == 'fund' ||
        data.containsKey('amount') ||
        data.containsKey('paymentProofUrl');
  }

  String _text(dynamic value) {
    if (value == null) return 'Not provided';

    if (value is Timestamp) {
      final d = value.toDate();

      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }

    if (value is List) {
      if (value.isEmpty) return 'Not provided';
      return value.join(', ');
    }

    if (value is Map) {
      if (value.isEmpty) return 'Not provided';

      return value.entries
          .map(
            (entry) =>
        '${entry.key}: ${entry.value}',
      )
          .join(', ');
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return 'Not provided';
    }

    return text;
  }

  String _status(dynamic value) {
    final status =
        value?.toString().trim().toLowerCase() ??
            'pending';

    if (status == 'complete' ||
        status == 'completed') {
      return 'Completed';
    }

    return status
        .split('_')
        .map(
          (word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data =
        Map<String, dynamic>.from(initialData);

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final freshData = snapshot.data!.data()
          as Map<String, dynamic>?;

          if (freshData != null) {
            data = freshData;
          }
        }

        final bool isFund = _isFund(data);

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              isFund
                  ? 'Fund Donation Details'
                  : 'Resource Donation Details',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _buildBody(
            data,
            isFund,
          ),
        );
      },
    );
  }

  Widget _buildBody(
      Map<String, dynamic> data,
      bool isFund,
      ) {
    final renderedKeys = <String>{
      'type',
      'amount',
      'verifiedAmount',
      'itemName',
      'category',
      'quantity',
      'condition',
      'description',
      'campaignName',
      'campaignId',
      'logisticsType',
      'donationType',
      'address',
      'donorPhone',
      'donorCnic',
      'donorName',
      'donorEmail',
      'userEmail',
      'paymentMethod',
      'transactionId',
      'txnId',
      'referenceId',
      'status',
      'createdAt',
      'verifiedAt',
      'completedAt',
      'receivedAt',
      'approvedAt',
      'rejectedAt',
      'paymentProofUrl',
      'receiptImageUrl',
      'itemImageUrl',
      'imageUrls',
    };

    final extraEntries = data.entries.where(
          (entry) => !renderedKeys.contains(entry.key),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFund
                ? const Color(0xFFF3E5F5)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  isFund
                      ? Icons.payments_rounded
                      : Icons.inventory_2_rounded,
                  color: isFund
                      ? const Color(0xFF6A1B9A)
                      : _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFund
                          ? 'FUND DONATION'
                          : 'RESOURCE DONATION',
                      style: TextStyle(
                        fontSize: 11,
                        color: isFund
                            ? const Color(0xFF6A1B9A)
                            : _green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isFund
                          ? 'Rs. ${_text(data['verifiedAmount'] ?? data['amount'])}'
                          : _text(
                        data['itemName'] ??
                            data['category'],
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                _status(data['status']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _section(
          'Donation Information',
          [
            _row(
              'Donation ID',
              donationId,
            ),
            _row(
              'Type',
              isFund
                  ? 'Fund Donation'
                  : 'Resource Donation',
            ),
            _row(
              'Status',
              _status(data['status']),
            ),
            _row(
              'Created At',
              data['createdAt'],
            ),
          ],
        ),
        const SizedBox(height: 14),

        _section(
          'Donor Information',
          [
            _row(
              'Donor Name',
              data['donorName'],
            ),
            _row(
              'Email',
              data['userEmail'] ??
                  data['donorEmail'],
            ),
            _row(
              'Phone',
              data['donorPhone'],
            ),
            if (!isFund)
              _row(
                'CNIC',
                data['donorCnic'],
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (isFund)
          _section(
            'Fund Details',
            [
              _row(
                'Submitted Amount',
                data['amount'] != null
                    ? 'Rs. ${_text(data['amount'])}'
                    : null,
              ),
              _row(
                'Verified Amount',
                data['verifiedAmount'] != null
                    ? 'Rs. ${_text(data['verifiedAmount'])}'
                    : null,
              ),
              _row(
                'Payment Method',
                data['paymentMethod'],
              ),
              _row(
                'Transaction ID',
                data['transactionId'] ??
                    data['txnId'],
              ),
              _row(
                'Reference ID',
                data['referenceId'],
              ),
            ],
          )
        else
          _section(
            'Resource Details',
            [
              _row(
                'Item Name',
                data['itemName'],
              ),
              _row(
                'Category',
                data['category'],
              ),
              _row(
                'Quantity',
                data['quantity'],
              ),
              _row(
                'Condition',
                data['condition'],
              ),
              _row(
                'Description',
                data['description'],
              ),
            ],
          ),

        const SizedBox(height: 14),

        _section(
          'Campaign Information',
          [
            _row(
              'Campaign',
              data['campaignName'],
            ),
            if (data['campaignId'] != null)
              _row(
                'Campaign ID',
                data['campaignId'],
              ),
          ],
        ),

        if (!isFund) ...[
          const SizedBox(height: 14),
          _section(
            'Donation / Logistics Information',
            [
              _row(
                'Logistics Type',
                data['logisticsType'] ??
                    data['donationType'],
              ),
              _row(
                'Address',
                data['address'],
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        _section(
          'Status Timeline',
          [
            _row(
              'Approved At',
              data['approvedAt'] ??
                  data['verifiedAt'],
            ),
            _row(
              'Received At',
              data['receivedAt'],
            ),
            _row(
              'Completed At',
              data['completedAt'],
            ),
            _row(
              'Rejected At',
              data['rejectedAt'],
            ),
          ],
        ),

        if (_imageUrls(data).isNotEmpty) ...[
          const SizedBox(height: 14),
          _imagesSection(
            _imageUrls(data),
          ),
        ],

        if (extraEntries.isNotEmpty) ...[
          const SizedBox(height: 14),
          _section(
            'Additional Firestore Details',
            extraEntries
                .map(
                  (entry) => _row(
                _prettyKey(entry.key),
                entry.value,
              ),
            )
                .toList(),
          ),
        ],
      ],
    );
  }

  List<String> _imageUrls(
      Map<String, dynamic> data,
      ) {
    final result = <String>[];

    void add(dynamic value) {
      if (value == null) return;

      final url = value.toString().trim();

      if (url.isNotEmpty &&
          !result.contains(url)) {
        result.add(url);
      }
    }

    add(data['paymentProofUrl']);
    add(data['receiptImageUrl']);
    add(data['itemImageUrl']);

    final images = data['imageUrls'];

    if (images is List) {
      for (final image in images) {
        add(image);
      }
    }

    return result;
  }

  Widget _imagesSection(
      List<String> urls,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Images / Proof',
            style: TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...urls.map(
                (url) => Padding(
              padding:
              const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(
                        height: 110,
                        alignment: Alignment.center,
                        color: Colors.grey[100],
                        child: const Text(
                          'Image could not be loaded',
                        ),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
      String title,
      List<Widget> children,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
      String label,
      dynamic value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
      String status,
      ) {
    final lower = status.toLowerCase();

    Color color;
    Color bg;

    if (lower == 'completed') {
      color = _green;
      bg = const Color(0xFFE8F5E9);
    } else if (lower == 'approved') {
      color = Colors.blue[700]!;
      bg = Colors.blue[50]!;
    } else if (lower == 'rejected') {
      color = Colors.red[700]!;
      bg = Colors.red[50]!;
    } else if (lower == 'pending') {
      color = Colors.orange[700]!;
      bg = Colors.orange[50]!;
    } else {
      color = Colors.blueGrey[700]!;
      bg = Colors.blueGrey[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _prettyKey(
      String key,
      ) {
    final result = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
          (match) =>
      '${match.group(1)} ${match.group(2)}',
    );

    final words = result
        .replaceAll('_', ' ')
        .split(' ');

    return words
        .map(
          (word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');
  }
}