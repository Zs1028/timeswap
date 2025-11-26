 import 'package:flutter/material.dart';
 import 'package:firebase_auth/firebase_auth.dart';

 import '../../routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ----- DUMMY DATA (replace with Firestore later) -----
  final String userName = 'Sarah';
  final int credits = 10;

  final Map<String, int> requestStats = const {
    'Total Request': 6,
    'Pending': 2,
    'Accepted': 3,
    'Ongoing': 1,
    'Completed': 0,
  };

  final Map<String, int> serviceStats = const {
    'Total Service': 4,
    'Pending': 1,
    'Accepted': 2,
    'Ongoing': 1,
    'Completed': 1,
  };

  final List<_Activity> activities = const [
    _Activity('You recently completed a session with Alex.', '2h ago'),
    _Activity('Your request to John is pending confirmation.', '5h ago'),
    _Activity('You earned 2.0 hours from Jane.', '6h ago'),
    _Activity('Your request to Mei Lee is pending confirmation.', '7h ago'),
  ];
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _Header(userName: userName),
            const SizedBox(height: 16),

            // Current balance card
            _ShadowCard(
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
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Time Credit Balance',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            )),
                        const SizedBox(height: 6),
                        Text('You have $credits credits available !',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Request/Service stats row
            Row(
              children: [
                Expanded(child: _StatsCard(title: 'Your Request', stats: requestStats)),
                const SizedBox(width: 12),
                Expanded(child: _StatsCard(title: 'Your Service', stats: serviceStats)),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Activity
            _ShadowCard(
              bg: const Color(0xFFF7A66B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Recent Activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => debugPrint('View all'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...activities.map((a) => _ActivityRow(activity: a)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),

      // “Create” floating button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF39C50),
        onPressed: () => debugPrint('Create new item'),
        child: const Icon(Icons.add),
      ),

      // Bottom nav (static for now)
      bottomNavigationBar: _BottomNav(currentIndex: 0),
    );
  }
}

// ======= Sub-widgets =======

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

          /// 🔥 LOGOUT BUTTON (TEMPORARY)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.welcome);
              }
            },
          ),

          // Existing profile picture
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

class _StatsCard extends StatelessWidget {
  final String title;
  final Map<String, int> stats;
  const _StatsCard({required this.title, required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList();
    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Text('${e.value}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Activity {
  final String text;
  final String timeAgo;
  const _Activity(this.text, this.timeAgo);
}

class _ActivityRow extends StatelessWidget {
  final _Activity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(activity.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    )),
          ),
          const SizedBox(width: 8),
          Text(activity.timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  )),
        ],
      ),
    );
  }
}
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
        BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), label: 'Services'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Your Request'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tab $i coming soon')),
            );
        }
      },
    );
  }
}