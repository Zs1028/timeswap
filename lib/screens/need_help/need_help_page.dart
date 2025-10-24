import 'package:flutter/material.dart';

class NeedHelpPage extends StatelessWidget {
  const NeedHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF4D1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF4D1),
          elevation: 0,
          toolbarHeight: 0, // hide normal appbar height; we draw our own segmented header
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Segmented header (Help Available | Your Request | Helper Application)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFADF8E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                  child: TabBar(
                    labelPadding: const EdgeInsets.symmetric(vertical: 8),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.black54,
                    indicator: const _RoundedUnderlineIndicator(),
                    tabs: const [
                      Text('Help Available'),
                      Text('Your Request'),
                      Text('Helper Application'),
                    ],
                  ),
                ),
              ),

              // Search + filter row
              Padding(
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                          // later: filter list
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => debugPrint('Open filters'),
                      icon: const Icon(Icons.tune),
                      tooltip: 'Filters',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs content
              Expanded(
                child: TabBarView(
                  children: [
                    // 1) Help Available
                    _ServicesList(dummyServices),

                    // 2) Your Request (placeholder for now)
                    _ServicesList(dummyRequests),

                    // 3) Helper Application (placeholder for now)
                    _ServicesList(dummyApplications),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nice rounded underline for the active tab (to match your Figma)
class _RoundedUnderlineIndicator extends Decoration {
  const _RoundedUnderlineIndicator();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _RoundedUnderlinePainter();
}

class _RoundedUnderlinePainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final rect = Offset(offset.dx, cfg.size!.height - 3) & Size(cfg.size!.width, 3);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }
}

/// List of services (reusable for each tab)
class _ServicesList extends StatelessWidget {
  final List<Service> items;
  const _ServicesList(this.items);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ServiceCard(service: items[i]),
    );
  }
}

/// One service card (UI only for now)
class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'open': return const Color(0xFFBFE8C9);     // greenish
      case 'pending': return const Color(0xFFFBE1B8);  // orange-ish
      default: return Colors.grey.shade300;
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
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => debugPrint('Open ${service.title}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Status + Category
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Offer Help: ',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                          children: [
                            TextSpan(
                              text: service.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(service.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(service.status, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _iconText(Icons.person_outline, service.name),
                    _iconText(Icons.place_outlined, service.location),
                    _iconText(Icons.event, service.schedule),
                    _iconText(Icons.hourglass_bottom, 'Within ${service.withinDays} days'),
                    _chip(service.category),
                    _credits(service.credits),
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
        Text(text, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
    );
  }

  Widget _credits(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, size: 16),
          const SizedBox(width: 4),
          Text('$value credits', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Simple data model (dummy)
class Service {
  final String title;
  final String name;
  final String location;
  final String schedule;  // e.g. 'Weekdays 9AM - 11AM' or 'Flexible Timing'
  final int withinDays;   // e.g. 7
  final String status;    // 'Pending' | 'Open'
  final String category;  // e.g. 'Transportation'
  final int credits;

  const Service({
    required this.title,
    required this.name,
    required this.location,
    required this.schedule,
    required this.withinDays,
    required this.status,
    required this.category,
    required this.credits,
  });
}

// ---------- Dummy lists ----------
const dummyServices = <Service>[
  Service(
    title: 'go to airport',
    name: 'Jane',
    location: 'Setapak',
    schedule: 'Weekdays 9AM - 11AM',
    withinDays: 7,
    status: 'Pending',
    category: 'Transportation',
    credits: 3,
  ),
  Service(
    title: 'Garden Clean Up',
    name: 'Ahmad Rahman',
    location: 'Wangsa Maju',
    schedule: 'Every Saturday Morning',
    withinDays: 3,
    status: 'Pending',
    category: 'Home Services',
    credits: 2,
  ),
  Service(
    title: 'Basic Computer Skills Tutorial',
    name: 'Kumar Devi',
    location: 'Selayang Community Center',
    schedule: 'Flexible Timing',
    withinDays: 10,
    status: 'Open',
    category: 'Education',
    credits: 5,
  ),
  Service(
    title: 'Haircut for Senior',
    name: 'Joanne Cheng',
    location: 'Kepong area',
    schedule: 'Weekdays 9AM - 11AM',
    withinDays: 7,
    status: 'Open',
    category: 'Elderly Support',
    credits: 3,
  ),
];

const dummyRequests = <Service>[
  Service(
    title: 'Fix leaky faucet',
    name: 'You',
    location: 'Gombak',
    schedule: 'Weekend Afternoon',
    withinDays: 2,
    status: 'Pending',
    category: 'Home Services',
    credits: 2,
  ),
];

const dummyApplications = <Service>[
  Service(
    title: 'Tutor form submitted',
    name: 'You',
    location: '—',
    schedule: '—',
    withinDays: 0,
    status: 'Open',
    category: 'Education',
    credits: 0,
  ),
];
