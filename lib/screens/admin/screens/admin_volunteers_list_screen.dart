import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminVolunteersListScreen extends StatelessWidget {
  const AdminVolunteersListScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  bool _isApproved(Map<String, dynamic> data) {
    final status = (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final verificationStage =
    (data['verificationStage'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return verificationStage == 'verified' ||
        status == 'approved' ||
        status == 'verified' ||
        status == 'active';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Volunteers',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'volunteer')
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

          final approvedDocs =
          (snapshot.data?.docs ?? []).where((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            return _isApproved(data);
          }).toList();

          if (approvedDocs.isEmpty) {
            return Center(
              child: Text(
                'No approved volunteers yet',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedDocs.length,
            itemBuilder: (context, index) {
              final doc = approvedDocs[index];
              final data =
              doc.data() as Map<String, dynamic>;

              final name =
                  data['name']?.toString() ??
                      'Volunteer';

              final email =
                  data['email']?.toString() ?? '';

              final photo =
                  data['profilePicUrl']?.toString() ??
                      data['photoURL']?.toString() ??
                      '';

              final bool isOnline =
                  data['isOnline'] == true;

              return GestureDetector(
                onTap: () => Get.to(
                      () => _VolunteerCompleteDetailsScreen(
                    data: data,
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
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                            const Color(0xFFE8F5E9),
                            backgroundImage:
                            photo.isNotEmpty
                                ? NetworkImage(photo)
                                : null,
                            child: photo.isEmpty
                                ? Text(
                              name.isNotEmpty
                                  ? name[0]
                                  .toUpperCase()
                                  : 'V',
                              style:
                              const TextStyle(
                                color: _green,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? Colors.green
                                    : Colors.grey[400],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                const Color(0xFFE8F5E9),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: _green,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _VolunteerCompleteDetailsScreen
    extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VolunteerCompleteDetailsScreen({
    required this.data,
  });

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  String _text(dynamic value) {
    if (value == null) return 'Not provided';

    if (value is List) {
      if (value.isEmpty) return 'Not provided';
      return value.join(', ');
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return 'Not provided';
    }

    return text;
  }

  String _date(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();

      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    }

    return _text(value);
  }

  @override
  Widget build(BuildContext context) {
    final photo =
        data['profilePicUrl']?.toString() ??
            data['photoURL']?.toString() ??
            '';

    final cnicFront =
        data['cnicFrontUrl']?.toString() ?? '';

    final cnicBack =
        data['cnicBackUrl']?.toString() ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Volunteer Details',
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
                  radius: 42,
                  backgroundColor:
                  const Color(0xFFE8F5E9),
                  backgroundImage: photo.isNotEmpty
                      ? NetworkImage(photo)
                      : null,
                  child: photo.isEmpty
                      ? const Icon(
                    Icons.person_rounded,
                    color: _green,
                    size: 36,
                  )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  _text(data['name']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Approved Volunteer',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _section(
            'Personal Information',
            [
              _row('Full Name', data['name']),
              _row(
                'Father’s Name',
                data['fatherName'],
              ),
              _row('Date of Birth', data['dob']),
              _row(
                'Blood Group',
                data['bloodGroup'],
              ),
              _row('Email', data['email']),
              _row('Phone', data['phone']),
              _row(
                'CNIC Number',
                data['cnic'],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            'Address & Location',
            [
              _row(
                'Permanent City',
                data['permanentCity'],
              ),
              _row(
                'State / Province',
                data['permanentState'],
              ),
              _row(
                'Preferred Work City',
                data['workCity'],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            'Education / Organization',
            [
              _row(
                'Degree / Designation',
                data['degree'],
              ),
              _row(
                'University / Organization',
                data['university'],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            'Volunteer Roles',
            [
              _row(
                'Selected Categories',
                data['categories'],
              ),
              _row(
                'Past Working Experience',
                data['pastExperience'],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (cnicFront.isNotEmpty ||
              cnicBack.isNotEmpty)
            _section(
              'CNIC Documents',
              [
                if (cnicFront.isNotEmpty)
                  _image(
                    'CNIC Front',
                    cnicFront,
                  ),
                if (cnicBack.isNotEmpty)
                  _image(
                    'CNIC Back',
                    cnicBack,
                  ),
              ],
            ),
          if (cnicFront.isNotEmpty ||
              cnicBack.isNotEmpty)
            const SizedBox(height: 14),
          _section(
            'Verification Information',
            [
              _row(
                'Verification Stage',
                data['verificationStage'],
              ),
              _row('Status', data['status']),
              _row(
                'Registered On',
                _date(data['createdAt']),
              ),
            ],
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
              fontSize: 14,
              color: _green,
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(
      String title,
      String url,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    color: Colors.grey[100],
                    child: const Text(
                      'Image could not be loaded',
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}