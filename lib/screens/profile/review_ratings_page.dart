import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewRatingsPage extends StatelessWidget {
  final String userId;   // revieweeId (the person being rated)

  const ReviewRatingsPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final ratingsQuery = FirebaseFirestore.instance
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('ratingDate', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Ratings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: ratingsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text('No ratings yet.'),
              );
            }

            // Convert docs → simple maps
            final ratings = docs
                .map((d) => {
                      'id': d.id,
                      ...d.data() as Map<String, dynamic>,
                    })
                .toList();

            // Group by date label (Today / Yesterday / 4 Dec 2025)
            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (final r in ratings) {
              final ts = r['ratingDate'] as Timestamp?;
              final date = ts?.toDate();
              final label = _formatDateLabel(date);
              grouped.putIfAbsent(label, () => []).add(r);
            }

            final dateSections = grouped.entries.toList();

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: dateSections.length,
              itemBuilder: (context, index) {
                final entry = dateSections[index];
                final sectionTitle = entry.key;
                final sectionRatings = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grey date header
                    Container(
                      color: const Color(0xFFE0E0E0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Text(
                        sectionTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Ratings under this date
                    ...sectionRatings.map(
                      (r) => _RatingTile(
                        ratingData: r,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Simple date label: Today / Yesterday / 4 Dec 2025
  String _formatDateLabel(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';

    // Manual format: 4 Dec 2025
    const monthNames = [
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
      'Dec',
    ];
    final day = d.day;
    final month = monthNames[d.month - 1];
    final year = d.year;
    return '$day $month $year';
  }
}

class _RatingTile extends StatelessWidget {
  final Map<String, dynamic> ratingData;

  const _RatingTile({required this.ratingData});

  @override
  Widget build(BuildContext context) {
    final int stars = (ratingData['rating'] as int?) ?? 0;
    final String comment = (ratingData['comment'] as String?) ?? '';
    final String reviewerId = (ratingData['reviewerId'] as String?) ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer row (icon + name)
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                child: Icon(
                  Icons.person,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReviewerNameText(reviewerId: reviewerId),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Stars
          Row(
            children: List.generate(5, (i) {
              final filled = i < stars;
              return Icon(
                filled ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(height: 4),

          // Comment
          if (comment.isNotEmpty)
            Text(
              comment,
              style: const TextStyle(fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _ReviewerNameText extends StatelessWidget {
  final String reviewerId;

  const _ReviewerNameText({required this.reviewerId});

  @override
  Widget build(BuildContext context) {
    if (reviewerId.isEmpty) {
      return const Text(
        'Unknown user',
        style: TextStyle(fontWeight: FontWeight.w600),
      );
    }

    // Get name from `users` collection
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(reviewerId);

    return FutureBuilder<DocumentSnapshot>(
      future: docRef.get(),
      builder: (context, snapshot) {
        String name = 'User';
        if (snapshot.connectionState == ConnectionState.waiting) {
          name = 'Loading...';
        } else if (snapshot.hasError) {
          name = 'User';
        } else if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final n = (data['name'] as String?)?.trim();
          if (n != null && n.isNotEmpty) {
            name = n;
          }
        }

        return Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        );
      },
    );
  }
}
