import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';

class TimeCreditPage extends StatelessWidget {
  const TimeCreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.pushReplacementNamed(context, AppRoutes.login),
      );
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        title: const Text(
          'Time Credit Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _TimeCreditBody(uid: user.uid),
    );
  }
}

/* ---------- SIMPLE FORMATTER ---------- */

String _formatCredits(double c) {
  if (c == c.roundToDouble()) return c.toInt().toString(); // 10.0 -> "10"
  return c.toString(); // 1.5 -> "1.5"
}

/* ---------- DATA MODELS ---------- */

class _TxnItem {
  final String description;
  final double credits;
  final bool isEarned;
  final DateTime createdAt;

  _TxnItem({
    required this.description,
    required this.credits,
    required this.isEarned,
    required this.createdAt,
  });
}

class _TimeCreditData {
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final List<_TxnItem> recent;

  _TimeCreditData({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.recent,
  });
}

/* ---------- BODY (FUTUREBUILDER) ---------- */

class _TimeCreditBody extends StatelessWidget {
  final String uid;
  const _TimeCreditBody({required this.uid});

  Future<_TimeCreditData> _loadData() async {
    final fs = FirebaseFirestore.instance;

    // user balance (can be int or double in Firestore)
    final userSnap = await fs.collection('users').doc(uid).get();
    final double balance =
        (userSnap.data()?['timeCredits'] as num?)?.toDouble() ?? 0.0;

    // transactions – as helper (earned)
    final helperSnap = await fs
        .collection('transactions')
        .where('helperId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .get();

    // transactions – as helpee (spent)
    final helpeeSnap = await fs
        .collection('transactions')
        .where('helpeeId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .get();

    double totalEarned = 0.0;
    double totalSpent = 0.0;
    final List<_TxnItem> all = [];

    for (final doc in helperSnap.docs) {
      final data = doc.data();
      final double credits =
          (data['credits'] as num?)?.toDouble() ?? 0.0;
      totalEarned += credits;

      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      all.add(_TxnItem(
        description: 'You helped someone.',
        credits: credits,
        isEarned: true,
        createdAt: createdAt,
      ));
    }

    for (final doc in helpeeSnap.docs) {
      final data = doc.data();
      final double credits =
          (data['credits'] as num?)?.toDouble() ?? 0.0;
      totalSpent += credits;

      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      all.add(_TxnItem(
        description: 'Someone helped you.',
        credits: credits,
        isEarned: false,
        createdAt: createdAt,
      ));
    }

    // newest first
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recent = all.length > 3 ? all.sublist(0, 3) : all;

    return _TimeCreditData(
      balance: balance,
      totalEarned: totalEarned,
      totalSpent: totalSpent,
      recent: recent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TimeCreditData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load time credits',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final data = snapshot.data ??
            _TimeCreditData(
              balance: 0.0,
              totalEarned: 0.0,
              totalSpent: 0.0,
              recent: const [],
            );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TotalBalanceCard(
              balance: data.balance,
              earned: data.totalEarned,
              spent: data.totalSpent,
            ),
            const SizedBox(height: 16),
            _TransactionPreviewCard(
              items: data.recent,
            ),
          ],
        );
      },
    );
  }
}

/* ---------- TOP CARD (TOTAL BALANCE) ---------- */

class _TotalBalanceCard extends StatelessWidget {
  final double balance;
  final double earned;
  final double spent;

  const _TotalBalanceCard({
    required this.balance,
    required this.earned,
    required this.spent,
  });

  static const _orange = Color(0xFFF39C50);
  static const _paleYellow = Color(0xFFFADF8E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Time Credit Balance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _orange,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 32),
              const SizedBox(width: 8),
              Text(
                _formatCredits(balance),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniStat(
                context,
                label: 'Earned',
                value: earned,
                bg: _paleYellow,
                icon: Icons.arrow_upward,
              ),
              const SizedBox(width: 16),
              _miniStat(
                context,
                label: 'Spent',
                value: spent,
                bg: _paleYellow,
                icon: Icons.arrow_downward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    BuildContext context, {
    required String label,
    required double value,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFF39C50),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text(
                _formatCredits(value),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------- PREVIEW CARD (RECENT TXNS) ---------- */

class _TransactionPreviewCard extends StatelessWidget {
  final List<_TxnItem> items;
  const _TransactionPreviewCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Transaction History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFF39C50),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                      context, AppRoutes.transactionHistory);
                },
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(
              'No transactions yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        t.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${t.isEarned ? '+' : '-'} ${_formatCredits(t.credits)} credits',
                          style: TextStyle(
                            color: t.isEarned
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeAgo(t.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ---------- HELPERS ---------- */

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
