import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

enum _HistoryFilter { all, earned, spent }

class _HistoryTxn {
  final String description;
  final double credits;
  final bool isEarned;
  final DateTime createdAt;

  _HistoryTxn({
    required this.description,
    required this.credits,
    required this.isEarned,
    required this.createdAt,
  });
}

String _formatCredits(double c) {
  if (c == c.roundToDouble()) return c.toInt().toString();
  return c.toString();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late Future<List<_HistoryTxn>> _future;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _future = _loadTransactions(uid);
  }

  Future<List<_HistoryTxn>> _loadTransactions(String? uid) async {
    if (uid == null) return [];

    final fs = FirebaseFirestore.instance;

    final helperSnap = await fs
        .collection('transactions')
        .where('helperId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .get();

    final helpeeSnap = await fs
        .collection('transactions')
        .where('helpeeId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .get();

    final List<_HistoryTxn> list = [];

    for (final doc in helperSnap.docs) {
      final data = doc.data();
      final double credits =
          (data['credits'] as num?)?.toDouble() ?? 0.0;
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      list.add(_HistoryTxn(
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
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      list.add(_HistoryTxn(
        description: 'Someone helped you.',
        credits: credits,
        isEarned: false,
        createdAt: createdAt,
      ));
    }

    // newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        title: const Text(
          'Transactions History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.filter_list),
          ),
        ],
      ),
      body: FutureBuilder<List<_HistoryTxn>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load transactions',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          var txns = snapshot.data ?? [];

          // apply filter
          txns = txns.where((t) {
            switch (_filter) {
              case _HistoryFilter.earned:
                return t.isEarned;
              case _HistoryFilter.spent:
                return !t.isEarned;
              case _HistoryFilter.all:
              default:
                return true;
            }
          }).toList();

          if (txns.isEmpty) {
            return Column(
              children: [
                _filterChips(),
                const Expanded(
                  child: Center(
                    child: Text('No transactions yet.'),
                  ),
                ),
              ],
            );
          }

          // group by date (already sorted newest first)
          final Map<String, List<_HistoryTxn>> grouped = {};
          for (final t in txns) {
            final key = _formatDate(t.createdAt);
            grouped.putIfAbsent(key, () => []).add(t);
          }

          final children = <Widget>[];
          children.add(_filterChips());

          grouped.forEach((date, items) {
            children.add(Container(
              width: double.infinity,
              color: Colors.grey.shade300,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ));

            for (final t in items) {
              children.add(Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t.isEarned ? '+' : '-'} ${_formatCredits(t.credits)} credits',
                      style: TextStyle(
                        color: t.isEarned
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ));
            }

            children.add(const SizedBox(height: 8));
          });

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: children,
          );
        },
      ),
    );
  }

  Widget _filterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _filter == _HistoryFilter.all,
            onSelected: (_) {
              setState(() => _filter = _HistoryFilter.all);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Earned'),
            selected: _filter == _HistoryFilter.earned,
            onSelected: (_) {
              setState(() => _filter = _HistoryFilter.earned);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Spent'),
            selected: _filter == _HistoryFilter.spent,
            onSelected: (_) {
              setState(() => _filter = _HistoryFilter.spent);
            },
          ),
        ],
      ),
    );
  }
}

/* ---------- HELPERS ---------- */

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final m = months[d.month - 1];
  return '${d.day} $m ${d.year}';
}
