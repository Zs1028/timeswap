import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/service_model.dart';
import '../../routes.dart';
import '../need_help/service_details_page.dart';
import 'service_applications_page.dart';

class YourRequestsPage extends StatelessWidget {
  const YourRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety: if somehow reached here without login → push Login
    if (user == null) {
      // You can also return LoginPage() directly if you want.
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String currentUserId = user.uid;

    final myRequestedQuery = FirebaseFirestore.instance
        .collection('services')
        .where('serviceType', isEqualTo: 'need')
        .where('requesterId', isEqualTo: currentUserId)
        .orderBy('createdDate', descending: true)
        .withConverter<Service>(
          fromFirestore: (snap, _) => Service.fromFirestore(snap),
          toFirestore: (service, _) => {},
        );

    final myOfferedQuery = FirebaseFirestore.instance
        .collection('services')
        .where('serviceType', isEqualTo: 'offer')
        .where('requesterId', isEqualTo: currentUserId)
        .orderBy('createdDate', descending: true)
        .withConverter<Service>(
          fromFirestore: (snap, _) => Service.fromFirestore(snap),
          toFirestore: (service, _) => {},
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF4D1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF4D1),
          elevation: 0,
          title: const Text(
            'Your Request',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _headerTabs(),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Services Offered
                    _MyServicesTab(
                      query: myOfferedQuery,
                      titlePrefix: 'Offer Help: ',
                      addButtonText: 'Add Offering',
                      onAddPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.addOffering),
                    ),

                    // Tab 2: Services Requested
                    _MyServicesTab(
                      query: myRequestedQuery,
                      titlePrefix: 'Need Help: ',
                      addButtonText: 'Add Request',
                      onAddPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.addRequest),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFADF8E),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
        child: const TabBar(
          labelPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicator: _RoundedUnderlineIndicator(),
          tabs: [
            Text('Services Offered'),
            Text('Services Requested'),
          ],
        ),
      ),
    );
  }
}

class _RoundedUnderlineIndicator extends Decoration {
  const _RoundedUnderlineIndicator();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _RoundedUnderlinePainter();
}

class _RoundedUnderlinePainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    if (cfg.size == null) return;
    final rect = Offset(offset.dx, cfg.size!.height - 3) &
        Size(cfg.size!.width, 3);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }
}

class _MyServicesTab extends StatefulWidget {
  final Query<Service> query;
  final String titlePrefix;
  final String addButtonText;
  final VoidCallback onAddPressed;

  const _MyServicesTab({
    required this.query,
    required this.titlePrefix,
    required this.addButtonText,
    required this.onAddPressed,
  });

  @override
  State<_MyServicesTab> createState() => _MyServicesTabState();
}

class _MyServicesTabState extends State<_MyServicesTab> {
  String _statusFilter = 'open'; // 'open' | 'inprogress' | 'completed'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _statusChips(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Service>>(
            stream: widget.query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              var services = docs.map((d) => d.data()).toList();

              services = services
                  .where((s) =>
                      s.serviceStatus.toLowerCase() ==
                      _statusFilter.toLowerCase())
                  .toList();

              if (services.isEmpty) {
                return const Center(child: Text('No services yet.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _ServiceCard(
                  service: services[i],
                  titlePrefix: widget.titlePrefix,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.onAddPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39C50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                widget.addButtonText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChips() {
    Widget buildChip(String label, String value) {
      final bool selected = _statusFilter == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = value);
        },
        selectedColor: const Color(0xFFF39C50),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildChip('Open', 'open'),
          const SizedBox(width: 8),
          buildChip('In Progress', 'inprogress'),
          const SizedBox(width: 8),
          buildChip('Completed', 'completed'),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final String titlePrefix;

  const _ServiceCard({
    required this.service,
    required this.titlePrefix,
  });

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return const Color(0xFFBFE8C9);
      case 'inprogress':
        return const Color(0xFFFBE1B8);
      case 'completed':
        return const Color(0xFFB0BEC5);
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showMarkCompleted =
        service.serviceStatus.toLowerCase() == 'inprogress';
    final bool showViewApplications =
        service.serviceStatus.toLowerCase() == 'open';

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailsPage(
                  service: service,
                  showRequestButton: false,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: titlePrefix,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                          children: [
                            TextSpan(
                              text: service.serviceTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _iconText(Icons.person_outline, service.providerName),
                      const SizedBox(height: 2),
                      _iconText(Icons.place_outlined, service.location),
                      const SizedBox(height: 2),
                      _iconText(Icons.access_time, service.availableTiming),
                      const SizedBox(height: 2),
                      _iconText(Icons.hourglass_bottom,
                          'Within ${service.timeLimitDays} days'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // RIGHT COLUMN
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg(service.serviceStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.serviceStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_empty, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${service.creditsPerHour} credits',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // View Applications (only when open)
                    if (showViewApplications) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceApplicationsPage(service: service),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'View Applications',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],

                    // Mark as completed (only when in progress)
                    if (showMarkCompleted) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: TextButton(
                          onPressed: () => _markAsCompleted(context),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF7ED9A2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                          ),
                          child: const Text(
                            'Mark as completed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsCompleted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(service.id)
          .update({'serviceStatus': 'completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service marked as completed.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
