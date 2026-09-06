import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDonorsListScreen extends StatelessWidget {
  const AdminDonorsListScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Donors',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'donor')
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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No donors yet',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userDoc = docs[index];
              final data =
              userDoc.data() as Map<String, dynamic>;

              final name =
                  data['name']?.toString() ?? 'Donor';
              final email =
                  data['email']?.toString() ?? '';
              final uid = userDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('donors')
                    .doc(uid)
                    .get(),
                builder: (context, donorSnap) {
                  final donorData = donorSnap.data?.data()
                  as Map<String, dynamic>?;

                  final points =
                      donorData?['rewardPoints'] ?? 0;
                  final totalDonations =
                      donorData?['totalDonations'] ?? 0;

                  return GestureDetector(
                    onTap: () => Get.to(
                          () => _AdminDonorDetailsScreen(
                        donorData: data,
                        rewardPoints: points,
                        totalDonations: totalDonations,
                      ),
                      transition: Transition.rightToLeft,
                    ),
                    child: Container(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                            const Color(0xFFE8F5E9),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                color: _green,
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                    Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  '$totalDonations donations',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                    Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$points',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight.bold,
                                  color: _green,
                                ),
                              ),
                              Text(
                                'points',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminDonorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> donorData;
  final dynamic rewardPoints;
  final dynamic totalDonations;

  const _AdminDonorDetailsScreen({
    required this.donorData,
    required this.rewardPoints,
    required this.totalDonations,
  });

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  String _text(dynamic value) {
    if (value == null) return 'Not provided';

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return 'Not provided';
    }

    return text;
  }

  String _date(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return _text(value);
  }

  @override
  Widget build(BuildContext context) {
    final name = _text(donorData['name']);
    final country = _text(donorData['country']);

    final bool pakistan =
        country.toLowerCase() == 'pakistan';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donor Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor:
                  const Color(0xFFE8F5E9),
                  child: Text(
                    name != 'Not provided' &&
                        name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(donorData['email']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _section(
            title: 'Signup Information',
            children: [
              _row(
                'Full Name',
                donorData['name'],
              ),
              _row(
                'Username',
                donorData['username'],
              ),
              _row(
                'Email',
                donorData['email'],
              ),
              _row(
                'Country',
                donorData['country'],
              ),
              _row(
                'Mobile Number',
                donorData['mobileNumber'],
              ),
              if (pakistan)
                _row(
                  'CNIC',
                  donorData['cnic'],
                )
              else
                _row(
                  'Passport Number',
                  donorData['passportNumber'],
                ),
              _row(
                'Registered On',
                _date(donorData['createdAt']),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            title: 'Donation Summary',
            children: [
              _row(
                'Total Donations',
                totalDonations,
              ),
              _row(
                'Reward Points',
                rewardPoints,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}