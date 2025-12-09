import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
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
            final name = (data['name'] as String?) ?? 'User';
            final location = (data['location'] as String?) ?? 'Not set';
            final about = (data['about'] as String?) ??
                'Tell others more about yourself.';

            // credits as double (works for old int + new double)
            final double timeCredits =
                (data['timeCredits'] as num?)?.toDouble() ?? 0.0;

            // skills can be List<String> (new) OR a single String (old create profile)
            final dynamic skillsRaw = data['skills'];
            List<String> skills = [];
            if (skillsRaw is List) {
              skills = skillsRaw.map((e) => e.toString()).toList();
            } else if (skillsRaw is String && skillsRaw.trim().isNotEmpty) {
              skills = skillsRaw
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }

            final photoUrl = data['photoUrl'] as String?;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _ProfileHeaderCard(
                  name: name,
                  location: location,
                  credits: timeCredits,
                  photoUrl: photoUrl,
                ),
                const SizedBox(height: 12),
                _BioCard(about: about),
                const SizedBox(height: 12),
                _StatsCard(userId: uid),
                const SizedBox(height: 12),
                _SkillsCard(skills: skills),
                const SizedBox(height: 12),
                _RatingsCard(userId: uid),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 4),
    );
  }
}

/* -------------------- HEADER CARD -------------------- */

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String location;
  final double credits;
  final String? photoUrl;

  const _ProfileHeaderCard({
    required this.name,
    required this.location,
    required this.credits,
    this.photoUrl,
  });

  String _formatCredits(double c) {
    if (c == c.roundToDouble()) {
      return c.toInt().toString(); // 10.0 -> "10"
    }
    return c.toString(); // 1.5 -> "1.5"
  }

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      bg: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar on top, centered
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage:
                (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_bottom, size: 16),
              const SizedBox(width: 4),
              Text(
                '${_formatCredits(credits)} credits',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------- BIO CARD -------------------- */

class _BioCard extends StatelessWidget {
  final String about;
  const _BioCard({required this.about});

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered title + edit icon on the right
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Bio',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditBioPage(currentBio: about),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            about,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/* -------------------- STATS CARD -------------------- */

class _StatsCard extends StatelessWidget {
  final String userId;
  const _StatsCard({required this.userId});

  Future<Map<String, num>> _loadStats() async {
    final fs = FirebaseFirestore.instance;

    // Completed services where this user is helper
    final helperSnap = await fs
        .collection('services')
        .where('helperId', isEqualTo: userId)
        .where('serviceStatus', isEqualTo: 'completed')
        .get();

    // Completed services where this user is helpee
    final helpeeSnap = await fs
        .collection('services')
        .where('helpeeId', isEqualTo: userId)
        .where('serviceStatus', isEqualTo: 'completed')
        .get();

    final completedCount = helperSnap.size + helpeeSnap.size;

    // Ratings received
    final ratingsSnap = await fs
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .get();

    double avgRating = 0.0;
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
      'reviewCount': ratingsSnap.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, num>>(
      future: _loadStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ShadowCard(
            bg: Colors.white,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _ShadowCard(
            bg: Colors.white,
            child: Text(
              'Failed to load stats',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final completed = (data['completed'] ?? 0).toInt();
        final avgRating = (data['avgRating'] ?? 0).toDouble();
        final reviewCount = (data['reviewCount'] ?? 0).toInt();

        return _ShadowCard(
          bg: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'My Stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 10),
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
                    reviewCount == 0
                        ? 'No ratings yet'
                        : '${avgRating.toStringAsFixed(1)} average rating ($reviewCount review${reviewCount > 1 ? 's' : ''})',
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

/* -------------------- SKILLS CARD -------------------- */

class _SkillsCard extends StatelessWidget {
  final List<String> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'What I offer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddSkillPage(existingSkills: skills),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            Text(
              'No skills added yet.',
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
                        color: const Color(0xFFE9F6FF),
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

/* -------------------- RATINGS CARD -------------------- */

class _RatingsCard extends StatelessWidget {
  final String userId;
  const _RatingsCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('ratingDate', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ShadowCard(
            bg: Colors.white,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _ShadowCard(
            bg: Colors.white,
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
          bg: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Rating & Reviews Received',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Full reviews page coming soon.')),
                      );
                    },
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (docs.isEmpty)
                Text(
                  'No ratings yet. Once you complete sessions, reviews will show here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...[
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${avgRating.toStringAsFixed(1)}/5.0',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
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
                  return _ReviewItem(data: data);
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReviewItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final rating = (data['rating'] as num?)?.toInt() ?? 0;
    final comment = (data['comment'] as String?) ?? '';
    final ts = data['ratingDate'] as Timestamp?;
    final dateTime = ts?.toDate() ?? DateTime.now();
    final reviewerId = data['reviewerId'] as String? ?? '';

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerId)
          .get(),
      builder: (context, snapshot) {
        String reviewerName = 'Someone';
        if (snapshot.hasData && snapshot.data?.data() != null) {
          reviewerName =
              (snapshot.data!.data()!['name'] as String?) ?? 'Someone';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStars(rating),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'by $reviewerName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
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

/* -------------------- EDIT BIO PAGE -------------------- */

class EditBioPage extends StatefulWidget {
  final String currentBio;
  const EditBioPage({super.key, required this.currentBio});

  @override
  State<EditBioPage> createState() => _EditBioPageState();
}

class _EditBioPageState extends State<EditBioPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'about': _bioCtrl.text.trim()}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save bio: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        title: const Text('Add a bio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(16),
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit your bio',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter a bio' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------- ADD SKILL PAGE -------------------- */

class AddSkillPage extends StatefulWidget {
  final List<String> existingSkills;
  const AddSkillPage({super.key, required this.existingSkills});

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _skillCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newSkill = _skillCtrl.text.trim();
    if (newSkill.isEmpty) return;

    setState(() => _saving = true);
    try {
      final updatedSkills = [...widget.existingSkills];
      if (!updatedSkills.contains(newSkill)) {
        updatedSkills.add(newSkill);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'skills': updatedSkills}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save skill: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        title: const Text('Add skills'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(16),
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add new skills',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _skillCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter new skills ...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a skill'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE74C3C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------- SHARED HELPERS -------------------- */

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
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
