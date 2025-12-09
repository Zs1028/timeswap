import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/service_model.dart';
import '../../routes.dart';
import '../need_help/service_details_page.dart';
import '../need_help/filter_page.dart'; // 👈 for NeedHelpFilters

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _searchQuery = '';
  NeedHelpFilters _filters = NeedHelpFilters.empty;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offeredQuery = FirebaseFirestore.instance
        .collection('services')
        .where('serviceType', isEqualTo: 'offer')
        .where('serviceStatus', isEqualTo: 'open')
        .orderBy('createdDate', descending: true)
        .withConverter<Service>(
          fromFirestore: (snap, _) => Service.fromFirestore(snap),
          toFirestore: (service, _) => {},
        );

    final requestedQuery = FirebaseFirestore.instance
        .collection('services')
        .where('serviceType', isEqualTo: 'need')
        .where('serviceStatus', isEqualTo: 'open')
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
            'Services',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
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
                    _ServicesList(
                      query: offeredQuery,
                      hideOwn: true,
                      titlePrefix: 'Offer Help: ',
                      emptyText: 'No offered services yet.',
                      searchQuery: _searchQuery,
                      filters: _filters,
                    ),
                    _ServicesList(
                      query: requestedQuery,
                      hideOwn: true,
                      titlePrefix: 'Need Help: ',
                      emptyText: 'No requested services yet.',
                      searchQuery: _searchQuery,
                      filters: _filters,
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

  Widget _searchAndFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Services',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (q) {
                        setState(() {
                          _searchQuery = q;
                        });
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        AppRoutes.needHelpFilter,
                        arguments: _filters,
                      );

                      if (result is NeedHelpFilters) {
                        setState(() {
                          _filters = result;
                        });
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.tune, size: 20),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
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

class _ServicesList extends StatelessWidget {
  final Query<Service> query;
  final bool hideOwn;
  final String titlePrefix;
  final String emptyText;

  final String searchQuery;
  final NeedHelpFilters filters;

  const _ServicesList({
    required this.query,
    required this.titlePrefix,
    required this.emptyText,
    required this.searchQuery,
    required this.filters,
    this.hideOwn = false,
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

        // 🔐 Hide my own services when looking at “Services” page
        if (hideOwn) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final uid = user.uid;
            services = services.where((s) => s.requesterId != uid).toList();
          }
        }

        // 🔍 Apply search by title
        final q = searchQuery.trim().toLowerCase();
        if (q.isNotEmpty) {
          services = services.where((s) {
            final title = s.serviceTitle.toLowerCase();
            return title.contains(q);
          }).toList();
        }

        // 🏷 Filter by category
        if (filters.category != null && filters.category!.isNotEmpty) {
          services = services
              .where((s) => s.category == filters.category)
              .toList();
        }

        // 📍 Filter by location (state) using the beginning of `location`
        if (filters.location != null && filters.location!.isNotEmpty) {
          final locFilter = filters.location!.toLowerCase();
          services = services.where((s) {
            final loc = s.location.toLowerCase();
            // location format like "Selangor - Setapak"
            return loc.startsWith(locFilter);
          }).toList();
        }

        if (services.isEmpty) {
          return Center(child: Text(emptyText));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _ServiceCard(
            service: services[i],
            titlePrefix: titlePrefix,
          ),
        );
      },
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
                builder: (_) => ServiceDetailsPage(
                  service: service,
                  showRequestButton: true, // 👈 from SERVICES page
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
