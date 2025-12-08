// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/your_requests_page.dart';
import '../applications/my_applications_page.dart';
import '../../routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety: if somehow no user, send to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),

      // AppBar with Logout button
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4D1),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.welcome);
              }
            },
          ),
        ],
      ),

      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data() ?? {};
            final userName = (data['name'] as String?) ?? 'Friend';

            // 🔥 timeCredits can be int or double in Firestore → read as num → double
            final double credits =
                (data['timeCredits'] as num?)?.toDouble() ?? 0.0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _Header(userName: userName),
                const SizedBox(height: 16),

                // Current balance card
                _CurrentBalanceCard(credits: credits),
                const SizedBox(height: 16),

                // Activity summary (stats from Firestore)
                _ActivitySummaryCard(uid: uid),
                const SizedBox(height: 16),

                // Recent activity (transactions)
                _RecentActivityCard(uid: uid),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: const _BottomNav(currentIndex: 0),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF39C50),
        onPressed: () {
          // later: maybe open "Create request / offer" chooser
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/* -------------------- SMALL HELPER FOR NUM FORMATTING -------------------- */

String _formatNum(num value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString(); // 10.0 -> "10"
  }
  return value.toString(); // 1.5 -> "1.5"
}

/* -------------------- HEADER -------------------- */

class _Header extends StatelessWidget {
  final String userName;
  const _Header({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFADF8E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            'Hi $userName!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile.jpg',
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- CURRENT BALANCE -------------------- */

class _CurrentBalanceCard extends StatelessWidget {
  final double credits; // 🔥 changed from int → double
  const _CurrentBalanceCard({required this.credits});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.timeCredits);
      },
      child: _ShadowCard(
        bg: const Color(0xFFF7A66B),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/wallet.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Time Credit Balance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You have ${_formatNum(credits)} credits available !',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- ACTIVITY SUMMARY -------------------- */

class _ActivitySummaryCard extends StatelessWidget {
  final String uid;
  const _ActivitySummaryCard({required this.uid});

  // use num so we can store both int & double safely
  Future<Map<String, num>> _loadSummary() async {
    final fs = FirebaseFirestore.instance;

    // 1) Your requests in progress  (services you created, type = need)
    final yourRequestsInProgressSnap = await fs
        .collection('services')
        .where('requesterId', isEqualTo: uid)
        .where('serviceType', isEqualTo: 'need')
        .where('serviceStatus', isEqualTo: 'inprogress')
        .get();

    // 2) Your offerings in progress  (services you created, type = offer)
    final yourOfferingsInProgressSnap = await fs
        .collection('services')
        .where('requesterId', isEqualTo: uid)
        .where('serviceType', isEqualTo: 'offer')
        .where('serviceStatus', isEqualTo: 'inprogress')
        .get();

    // 3) Your applications in progress
    //    (you applied to others' services; we count accepted + inprogress)
    final appsAcceptedSnap = await fs
        .collection('serviceRequests')
        .where('requesterId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final appsInProgressSnap = await fs
        .collection('serviceRequests')
        .where('requesterId', isEqualTo: uid)
        .where('status', isEqualTo: 'inprogress')
        .get();

    final int applicationsInProgress =
        appsAcceptedSnap.size + appsInProgressSnap.size;

    // 4) Service requests need your response (your "need help" listings that are still open)
    final requestsNeedResponseSnap = await fs
        .collection('services')
        .where('requesterId', isEqualTo: uid)
        .where('serviceType', isEqualTo: 'need')
        .where('serviceStatus', isEqualTo: 'open')
        .get();

    // 5) Service offerings need your response (your "offer help" listings still open)
    final offeringsNeedResponseSnap = await fs
        .collection('services')
        .where('requesterId', isEqualTo: uid)
        .where('serviceType', isEqualTo: 'offer')
        .where('serviceStatus', isEqualTo: 'open')
        .get();

    // 6) Hours earned this week (as helper)
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final earnedSnap = await fs
        .collection('transactions')
        .where('helperId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
        )
        .get();

    double hoursEarnedThisWeek = 0.0;
    for (final doc in earnedSnap.docs) {
      final data = doc.data();
      final double credits =
          (data['credits'] as num?)?.toDouble() ?? 0.0;
      hoursEarnedThisWeek += credits;
    }

    return {
      'yourRequestsInProgress': yourRequestsInProgressSnap.size,
      'yourOfferingsInProgress': yourOfferingsInProgressSnap.size,
      'applicationsInProgress': applicationsInProgress,
      'requestsNeedResponse': requestsNeedResponseSnap.size,
      'offeringsNeedResponse': offeringsNeedResponseSnap.size,
      'hoursEarnedThisWeek': hoursEarnedThisWeek,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, num>>(
      future: _loadSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _ShadowCard(
            bg: Colors.white,
            child: Text(
              'Failed to load activity summary',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final data = snapshot.data ??
            {
              'yourRequestsInProgress': 0,
              'yourOfferingsInProgress': 0,
              'applicationsInProgress': 0,
              'requestsNeedResponse': 0,
              'offeringsNeedResponse': 0,
              'hoursEarnedThisWeek': 0.0,
            };

        return _ShadowCard(
          bg: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),

              // 1) Your requests in progress  → "Services You Requested" tab, status = inprogress
            _summaryRow(
              context,
              label: 'Your requests in progress',
              value: data['yourRequestsInProgress'] ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YourRequestsPage(
                      initialTabIndex: 1,              // tab 1 = Services You Requested
                      initialOfferedStatus: 'open',    // leave offered tab as open
                      initialRequestedStatus: 'inprogress',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 2) Your offerings in progress → "Services You Offered" tab, status = inprogress
            _summaryRow(
              context,
              label: 'Your offerings in progress',
              value: data['yourOfferingsInProgress'] ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YourRequestsPage(
                      initialTabIndex: 0,              // tab 0 = Services You Offered
                      initialOfferedStatus: 'inprogress',
                      initialRequestedStatus: 'open',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 3) Your applications in progress → MyApplicationsPage, status = inprogress
            _summaryRow(
              context,
              label: 'Your applications in progress',
              value: data['applicationsInProgress'] ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyApplicationsPage(
                      initialStatusFilter: 'inprogress',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 4) Service requests need your response → requested tab, status = open
            _summaryRow(
              context,
              label: 'Service requests need your response',
              value: data['requestsNeedResponse'] ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const YourRequestsPage(
                      initialTabIndex: 1,               // Services You Requested
                      initialOfferedStatus: 'open',
                      initialRequestedStatus: 'open',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 5) Service offerings need your response → offered tab, status = open
            _summaryRow(
              context,
              label: 'Service offerings need your response',
              value: data['offeringsNeedResponse'] ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const YourRequestsPage(
                      initialTabIndex: 0,               // Services You Offered
                      initialOfferedStatus: 'open',
                      initialRequestedStatus: 'open',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 6) Hours earned this week → Time Credits page (already correct)
            _summaryRow(
              context,
              label: 'Hours earned this week',
              value: data['hoursEarnedThisWeek'] ?? 0.0,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.timeCredits);
              },
            ),

            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required String label,
    required num value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              _formatNum(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}


/* -------------------- RECENT TRANSACTIONS -------------------- */

class _RecentActivityItem {
  final String text;
  final DateTime time;
  _RecentActivityItem({required this.text, required this.time});
}

class _RecentActivityCard extends StatelessWidget {
  final String uid;
  const _RecentActivityCard({required this.uid});

  Future<String> _getUserName(
    FirebaseFirestore fs,
    String userId,
    Map<String, String> cache,
  ) async {
    if (userId.isEmpty) return 'someone';

    if (cache.containsKey(userId)) {
      return cache[userId]!;
    }

    final snap = await fs.collection('users').doc(userId).get();
    final data = snap.data();
    final name = (data?['name'] as String?) ?? 'someone';
    cache[userId] = name;
    return name;
  }

  Future<List<_RecentActivityItem>> _loadRecentActivities() async {
    final fs = FirebaseFirestore.instance;
    final nameCache = <String, String>{};

    // Transactions where YOU are the helper (you earned credits)
    final asHelperSnap = await fs
        .collection('transactions')
        .where('helperId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    // Transactions where YOU are the helpee (you spent credits)
    final asHelpeeSnap = await fs
        .collection('transactions')
        .where('helpeeId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    final items = <_RecentActivityItem>[];

    // You helped others
    for (final doc in asHelperSnap.docs) {
      final data = doc.data();
      final String helpeeId = data['helpeeId'] as String? ?? '';
      final String serviceTitle =
          data['serviceTitle'] as String? ?? 'this service';
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      final helpeeName =
          await _getUserName(fs, helpeeId, nameCache); // e.g. Kitty

      items.add(
        _RecentActivityItem(
          text: 'Helped $helpeeName with $serviceTitle',
          time: createdAt,
        ),
      );
    }

    // You received help
    for (final doc in asHelpeeSnap.docs) {
      final data = doc.data();
      final String helperId = data['helperId'] as String? ?? '';
      final String serviceTitle =
          data['serviceTitle'] as String? ?? 'this service';
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      final helperName =
          await _getUserName(fs, helperId, nameCache); // e.g. Josephine

      items.add(
        _RecentActivityItem(
          text: 'Received $serviceTitle from $helperName',
          time: createdAt,
        ),
      );
    }

    // Newest first
    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RecentActivityItem>>(
      future: _loadRecentActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _ShadowCard(
            bg: const Color(0xFFF7A66B),
            child: Text(
              'Failed to load recent transactions',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];

        return _ShadowCard(
          bg: const Color(0xFFF7A66B),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.transactionHistory);
                    },
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (activities.isEmpty)
                Text(
                  'No transactions yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final a = activities[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle,
                                size: 8, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(a.time),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/* -------------------- SHARED WIDGETS -------------------- */

class _ShadowCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  const _ShadowCard({required this.child, this.bg = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
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
