import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../routes.dart';
import '../../models/service_model.dart';
import 'service_details_page.dart';

class NeedHelpPage extends StatelessWidget {
  const NeedHelpPage({super.key});

  // TEMP user id – later replace with FirebaseAuth uid
  static const String currentUserId = 'demoUser123';

  @override
  Widget build(BuildContext context) {
    // All OPEN services (for Services Available tab)
    final servicesAvailableQuery = FirebaseFirestore.instance
        .collection('services')
        .where('serviceType', isEqualTo: 'need')
        .where('serviceStatus', isEqualTo: 'open')
        .orderBy('createdDate', descending: true)
        .withConverter<Service>(
          fromFirestore: (snap, _) => Service.fromFirestore(snap),
          toFirestore: (service, _) => {},
        );

    // Only MY requests (for Your Request tab)
    final yourRequestsQuery = FirebaseFirestore.instance
        .collection('services')
        .where('serviceType', isEqualTo: 'need')
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
          toolbarHeight: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _headerTabs(),
              _searchAndFilterRow(context),
              Expanded(
                child: TabBarView(
                  children: [
                    // 1) Services Available – hide my own requests
                    _ServicesList(
                      query: servicesAvailableQuery,
                      hideOwn: true,
                    ),

                    // 2) Your Request – only my requests + Add Request button
                    _YourRequestTab(query: yourRequestsQuery),
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
            Text('Services Available'),
            Text('Your Request'),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Services',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              onChanged: (q) {
                // later: client-side filtering
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.needHelpFilter,
              );
              if (result != null) debugPrint('Filter result: $result');
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded underline for active tab
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

/// Your Request tab: list + Add Request button
class _YourRequestTab extends StatelessWidget {
  final Query<Service> query;
  const _YourRequestTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _ServicesList(query: query),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addRequest);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39C50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Add Request',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Uses a Firestore stream to show services
class _ServicesList extends StatelessWidget {
  final Query<Service> query;
  final bool hideOwn; // NEW

  const _ServicesList({
    required this.query,
    this.hideOwn = false, // default: don't hide
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Service>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        var services = docs.map((d) => d.data()).toList();

        // hide my own services, for Services Available tab
        if (hideOwn) {
          services = services
              .where((s) => s.requesterId != NeedHelpPage.currentUserId)
              .toList();
        }

        if (services.isEmpty) {
          return const Center(child: Text('No services yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _ServiceCard(service: services[i]),
        );
      },
    );
  }
}

/// Card UI – using Service from Firestore
class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return const Color(0xFFBFE8C9);
      case 'pending':
        return const Color(0xFFFBE1B8);
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                builder: (_) => ServiceDetailsPage(service: service),
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
                          text: 'Need Help: ',
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
