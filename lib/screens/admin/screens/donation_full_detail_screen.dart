import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_donations_controller.dart';
import '../../../widgets/admin_donation_kit.dart';

class DonationFullDetailScreen extends StatefulWidget {
  final String donationId;
  final Map<String, dynamic> data;
  const DonationFullDetailScreen({super.key, required this.donationId, required this.data});

  @override
  State<DonationFullDetailScreen> createState() => _DonationFullDetailScreenState();
}

class _DonationFullDetailScreenState extends State<DonationFullDetailScreen> {
  late final AdminDonationsController _controller;

  late final Future<Map<String, dynamic>?> _donorFuture;
  Future<Map<String, dynamic>?>? _taskFuture;
  String _taskStatusKey = '';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminDonationsController>();
    _donorFuture =
        _controller.fetchDonorProfile(widget.data['donorId'] as String?);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId)
          .snapshots(),
      builder: (context, snapshot) {

        Map<String, dynamic> data = Map<String, dynamic>.from(widget.data);
        if (snapshot.hasData && snapshot.data!.exists) {
          final fresh = snapshot.data!.data() as Map<String, dynamic>?;
          if (fresh != null) data = fresh;
        }

        final String logistics =
        (data['logisticsType'] ?? data['donationType'] ?? 'desk').toString();
        final String status = (data['status'] ?? 'pending').toString();

        if (logistics == 'pickup' &&
            (_taskFuture == null || _taskStatusKey != status)) {
          _taskStatusKey = status;
          _taskFuture = _controller.fetchLinkedTask(widget.donationId);
        }

        final List<_Option> options = _nextOptions(status, logistics);

        return Scaffold(
          backgroundColor: DonationKit.bg,
          appBar: AppBar(
            backgroundColor: DonationKit.green,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Donation Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back_ios_rounded),
            ),
            actions: [
              IconButton(
                tooltip: 'Remove donation',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: _body(context, data, logistics, status),
          bottomNavigationBar: options.isEmpty
              ? null
              : _ActionBar(
            options: options,
            onChange: (value) =>
                _controller.updateStatus(widget.donationId, value),
            onReject: () => _showRejectDialog(context),
          ),
        );
      },
    );
  }

  Widget _body(
      BuildContext context,
      Map<String, dynamic> data,
      String logistics,
      String status,
      ) {
    return LayoutBuilder(
      builder: (context, c) {
        final bool wide = c.maxWidth >= 860;
        final double side = c.maxWidth > 1040 ? (c.maxWidth - 1040) / 2 : 0;
        final double hp = (wide ? 24.0 : 16.0) + side;

        final bool rejected = status == 'rejected';

        final Widget details = _detailsCard(data);
        final Widget donor = _donorCard(data);
        final Widget delivery = _deliveryCard(data, logistics);
        final Widget? photos = _photosCard(data);
        final Widget? activity = _activityCard(context, data);

        final Widget cards;
        if (wide) {
          cards = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _stack([details, delivery])),
              const SizedBox(width: 16),
              Expanded(child: _stack([donor, if (photos != null) photos])),
            ],
          );
        } else {
          cards = _stack([
            details,
            donor,
            delivery,
            if (photos != null) photos,
          ]);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hp, wide ? 24 : 16, hp, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(
                donationId: widget.donationId,
                data: data,
                logistics: logistics,
                wide: wide,
              ),
              const SizedBox(height: 16),
              if (rejected)
                _RejectedBanner(data: data)
              else
                _ProgressCard(data: data, status: status, logistics: logistics),
              const SizedBox(height: 16),
              cards,
              if (activity != null) ...[
                const SizedBox(height: 16),
                activity,
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

  // what was donated
  Widget _detailsCard(Map<String, dynamic> data) {
    final bool isFund = DonationKit.isFund(data);
    final List<Widget> rows = [];

    _addKV(rows, 'Category', data['category']);
    _addKV(rows, 'Item', data['itemName']);
    _addKV(rows, 'Quantity', data['quantity']);
    _addKV(rows, 'Condition', data['condition']);
    _addKV(rows, 'Campaign', data['campaignName']);
    if (data['amount'] != null) {
      rows.add(_KV(
        label: 'Amount',
        value: DonationKit.money(DonationKit.amountOf(data)),
        emphasize: true,
      ));
    }
    final String description = DonationKit.valueText(data['description']);
    if (description.isNotEmpty) {
      rows.add(_Block(label: 'Description', text: description));
    }
    final String notes = DonationKit.valueText(data['notes']);
    if (notes.isNotEmpty) {
      rows.add(const SizedBox(height: 10));
      rows.add(_Block(label: 'Admin notes', text: notes));
    }
    if (rows.isEmpty) {
      rows.add(Text(
        'No item details were provided.',
        style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
      ));
    }

    return _InfoCard(
      icon: isFund ? Icons.payments_rounded : Icons.inventory_2_rounded,
      color: isFund ? DonationKit.green : DonationKit.teal,
      title: isFund ? 'Donation' : 'Item details',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  // who donated
  Widget _donorCard(Map<String, dynamic> data) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _donorFuture,
      builder: (context, snap) {
        final Map<String, dynamic>? profile = snap.data;

        final String name =
        DonationKit.valueText(profile?['name'] ?? data['donorName']);
        final String email = DonationKit.valueText(
            profile?['email'] ?? data['userEmail'] ?? data['donorEmail']);
        final String phone = DonationKit.valueText(profile?['mobileNumber'] ??
            profile?['phone'] ?? // FIXED earlier — donors save 'mobileNumber'
            data['donorPhone']);
        final String contact = DonationKit.valueText(data['donorContact']);
        final String cnic = DonationKit.valueText(data['donorCnic']);

        final String initialSource = name.isNotEmpty ? name : email;
        final String initial =
        initialSource.isEmpty ? '' : initialSource[0].toUpperCase();

        final List<Widget> rows = [];
        if (phone.isNotEmpty) rows.add(_KV(label: 'Phone', value: phone, copy: true));
        if (contact.isNotEmpty && contact != phone) {
          rows.add(_KV(label: 'Contact', value: contact, copy: true));
        }
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
      },
    );
  }

  // how it reaches us
  Widget _deliveryCard(Map<String, dynamic> data, String logistics) {
    String label;
    IconData icon;
    switch (logistics) {
      case 'online':
        label = 'Courier (online)';
        icon = Icons.local_shipping_rounded;
        break;
      case 'pickup':
        label = 'Volunteer pickup';
        icon = Icons.directions_walk_rounded;
        break;
      default:
        label = 'Drop-off at desk';
        icon = Icons.store_mall_directory_rounded;
    }

    final String address =
    DonationKit.valueText(data['address'] ?? data['pickupAddress']);

    Widget body;
    if (logistics == 'online') {
      final List<Widget> rows = [];
      _addKV(rows, 'Courier', data['courierName']);
      _addKV(rows, 'Tracking ID', data['trackingId'], copy: true);
      body = rows.isEmpty
          ? Text(
        'No courier details were provided.',
        style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
      )
          : Column(children: rows);
    } else if (logistics == 'pickup') {
      body = FutureBuilder<Map<String, dynamic>?>(
        future: _taskFuture,
        builder: (context, snap) {
          final task = snap.data;
          if (task == null) {
            return Text(
              'No volunteer assigned yet.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
            );
          }
          final List<Widget> rows = [];
          _addKV(rows, 'Volunteer', task['volunteerName']);
          final String taskStatus = DonationKit.valueText(task['status']);
          if (taskStatus.isNotEmpty) {
            rows.add(_KV(label: 'Task status', value: DonationKit.pretty(taskStatus)));
          }
          return Column(children: rows);
        },
      );
    } else {
      body = Text(
        'Donor will personally bring this donation to Little Smiles Orphan Home.',
        style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
      );
    }

    return _InfoCard(
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFFE65100),
      title: 'Delivery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 14),
          body,
          if (address.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Block(label: 'Address', text: address),
          ],
        ],
      ),
    );
  }

  Widget? _photosCard(Map<String, dynamic> data) {
    final List<_Proof> proofs = _proofsOf(data);
    if (proofs.isEmpty) return null;
    return _InfoCard(
      icon: Icons.image_rounded,
      color: const Color(0xFF1565C0),
      title: 'Photos & receipts',
      child: _ProofGrid(proofs: proofs),
    );
  }

  Widget? _activityCard(BuildContext context, Map<String, dynamic> data) {
    final entries = <MapEntry<String, dynamic>>[
      MapEntry('Submitted', data['createdAt']),
      MapEntry('Approved', data['approvedAt']),
      MapEntry('Picked up', data['pickedUpAt']),
      MapEntry('Received', data['receivedAt']),
      MapEntry('Completed', data['completedAt']),
      MapEntry('Rejected', data['rejectedAt']),
    ].where((e) => e.value != null).toList();
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
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule_rounded, size: 19, color: Color(0xFF455A64)),
          ),
          title: const Text(
            'Activity log',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DonationKit.ink,
            ),
          ),
          children: [
            for (final e in entries)
              _KV(label: e.key, value: _fmtFull(e.value)),
          ],
        ),
      ),
    );
  }

  String _fmtFull(dynamic ts) {
    if (ts is! Timestamp) return '';
    final DateTime d = ts.toDate();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final int hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year} • $hour12:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  // actions
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Donation'),
        content: const Text('This will remove the donation from the list. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.softDelete(widget.donationId);
              Get.back();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Donation'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.updateStatus(widget.donationId, 'rejected',
                  reason: reasonCtrl.text.trim());
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
class _Option {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _Option(this.label, this.value, this.color, this.icon);
}

List<_Option> _nextOptions(String status, String logistics) {
  const Color green = Color(0xFF1B6B3A);

  if (status == 'pending') {
    return const [
      _Option('Approve', 'approved', green, Icons.check_circle_rounded),
      _Option('Reject', 'rejected', Color(0xFFC0392B), Icons.cancel_rounded),
    ];
  }
  if (status == 'approved') {
    if (logistics == 'online') {
      return const [
        _Option('Mark In Transit', 'in_transit', Color(0xFF2563EB), Icons.local_shipping_rounded),
      ];
    }
    if (logistics == 'pickup') {
      return const [
        _Option('Mark Pending Pickup', 'pending_pickup', Color(0xFF6A1B9A), Icons.directions_walk_rounded),
      ];
    }
    return const [
      _Option('Mark Awaiting Physical Submission', 'awaiting_physical', Color(0xFFDB7C26), Icons.hourglass_top_rounded),
    ];
  }
  if (status == 'in_transit' || status == 'awaiting_physical' || status == 'picked_up') {
    return const [
      _Option('Mark Received', 'received', green, Icons.inventory_rounded),
    ];
  }
  if (status == 'pending_pickup') {
    return const [
      _Option('Mark Picked Up', 'picked_up', Color(0xFF6A1B9A), Icons.shopping_bag_rounded),
    ];
  }
  if (status == 'received') {
    return const [
      _Option('Mark Completed', 'completed', green, Icons.verified_rounded),
    ];
  }
  return const [];
}
class _ActionBar extends StatelessWidget {
  final List<_Option> options;
  final void Function(String value) onChange;
  final VoidCallback onReject;

  const _ActionBar({
    required this.options,
    required this.onChange,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final List<_Option> rejects = options.where((o) => o.value == 'rejected').toList();
    final List<_Option> mains = options.where((o) => o.value != 'rejected').toList();

    final List<Widget> buttons = [
      for (final o in rejects)
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: Icon(o.icon, size: 19),
              label: Text(
                o.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: o.color,
                side: BorderSide(color: o.color, width: 1.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      for (final o in mains)
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => onChange(o.value),
              icon: Icon(o.icon, size: 20),
              label: Text(
                o.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: o.color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  for (int i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    buttons[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _Hero extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> data;
  final String logistics;
  final bool wide;

  const _Hero({
    required this.donationId,
    required this.data,
    required this.logistics,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFund = DonationKit.isFund(data);
    final DonationStatusStyle st = DonationKit.statusStyle(data['status']);

    final String item = DonationKit.valueText(data['itemName']);
    final String category = DonationKit.valueText(data['category']);
    final String qty = DonationKit.valueText(data['quantity']);

    final String primary = isFund
        ? DonationKit.money(DonationKit.amountOf(data))
        : (item.isNotEmpty ? item : (category.isNotEmpty ? category : 'Donation'));

    final String secondary = [
      if (!isFund && category.isNotEmpty && category != primary) category,
      if (!isFund && qty.isNotEmpty) 'Qty $qty',
      if (isFund && DonationKit.targetName(data).isNotEmpty) DonationKit.targetName(data),
    ].join('  ·  ');

    final List<Color> colors = isFund
        ? const [Color(0xFF1B6B3A), Color(0xFF2D8A52)]
        : const [Color(0xFF00695C), Color(0xFF00838F)];

    String deliveryLabel;
    switch (logistics) {
      case 'online':
        deliveryLabel = 'Courier';
        break;
      case 'pickup':
        deliveryLabel = 'Volunteer pickup';
        break;
      default:
        deliveryLabel = 'Desk drop-off';
    }

    final String donor = DonationKit.valueText(data['donorName']).isNotEmpty
        ? DonationKit.valueText(data['donorName'])
        : DonationKit.valueText(data['userEmail'] ?? data['donorEmail']);
    final String submitted = DonationKit.fmtDate(data['createdAt']);
    final String ref = donationId.length > 8
        ? donationId.substring(0, 8).toUpperCase()
        : donationId.toUpperCase();
    final bool byAdmin = data['source'] == 'admin_manual';

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
                  Flexible(
                    child: Container(
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
                          Flexible(
                            child: Text(
                              isFund ? 'FUND DONATION' : 'RESOURCE DONATION',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                  fontSize: wide ? 38 : 28,
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
                  if (!isFund) _HeroMeta(label: 'DELIVERY', value: deliveryLabel),
                  if (submitted.isNotEmpty) _HeroMeta(label: 'SUBMITTED', value: submitted),
                  if (byAdmin) const _HeroMeta(label: 'SOURCE', value: 'Added by Admin'),
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

// REJECTED BANNER
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
                  'Donation rejected',
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

List<String> _stepsFor(String logistics) {
  if (logistics == 'online') {
    return ['submitted', 'approved', 'in_transit', 'received', 'completed'];
  }
  if (logistics == 'pickup') {
    return ['submitted', 'approved', 'pending_pickup', 'picked_up', 'received', 'completed'];
  }
  return ['submitted', 'approved', 'awaiting_physical', 'received', 'completed'];
}

int _activeIndexFor(String status, List<String> steps) {
  if (status == 'pending') return 0;
  if (status == 'rejected') return -1;
  String effective = status;
  if (status == 'pickup_assigned' || status == 'volunteer_assigned') {
    effective = 'pending_pickup';
  }
  if (status == 'complete') effective = 'completed';
  final int idx = steps.indexOf(effective);
  return idx == -1 ? 0 : idx;
}

dynamic _dateForStep(String step, Map<String, dynamic> data) {
  switch (step) {
    case 'submitted':
      return data['createdAt'];
    case 'approved':
      return data['approvedAt'];
    case 'picked_up':
      return data['pickedUpAt'];
    case 'received':
      return data['receivedAt'];
    case 'completed':
      return data['completedAt'];
    default:
      return null;
  }
}

class _ProgressCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String status;
  final String logistics;
  const _ProgressCard({
    required this.data,
    required this.status,
    required this.logistics,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> steps = _stepsFor(logistics);
    final int current = _activeIndexFor(status, steps);

    const Color grey = Color(0xFFD5DBD9);

    return _InfoCard(
      icon: Icons.timeline_rounded,
      color: DonationKit.green,
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
                              : (i <= current ? DonationKit.green : grey),
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: i <= current ? DonationKit.green : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i <= current ? DonationKit.green : grey,
                            width: 2,
                          ),
                          boxShadow: i == current
                              ? [
                            BoxShadow(
                              color: DonationKit.green.withOpacity(0.25),
                              spreadRadius: 4,
                              blurRadius: 0,
                            ),
                          ]
                              : null,
                        ),
                        child: i <= current
                            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                            : null,
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i == steps.length - 1
                              ? Colors.transparent
                              : (i < current ? DonationKit.green : grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      DonationKit.pretty(steps[i]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: i <= current ? FontWeight.w800 : FontWeight.w500,
                        color: i <= current ? DonationKit.ink : Colors.grey[500],
                      ),
                    ),
                  ),
                  if (DonationKit.shortDate(_dateForStep(steps[i], data)).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      DonationKit.shortDate(_dateForStep(steps[i], data)),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

// PHOTOS & RECEIPTS
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

  add('Item photo', data['itemImageUrl']);
  final images = data['imageUrls'];
  if (images is List) {
    int n = 0;
    for (final image in images) {
      n++;
      add(images.length > 1 ? 'Item photo $n' : 'Item photo', image);
    }
  }
  add('Payment proof', data['paymentProofUrl']);
  add('Courier receipt', data['receiptUrl'] ?? data['receiptImageUrl']);
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