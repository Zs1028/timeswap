// lib/screens/profile/provider_profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProviderProfilePage extends StatelessWidget {
  final String providerId;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Provider Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(providerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Provider not found.'));
            }

            final data = snapshot.data!.data() ?? {};

            final name = (data['name'] as String?) ?? 'Provider';
            final location =
                (data['state'] as String?) ??
                    (data['location'] as String?) ??
                    'Not set';
            final bio =
                (data['bio'] as String?) ??
                    (data['about'] as String?) ??
                    'This provider has not added a bio yet.';
            final phone = (data['phone'] as String?) ?? 'Not provided';

            final skillsRaw = data['skills'];
            final List<String> skills = skillsRaw is List
                ? skillsRaw.map((e) => e.toString()).toList()
                : [];

            final photoUrl = data['photoUrl'] as String?;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _ProviderHeaderCard(
                  name: name,
                  location: location,
                  phone: phone,
                  photoUrl: photoUrl,
                ),
                const SizedBox(height: 12),
                _BioCard(bio: bio),
                const SizedBox(height: 12),
                _ProviderStatsCard(userId: providerId),
                const SizedBox(height: 12),
                _SkillsCard(
                  title: 'Services Offered',
                  skills: skills,
                ),
                const SizedBox(height: 12),
                _RatingsCard(userId: providerId),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* -------------------- PROVIDER HEADER -------------------- */

class _ProviderHeaderCard extends StatelessWidget {
  final String name;
  final String location;
  final String phone;
  final String? photoUrl;

  const _ProviderHeaderCard({
    required this.name,
    required this.location,
    required this.phone,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      bg: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.place, size: 16, color: Colors.redAccent),
              const SizedBox(width: 4),
              Text(
                location,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 16),
              const SizedBox(width: 4),
              Text(
                phone,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black87,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/* -------------------- BIO (REUSED) -------------------- */

class _BioCard extends StatelessWidget {
  final String bio;
  const _BioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      bg: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/* -------------------- PROVIDER STATS -------------------- */

class _ProviderStatsCard extends StatelessWidget {
  final String userId;
  const _ProviderStatsCard({required this.userId});

  Future<Map<String, dynamic>> _loadStats() async {
    final fs = FirebaseFirestore.instance;

    final completedSnap = await fs
        .collection('transactions')
        .where('helperId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    final completedCount = completedSnap.size;

    final ratingsSnap = await fs
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .get();

    double avgRating = 0;
    if (ratingsSnap.docs.isNotEmpty) {
      final total = ratingsSnap.docs.fold<num>(0, (sum, d) {
        final r = (d.data()['rating'] as num?) ?? 0;
        return sum + r;
      });
      avgRating = total / ratingsSnap.docs.length;
    }

    return {
      'completed': completedCount,
      'avgRating': avgRating,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final completed = snapshot.data?['completed'] as int? ?? 0;
        final avgRating = snapshot.data?['avgRating'] as double? ?? 0.0;

        return _ShadowCard(
          bg: const Color(0xFFF5F5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Provider's Stats",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    '$completed services completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star_border,
                      size: 18, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    avgRating == 0
                        ? 'No ratings yet'
                        : '${avgRating.toStringAsFixed(1)} ratings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------- SKILLS (SERVICES OFFERED) -------------------- */

class _SkillsCard extends StatelessWidget {
  final String title;
  final List<String> skills;

  const _SkillsCard({
    required this.title,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      bg: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            Text(
              'No services added yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3F3DE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

/* -------------------- RATINGS LIST (REUSED) -------------------- */

class _RatingsCard extends StatelessWidget {
  final String userId;
  const _RatingsCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('ratingDate', descending: true)
        .limit(3);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
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
            bg: const Color(0xFFF5F5F5),
            child: Text(
              'Failed to load ratings.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        double avgRating = 0;
        if (docs.isNotEmpty) {
          final total = docs.fold<num>(0, (sum, d) {
            final rating = (d.data()['rating'] as num?) ?? 0;
            return sum + rating;
          });
          avgRating = total / docs.length;
        }

        return _ShadowCard(
          bg: const Color(0xFFF5F5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Ratings & Reviews Received',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Full reviews page coming soon')),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (docs.isEmpty)
                Text(
                  'No ratings yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...[
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${avgRating.toStringAsFixed(1)}/5.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${docs.length} review${docs.length > 1 ? 's' : ''})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...docs.map((d) {
                  final data = d.data();
                  final rating = (data['rating'] as num?)?.toInt() ?? 0;
                  final comment = (data['comment'] as String?) ?? '';
                  final ts = data['ratingDate'] as Timestamp?;
                  final dateTime = ts?.toDate() ?? DateTime.now();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStars(rating),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(dateTime),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            comment,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }
}

/* -------------------- SHARED -------------------- */

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

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
