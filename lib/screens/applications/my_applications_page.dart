import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import '../../models/service_application.dart';
import '../../routes.dart';

class MyApplicationsPage extends StatefulWidget {
  final String initialStatusFilter;

  const MyApplicationsPage({
    super.key,
    this.initialStatusFilter = 'pending',});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  late String _statusFilter;
  
  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = user.uid;

    final query = FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('requesterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .withConverter<ServiceApplication>(
          fromFirestore: (snap, _) => ServiceApplication.fromFirestore(snap),
          toFirestore: (_, __) => {},
        );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
  backgroundColor: const Color(0xFFFADF8E),
  elevation: 0,
  centerTitle: true,
  automaticallyImplyLeading: false,

  title: const Text(
    'My Applications',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),

  // ✅ Subtitle INSIDE AppBar
  bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Center(
              child: Text(
                'Services you have applied for',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            
             const SizedBox(height: 10),
            _buildStatusChips(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<ServiceApplication>>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  var apps = docs.map((d) => d.data()).toList();

                  // We will compute UI status per app once we join with the service.
                  if (apps.isEmpty) {
                    return const Center(
                      child: Text('You have not applied to any services yet.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return _ApplicationCard(
                        application: app,
                        statusFilter: _statusFilter,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 3),
    );
  }

  Widget _buildStatusChips() {
    // small helper to avoid repeating code
  Widget chip(String label, String value) {
        final bool selected = _statusFilter == value;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() => _statusFilter = value);
          },
          selectedColor: const Color(0xFFF39C50),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFFF39C50),
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: Color(0xFFF39C50)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // first row: Pending, In Progress, Accepted
            Row(
              children: [
                chip('Pending', 'pending'),
                const SizedBox(width: 8),
                chip('In Progress', 'inprogress'),
                const SizedBox(width: 8),
                chip('Accepted', 'accepted'),
              ],
            ),
            const SizedBox(height: 8),
            // second row: Declined, Completed
            Row(
              children: [
                chip('Declined', 'declined'),
                const SizedBox(width: 8),
                chip('Completed', 'completed'),
              ],
            ),
          ],
        ),
      );  
  }
}

/* ---------- Application Card (joins serviceRequests + services) ---------- */

class _ApplicationCard extends StatelessWidget {
  final ServiceApplication application;
  final String statusFilter;

  const _ApplicationCard({
    required this.application,
    required this.statusFilter,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    // Load the related service document
    final serviceRef = fs.collection('services').doc(application.serviceId);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: serviceRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final service = Service.fromFirestore(
          snapshot.data as DocumentSnapshot<Map<String, dynamic>>,
        );

        // Compute UI status for this card
        final uiStatus = _computeUiStatus(application, service);

        final displayStatus =
        (statusFilter == 'accepted' && uiStatus == 'inprogress')
            ? 'accepted'
            : uiStatus;

        // Filter here – if not matching the current chip, hide this card
        bool _matchesFilter(String uiStatus, String filter) {
          // "Accepted" tab should include accepted + inprogress + completed
          if (filter == 'accepted') {
            return uiStatus == 'accepted' || uiStatus == 'inprogress';
          }
          // other tabs match exactly
          return uiStatus == filter;
        }

        // ✅ IMPORTANT: apply the filter
        if (!_matchesFilter(uiStatus, statusFilter)) {
          return const SizedBox.shrink();
        }

        final isOffer = service.serviceType == 'offer';

        return Container(
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
              // later: you could navigate to ServiceDetailsPage if you want
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT column – main info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: isOffer ? 'Offer Help: ' : 'Need Help: ',
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
                        const SizedBox(height: 6),
                        _iconRow(
                          icon: Icons.person_outline,
                          text: service.providerName,
                        ),
                        const SizedBox(height: 2),
                        _iconRow(
                          icon: Icons.place_outlined,
                          text: service.location,
                        ),
                        const SizedBox(height: 2),
                        _iconRow(
                          icon: Icons.access_time,
                          text: service.availableTiming,
                        ),
                        const SizedBox(height: 2),
                        _iconRow(
                          icon: Icons.hourglass_bottom,
                          text:
                              '${service.creditsPerHour.toString()} credits ${isOffer ? 'offered' : 'required'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // RIGHT column – status + category + rate button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusChip(displayStatus),
                      const SizedBox(height: 6),
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

                      // Rate & Review – only when completed
                      if (uiStatus == 'completed') ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => _openRatingDialog(context, service),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFF39C50),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text(
                              'Rate',
                              style: TextStyle(
                                color: Color(0xFFF39C50),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
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
        );
      },
    );
  }

  /// Decide what UI status to show for this application.
  /// We combine serviceRequests.status + services.serviceStatus.
  static String _computeUiStatus(
      ServiceApplication app, Service service) {
    final appStatus = app.status.toLowerCase();
    final serviceStatus = service.serviceStatus.toLowerCase();

    if (appStatus == 'pending') return 'pending';
    if (appStatus == 'declined') return 'declined';

    // appStatus == 'accepted'
    if (serviceStatus == 'inprogress') return 'inprogress';
    if (serviceStatus == 'completed') return 'completed';

    // accepted but maybe serviceStatus still 'open'
    return 'accepted';
  }

  Widget _statusChip(String status) {
    Color bg;
    String label;

    switch (status) {
      case 'pending':
        bg = const Color(0xFFFBE1B8);
        label = 'Pending';
        break;
      case 'inprogress':
        bg = const Color(0xFFBFE8C9);
        label = 'In Progress';
        break;
      case 'accepted':
        bg = const Color(0xFFB3E5FC);
        label = 'Accepted';
        break;
      case 'declined':
        bg = const Color(0xFFFFCDD2);
        label = 'Declined';
        break;
      case 'completed':
        bg = const Color(0xFFCFD8DC);
        label = 'Completed';
        break;
      default:
        bg = Colors.grey.shade300;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _iconRow({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black87),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // ---------- Rating logic for applicant ----------
  Future<void> _openRatingDialog(BuildContext context, Service service) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to rate.')),
      );
      return;
    }

    final uid = user.uid;
    final bool isHelper = uid == service.helperId;
    final bool isHelpee = uid == service.helpeeId;

    if (!isHelper && !isHelpee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not part of this service.')),
      );
      return;
    }

    final String titleText = isHelper
        ? 'How was the person you helped?'
        : 'How was the person who helped you?';

    int selectedStars = 5;
    final commentCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                titleText,
                style: const TextStyle(fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Rating',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < selectedStars;
                      return IconButton(
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() => selectedStars = i + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write some comment... [Optional]',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveRating(
                      reviewerId: uid,
                      service: service,
                      stars: selectedStars,
                      comment: commentCtrl.text.trim(),
                      isHelper: isHelper,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your rating!')),
      );
    }
  }

  Future<void> _saveRating({
    required String reviewerId,
    required Service service,
    required int stars,
    required String comment,
    required bool isHelper,
  }) async {
    final fs = FirebaseFirestore.instance;
    final String revieweeId =
        isHelper ? service.helpeeId : service.helperId;

    if (revieweeId.isEmpty) return;

    await fs.collection('ratings').add({
      'serviceId': service.id,
      'transactionId': service.id,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'reviewerRole': isHelper ? 'helper' : 'helpee',
      'rating': stars,
      'comment': comment,
      'ratingDate': FieldValue.serverTimestamp(),
    });
  }
}

/* -------------------- BOTTOM NAV -------------------- */

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined), label: 'Services'),
        BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), label: 'Your Request'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined), label: 'My Application'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: (i) {
        if (i == currentIndex) return;

        switch (i) {
          case 0:
            Navigator.pushNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.services);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.yourRequests);
            break;
          case 3:
              Navigator.pushNamed(context, AppRoutes.myApplications);
            break;
          case 4:
            Navigator.pushNamed(context, AppRoutes.profile);
            break;
        }
      },
    );
  }
}
