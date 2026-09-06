import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'donation_feedback_sheet.dart';

class DonorDonationsTab extends StatefulWidget {
  const DonorDonationsTab({super.key});

  @override
  State<DonorDonationsTab> createState() => _DonorDonationsTabState();
}

class _DonorDonationsTabState extends State<DonorDonationsTab> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Set<String> _promptedThisSession = {};
  bool _isPromptShowing = false;

  String _selectedFilter = 'All';
  String _selectedType = 'All';

  // ============================================================
  // FEEDBACK PROMPT
  // ============================================================

  void _maybeShowFeedbackPrompt(
      List<QueryDocumentSnapshot> docs,
      ) {
    if (_isPromptShowing) return;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final bool isFund = _isFundDonation(data);
      final String status =
      (data['status'] ?? 'pending').toString();

      final bool alreadyPrompted =
          data['feedbackPrompted'] == true;

      // Fund: approved = completed
      // Resource: completed = completed
      final bool qualifies = isFund
          ? status == 'approved'
          : status == 'completed';

      if (qualifies &&
          !alreadyPrompted &&
          !_promptedThisSession.contains(doc.id)) {
        _promptedThisSession.add(doc.id);
        _isPromptShowing = true;

        _db.collection('donations').doc(doc.id).update({
          'feedbackPrompted': true,
        }).catchError((_) {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            builder: (_) => DonationFeedbackSheet(
              donationId: doc.id,
              isFund: isFund,
            ),
          ).whenComplete(() {
            _isPromptShowing = false;
          });
        });

        break;
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isFundDonation(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase();

    if (type == 'fund') return true;

    return data.containsKey('amount') &&
        !data.containsKey('itemName');
  }

  bool _matchesFilter(
      Map<String, dynamic> data,
      ) {
    final status =
    (data['status'] ?? 'pending').toString();

    final bool isFund = _isFundDonation(data);

    // ----------------------------
    // TYPE FILTER
    // ----------------------------
    if (_selectedType == 'Fund' && !isFund) {
      return false;
    }

    if (_selectedType == 'Resource' && isFund) {
      return false;
    }

    // ----------------------------
    // STATUS FILTER
    // ----------------------------
    switch (_selectedFilter) {
      case 'Pending':
        return status == 'pending';

      case 'Active':
        if (isFund) {
          return false;
        }

        return status == 'approved' ||
            status == 'pickup_assigned' ||
            status == 'delivered';

      case 'Completed':
        if (isFund) {
          return status == 'approved';
        }

        return status == 'completed';

      case 'All':
      default:
        return true;
    }
  }

  DateTime _dateFrom(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final date = _dateFrom(value);

    if (date.millisecondsSinceEpoch == 0) {
      return 'N/A';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '0';

    if (value is num) {
      return value.toStringAsFixed(0);
    }

    final parsed = double.tryParse(
      value.toString().replaceAll(',', ''),
    );

    if (parsed == null) {
      return value.toString();
    }

    return parsed.toStringAsFixed(0);
  }

  String _timeAgo(dynamic value) {
    if (value == null || value is! Timestamp) {
      return '';
    }

    final diff =
    DateTime.now().difference(value.toDate());

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }

    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }

    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }

    return 'Just now';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Please log in again to view your donations.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(uid),
            _buildFilters(),
            Expanded(
              child: _buildDonationsStream(uid),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(String uid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _green,
            _lightGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('donations')
            .where(
          'donorId',
          isEqualTo: uid,
        )
            .snapshots(),
        builder: (context, snapshot) {
          final docs =
              snapshot.data?.docs ?? [];

          final total = docs.length;

          final pending = docs.where((doc) {
            final data =
            doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'pending') ==
                'pending';
          }).length;

          final completed = docs.where((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            final isFund =
            _isFundDonation(data);

            final status =
            (data['status'] ?? 'pending')
                .toString();

            return isFund
                ? status == 'approved'
                : status == 'completed';
          }).length;

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(
                        0.16,
                      ),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Donations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Track your donations and their progress',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _HeaderStat(
                    icon: Icons.layers_outlined,
                    value: '$total',
                    label: 'Total',
                  ),
                  const SizedBox(width: 10),
                  _HeaderStat(
                    icon:
                    Icons.pending_actions_rounded,
                    value: '$pending',
                    label: 'Pending',
                  ),
                  const SizedBox(width: 10),
                  _HeaderStat(
                    icon:
                    Icons.check_circle_outline,
                    value: '$completed',
                    label: 'Completed',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        4,
      ),
      child: Column(
        children: [
          _buildStatusFilter(),
          const SizedBox(height: 10),
          _buildTypeFilter(),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    const filters = [
      'All',
      'Pending',
      'Active',
      'Completed',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: filters.map((filter) {
          final selected =
              _selectedFilter == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 180),
                padding:
                const EdgeInsets.symmetric(
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? _green
                      : Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  filter,
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeFilter() {
    const types = [
      'All',
      'Fund',
      'Resource',
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection:
        Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final selected =
              _selectedType == type;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              alignment:
              Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(
                  0xFFE8F5E9,
                )
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? _green.withOpacity(0.35)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    type == 'Fund'
                        ? Icons.payments_outlined
                        : type == 'Resource'
                        ? Icons
                        .inventory_2_outlined
                        : Icons.layers_outlined,
                    size: 14,
                    color: selected
                        ? _green
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                      selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? _green
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FIRESTORE STREAM
  // ============================================================

  Widget _buildDonationsStream(String uid) {
    return StreamBuilder<QuerySnapshot>(
      // Only where() is used.
      // Sorting is done locally.
      stream: _db
          .collection('donations')
          .where(
        'donorId',
        isEqualTo: uid,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: _green,
            ),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message:
            'Unable to load your donations.\n\n'
                '${snapshot.error}',
          );
        }

        final docs =
        List<QueryDocumentSnapshot>.from(
          snapshot.data?.docs ?? [],
        );

        docs.sort((a, b) {
          final aData =
          a.data()
          as Map<String, dynamic>;
          final bData =
          b.data()
          as Map<String, dynamic>;

          final aDate =
          _dateFrom(aData['createdAt']);
          final bDate =
          _dateFrom(bData['createdAt']);

          return bDate.compareTo(aDate);
        });

        _maybeShowFeedbackPrompt(docs);

        final filteredDocs =
        docs.where((doc) {
          final data =
          doc.data()
          as Map<String, dynamic>;

          return _matchesFilter(data);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _EmptyDonationState(
            filter: _selectedFilter,
            type: _selectedType,
          );
        }

        return RefreshIndicator(
          color: _green,
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(
                milliseconds: 300,
              ),
            );
          },
          child: ListView.builder(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              24,
            ),
            itemCount:
            filteredDocs.length,
            itemBuilder:
                (context, index) {
              final doc =
              filteredDocs[index];

              final data =
              doc.data()
              as Map<String, dynamic>;

              return _DonationCard(
                docId: doc.id,
                data: data,
                isFund:
                _isFundDonation(data),
                formatDate:
                _formatDate,
                timeAgo:
                _timeAgo,
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// HEADER STAT
// ============================================================================

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
          Colors.white.withOpacity(0.14),
          borderRadius:
          BorderRadius.circular(13),
          border: Border.all(
            color:
            Colors.white.withOpacity(0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style:
                  const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DONATION CARD
// ============================================================================

class _DonationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isFund;
  final String Function(dynamic)
  formatDate;
  final String Function(dynamic)
  timeAgo;

  const _DonationCard({
    required this.docId,
    required this.data,
    required this.isFund,
    required this.formatDate,
    required this.timeAgo,
  });

  static const Color _green =
  Color(0xFF1B6B3A);

  String get status =>
      (data['status'] ?? 'pending')
          .toString();

  String get title {
    if (isFund) {
      return 'Fund Donation';
    }

    return data['itemName']?.toString() ??
        'Resource Donation';
  }

  String get campaign {
    return data['campaignName']
        ?.toString() ??
        '';
  }

  String get description {
    return data['description']
        ?.toString() ??
        '';
  }

  String get address {
    return (data['address'] ??
        data['pickupAddress'] ??
        '')
        .toString();
  }

  String get category {
    return data['category']?.toString() ??
        '';
  }

  String get quantity {
    return data['quantity']?.toString() ??
        '';
  }

  String get condition {
    return data['condition']?.toString() ??
        '';
  }

  String get paymentMethod {
    return data['paymentMethod']
        ?.toString() ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(
              () => DonationDetailScreen(
            docId: docId,
            data: data,
          ),
          transition:
          Transition.rightToLeft,
        );
      },
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 13,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                0.055,
              ),
              blurRadius: 12,
              offset:
              const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 5,
              decoration:
              BoxDecoration(
                color:
                _statusColor(status),
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration:
                        BoxDecoration(
                          color: isFund
                              ? const Color(
                            0xFFE8F5E9,
                          )
                              : const Color(
                            0xFFE0F7FA,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          isFund
                              ? Icons
                              .payments_rounded
                              : Icons
                              .inventory_2_rounded,
                          color: isFund
                              ? _green
                              : const Color(
                            0xFF00838F,
                          ),
                          size: 24,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style:
                                    const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                      FontWeight.bold,
                                      color:
                                      Color(0xFF17221C),
                                    ),
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                _StatusBadge(
                                  status:
                                  status,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            if (isFund)
                              Text(
                                'Rs. ${_amount(data['amount'])}',
                                style:
                                const TextStyle(
                                  color: _green,
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              )
                            else if (quantity
                                .isNotEmpty)
                              Text(
                                'Quantity: $quantity',
                                style:
                                TextStyle(
                                  fontSize: 11.5,
                                  color:
                                  Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (campaign.isNotEmpty) ...[
                    const SizedBox(
                      height: 11,
                    ),
                    _InfoPill(
                      icon:
                      Icons.campaign_outlined,
                      text: campaign,
                      color: _green,
                    ),
                  ],

                  if (!isFund &&
                      category.isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),
                    _InfoPill(
                      icon:
                      Icons.category_outlined,
                      text: category,
                      color:
                      Colors.teal[700]!,
                    ),
                  ],

                  if (!isFund &&
                      condition.isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),
                    _InfoPill(
                      icon:
                      Icons.verified_outlined,
                      text:
                      'Condition: $condition',
                      color:
                      Colors.indigo[600]!,
                    ),
                  ],

                  if (description.isNotEmpty) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment:
                      Alignment.centerLeft,
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                          Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                      ),
                    ),
                  ],

                  if (address.isNotEmpty) ...[
                    const SizedBox(
                      height: 9,
                    ),
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons
                              .location_on_outlined,
                          size: 15,
                          color:
                          Colors.grey[500],
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                              Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (isFund &&
                      paymentMethod
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 9,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons
                              .account_balance_wallet_outlined,
                          size: 15,
                          color:
                          Colors.grey[500],
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          paymentMethod,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                            Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(
                    height: 12,
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(0xFFF8FAF9),
                      borderRadius:
                      BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .calendar_today_outlined,
                          size: 13,
                          color:
                          Colors.grey[500],
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          formatDate(
                            data['createdAt'],
                          ),
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                            Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo(
                            data['createdAt'],
                          ),
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                            Colors.grey[500],
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Icon(
                          Icons
                              .arrow_forward_ios_rounded,
                          size: 11,
                          color:
                          Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  if (status == 'rejected' &&
                      data['rejectionReason'] !=
                          null) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(
                        11,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.red[50],
                        borderRadius:
                        BorderRadius.circular(
                          11,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color:
                            Colors.red[700],
                            size: 16,
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          Expanded(
                            child: Text(
                              'Reason: ${data['rejectionReason']}',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                Colors.red[700],
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (status ==
                      'pickup_assigned') ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _MessageBox(
                      icon:
                      Icons
                          .local_shipping_outlined,
                      text:
                      'A volunteer has been assigned for pickup.',
                      color:
                      Colors.orange[800]!,
                      background:
                      Colors.orange[50]!,
                    ),
                  ],

                  if (status == 'delivered') ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _MessageBox(
                      icon:
                      Icons.done_all_rounded,
                      text:
                      'Your donation has been delivered and is awaiting final completion.',
                      color:
                      Colors.teal[800]!,
                      background:
                      Colors.teal[50]!,
                    ),
                  ],

                  if (isFund &&
                      status == 'approved') ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _MessageBox(
                      icon:
                      Icons.celebration_rounded,
                      text:
                      'Your fund donation has been verified successfully. Thank you!',
                      color:
                      _green,
                      background:
                      const Color(
                        0xFFE8F5E9,
                      ),
                    ),
                  ],

                  if (!isFund &&
                      status == 'completed') ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _MessageBox(
                      icon:
                      Icons.favorite_rounded,
                      text:
                      'Thank you! Your resource donation has completed its journey.',
                      color:
                      _green,
                      background:
                      const Color(
                        0xFFE8F5E9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _amount(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(0);
    }

    return double.tryParse(
      value
          ?.toString()
          .replaceAll(',', '')
          .trim() ??
          '',
    )?.toStringAsFixed(0) ??
        value?.toString() ??
        '0';
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'approved':
        return Colors.blue[400]!;

      case 'completed':
        return Colors.green[500]!;

      case 'rejected':
        return Colors.red[400]!;

      case 'pickup_assigned':
        return Colors.orange[400]!;

      case 'delivered':
        return Colors.teal[400]!;

      default:
        return Colors.grey[300]!;
    }
  }
}

// ============================================================================
// INFO PILL
// ============================================================================

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      Alignment.centerLeft,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration:
        BoxDecoration(
          color:
          color.withOpacity(0.08),
          borderRadius:
          BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10.5,
                  color: color,
                  fontWeight:
                  FontWeight.w600,
                ),
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE BOX
// ============================================================================

class _MessageBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  const _MessageBox({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(11),
      decoration:
      BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                height: 1.35,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.blue[700]!;
        bg = Colors.blue[50]!;
        label = 'Approved';
        icon = Icons.thumb_up_outlined;
        break;

      case 'completed':
        color = Colors.green[700]!;
        bg = Colors.green[50]!;
        label = 'Completed';
        icon =
            Icons.check_circle_outline;
        break;

      case 'rejected':
        color = Colors.red[700]!;
        bg = Colors.red[50]!;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;

      case 'pickup_assigned':
        color = Colors.orange[700]!;
        bg = Colors.orange[50]!;
        label = 'Pickup Soon';
        icon =
            Icons.local_shipping_outlined;
        break;

      case 'delivered':
        color = Colors.teal[700]!;
        bg = Colors.teal[50]!;
        label = 'Delivered';
        icon = Icons.done_all_rounded;
        break;

      default:
        color = Colors.grey[700]!;
        bg = Colors.grey[100]!;
        label = 'Pending';
        icon = Icons.pending_outlined;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color: bg,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              color: color,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyDonationState
    extends StatelessWidget {
  final String filter;
  final String type;

  const _EmptyDonationState({
    required this.filter,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;

    if (filter == 'Pending') {
      title =
      'No pending donations';
      subtitle =
      'Donations waiting for manager approval will appear here.';
    } else if (filter == 'Active') {
      title =
      'No active donations';
      subtitle =
      'Approved resource donations with pickup activity will appear here.';
    } else if (filter == 'Completed') {
      title =
      'No completed donations';
      subtitle =
      'Your completed donation history will appear here.';
    } else if (type == 'Fund') {
      title =
      'No fund donations';
      subtitle =
      'Your fund donations will appear here.';
    } else if (type == 'Resource') {
      title =
      'No resource donations';
      subtitle =
      'Your resource donations will appear here.';
    } else {
      title =
      'No donations yet';
      subtitle =
      'Start donating to make a difference!';
    }

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
              const BoxDecoration(
                color:
                Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .volunteer_activism_outlined,
                size: 40,
                color:
                Color(0xFF1B6B3A),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              title,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              subtitle,
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                Colors.grey[500],
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================

class _ErrorState
    extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.grey[300],
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'Could not load donations',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DONATION DETAIL SCREEN
// ============================================================================

class DonationDetailScreen
    extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DonationDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  static const Color _green =
  Color(0xFF1B6B3A);

  static const Color _bg =
  Color(0xFFF4F6F8);

  bool _isFund() {
    final type =
    data['type']
        ?.toString()
        .toLowerCase();

    if (type == 'fund') return true;

    return data.containsKey('amount') &&
        !data.containsKey('itemName');
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'N/A';
    }

    final date =
    value.toDate();

    final day =
    date.day
        .toString()
        .padLeft(2, '0');

    final month =
    date.month
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _amount(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(0);
    }

    return value?.toString() ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    final bool isFund =
    _isFund();

    final String status =
        data['status']
            ?.toString() ??
            'pending';

    final String campaign =
        data['campaignName']
            ?.toString() ??
            '';

    final String paymentMethod =
        data['paymentMethod']
            ?.toString() ??
            '';

    final String paymentProofUrl =
    (data['paymentProofUrl'] ??
        data['receiptImageUrl'] ??
        '')
        .toString();

    final String itemImageUrl =
    (data['itemImageUrl'] ??
        ((data['imageUrls'] is List &&
            (data['imageUrls']
            as List)
                .isNotEmpty)
            ? (data['imageUrls']
        as List)
            .first
            : ''))
        .toString();

    final String address =
    (data['address'] ??
        data['pickupAddress'] ??
        '')
        .toString();

    return Scaffold(
      backgroundColor:
      _bg,
      appBar: AppBar(
        backgroundColor:
        _green,
        foregroundColor:
        Colors.white,
        elevation: 0,
        title: const Text(
          'Donation Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        leading:
        IconButton(
          onPressed: () =>
              Get.back(),
          icon:
          const Icon(
            Icons
                .arrow_back_ios_rounded,
            size: 20,
          ),
        ),
      ),
      body:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [
            // -----------------------------------------------------
            // STATUS HEADER
            // -----------------------------------------------------
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                20,
              ),
              decoration:
              BoxDecoration(
                gradient:
                const LinearGradient(
                  colors: [
                    _green,
                    Color(
                      0xFF2D8A52,
                    ),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .white
                          .withOpacity(
                        0.18,
                      ),
                      shape: BoxShape
                          .circle,
                    ),
                    child:
                    Icon(
                      isFund
                          ? Icons
                          .payments_rounded
                          : Icons
                          .inventory_2_rounded,
                      color:
                      Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    isFund
                        ? 'Fund Donation'
                        : 'Resource Donation',
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize: 18,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),
                  if (isFund) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Rs. ${_amount(data['amount'])}',
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 27,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 10,
                  ),
                  _WhiteStatusBadge(
                    status: status,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // -----------------------------------------------------
            // PROGRESS
            // -----------------------------------------------------
            _DetailCard(
              title:
              'Donation Progress',
              icon:
              Icons.timeline_rounded,
              child:
              Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  vertical:
                  8,
                ),
                child:
                _DetailTimeline(
                  status:
                  status,
                  isFund:
                  isFund,
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // -----------------------------------------------------
            // INFORMATION
            // -----------------------------------------------------
            _DetailCard(
              title:
              'Donation Information',
              icon:
              Icons.info_outline_rounded,
              child:
              Column(
                children: [
                  if (campaign
                      .isNotEmpty)
                    _InfoRow(
                      label:
                      'Campaign',
                      value:
                      campaign,
                    ),

                  if (isFund &&
                      paymentMethod
                          .isNotEmpty)
                    _InfoRow(
                      label:
                      'Payment Method',
                      value:
                      paymentMethod,
                    ),

                  if (isFund)
                    _InfoRow(
                      label:
                      'Amount',
                      value:
                      'Rs. ${_amount(data['amount'])}',
                    ),

                  if (!isFund) ...[
                    _InfoRow(
                      label: 'Item',
                      value:
                      data['itemName']
                          ?.toString() ??
                          '',
                    ),
                    _InfoRow(
                      label:
                      'Category',
                      value:
                      data['category']
                          ?.toString() ??
                          '',
                    ),
                    _InfoRow(
                      label:
                      'Quantity',
                      value:
                      data['quantity']
                          ?.toString() ??
                          '',
                    ),
                    _InfoRow(
                      label:
                      'Condition',
                      value:
                      data['condition']
                          ?.toString() ??
                          '',
                    ),
                  ],

                  if (address
                      .isNotEmpty)
                    _InfoRow(
                      label:
                      'Pickup Address',
                      value:
                      address,
                    ),

                  _InfoRow(
                    label:
                    'Submitted',
                    value:
                    _formatDate(
                      data['createdAt'],
                    ),
                  ),

                  if (data[
                  'verifiedAt'] !=
                      null)
                    _InfoRow(
                      label:
                      'Verified',
                      value:
                      _formatDate(
                        data[
                        'verifiedAt'],
                      ),
                    ),

                  if (data[
                  'acceptedAt'] !=
                      null)
                    _InfoRow(
                      label:
                      'Accepted',
                      value:
                      _formatDate(
                        data[
                        'acceptedAt'],
                      ),
                    ),

                  if (data[
                  'deliveredAt'] !=
                      null)
                    _InfoRow(
                      label:
                      'Delivered',
                      value:
                      _formatDate(
                        data[
                        'deliveredAt'],
                      ),
                    ),

                  if (data[
                  'completedAt'] !=
                      null)
                    _InfoRow(
                      label:
                      'Completed',
                      value:
                      _formatDate(
                        data[
                        'completedAt'],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // -----------------------------------------------------
            // IMAGE / PROOF
            // -----------------------------------------------------
            if (paymentProofUrl
                .isNotEmpty ||
                itemImageUrl
                    .isNotEmpty)
              _DetailCard(
                title: isFund
                    ? 'Payment Proof'
                    : 'Item Images',
                icon:
                Icons.image_outlined,
                child:
                _DetailImageSection(
                  primaryUrl:
                  isFund
                      ? paymentProofUrl
                      : itemImageUrl,
                  allImages:
                  data['imageUrls']
                  is List
                      ? List<String>
                      .from(
                    (data[
                    'imageUrls']
                    as List)
                        .map(
                          (e) =>
                          e.toString(),
                    ),
                  )
                      : const [],
                ),
              ),

            if (status ==
                'pickup_assigned' ||
                status ==
                    'delivered') ...[
              const SizedBox(
                height: 12,
              ),
              _DetailCard(
                title:
                'Pickup Information',
                icon: Icons
                    .local_shipping_outlined,
                child:
                _MessageBox(
                  icon: Icons
                      .directions_bike_rounded,
                  text:
                  status ==
                      'delivered'
                      ? 'Your donation has been collected and delivered to LSOH!'
                      : 'A volunteer has been assigned to collect your donation.',
                  color:
                  Colors.orange[800]!,
                  background:
                  Colors.orange[50]!,
                ),
              ),
            ],

            if (status ==
                'rejected' &&
                data[
                'rejectionReason'] !=
                    null) ...[
              const SizedBox(
                height: 12,
              ),
              _DetailCard(
                title:
                'Rejection Reason',
                icon:
                Icons.cancel_outlined,
                child:
                _MessageBox(
                  icon:
                  Icons.info_outline,
                  text: data[
                  'rejectionReason']
                      .toString(),
                  color:
                  Colors.red[700]!,
                  background:
                  Colors.red[50]!,
                ),
              ),
            ],

            if ((isFund &&
                status ==
                    'approved') ||
                (!isFund &&
                    status ==
                        'completed')) ...[
              const SizedBox(
                height: 12,
              ),
              _DetailCard(
                title:
                'Thank You',
                icon:
                Icons.favorite_rounded,
                child:
                _MessageBox(
                  icon: Icons
                      .celebration_rounded,
                  text: isFund
                      ? 'Your fund donation has been verified successfully. Thank you for your generosity!'
                      : 'Your resource donation has been completed successfully. Thank you for making a difference!',
                  color:
                  _green,
                  background:
                  const Color(
                    0xFFE8F5E9,
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DETAIL TIMELINE
// ============================================================================

class _DetailTimeline
    extends StatelessWidget {
  final String status;
  final bool isFund;

  const _DetailTimeline({
    required this.status,
    required this.isFund,
  });

  @override
  Widget build(BuildContext context) {
    final steps = isFund
        ? const [
      'Submitted',
      'Verified',
      'Completed',
    ]
        : const [
      'Submitted',
      'Approved',
      'Pickup',
      'Delivered',
      'Completed',
    ];

    final activeStep =
    _activeStep();

    return Row(
      children:
      List.generate(
        steps.length,
            (index) {
          final done =
              index <= activeStep;

          final last =
              index ==
                  steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration:
                        BoxDecoration(
                          color: done
                              ? const Color(
                            0xFF1B6B3A,
                          )
                              : Colors
                              .grey[200],
                          shape:
                          BoxShape
                              .circle,
                        ),
                        child:
                        Icon(
                          done
                              ? Icons
                              .check_rounded
                              : Icons.circle,
                          size: done
                              ? 14
                              : 6,
                          color: done
                              ? Colors.white
                              : Colors
                              .grey[400],
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        steps[index],
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          fontSize:
                          8.5,
                          color: done
                              ? const Color(
                            0xFF1B6B3A,
                          )
                              : Colors
                              .grey[400],
                          fontWeight: done
                              ? FontWeight
                              .w600
                              : FontWeight
                              .normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!last)
                  Expanded(
                    child:
                    Container(
                      height: 2,
                      margin:
                      const EdgeInsets
                          .only(
                        bottom: 18,
                      ),
                      color: index <
                          activeStep
                          ? const Color(
                        0xFF1B6B3A,
                      )
                          : Colors
                          .grey[200],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _activeStep() {
    if (isFund) {
      switch (status) {
        case 'approved':
        case 'completed':
          return 2;
        default:
          return 0;
      }
    }

    switch (status) {
      case 'approved':
        return 1;
      case 'pickup_assigned':
        return 2;
      case 'delivered':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }
}

// ============================================================================
// DETAIL CARD
// ============================================================================

class _DetailCard
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.045,
            ),
            blurRadius: 9,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color:
                const Color(
                  0xFF1B6B3A,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
              TextStyle(
                fontSize: 11.5,
                color:
                Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 12.5,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DETAIL IMAGE SECTION
// ============================================================================

class _DetailImageSection
    extends StatelessWidget {
  final String primaryUrl;
  final List<String> allImages;

  const _DetailImageSection({
    required this.primaryUrl,
    required this.allImages,
  });

  @override
  Widget build(BuildContext context) {
    final images = <String>[];

    if (primaryUrl.isNotEmpty) {
      images.add(primaryUrl);
    }

    for (final image in allImages) {
      if (image.isNotEmpty &&
          !images.contains(image)) {
        images.add(image);
      }
    }

    if (images.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius:
          BorderRadius.circular(12),
          child:
          Image.network(
            images.first,
            width:
            double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) {
              return Container(
                height: 220,
                color:
                Colors.grey[100],
                child:
                Icon(
                  Icons
                      .broken_image_outlined,
                  color:
                  Colors.grey[400],
                  size: 40,
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 75,
            child:
            ListView.separated(
              scrollDirection:
              Axis.horizontal,
              itemCount:
              images.length,
              separatorBuilder:
                  (_, __) =>
              const SizedBox(
                width: 8,
              ),
              itemBuilder:
                  (context, index) {
                return ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    9,
                  ),
                  child:
                  Image.network(
                    images[index],
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) {
                      return Container(
                        width: 75,
                        height: 75,
                        color:
                        Colors.grey[
                        100],
                        child: Icon(
                          Icons
                              .broken_image_outlined,
                          size: 24,
                          color:
                          Colors.grey[
                          400],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// WHITE STATUS BADGE
// ============================================================================

class _WhiteStatusBadge
    extends StatelessWidget {
  final String status;

  const _WhiteStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String label;

    switch (status) {
      case 'approved':
        label = 'VERIFIED';
        break;

      case 'completed':
        label = 'COMPLETED';
        break;

      case 'pickup_assigned':
        label = 'PICKUP ASSIGNED';
        break;

      case 'delivered':
        label = 'DELIVERED';
        break;

      case 'rejected':
        label = 'REJECTED';
        break;

      default:
        label = 'PENDING';
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(
          0.18,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
        const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}