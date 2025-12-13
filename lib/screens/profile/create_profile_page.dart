import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../welcome/widgets/clock_logo.dart';
import 'package:timeswap/routes.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _about = TextEditingController();

  // new: we no longer use a single skills TextField
  final _customSkillController = TextEditingController();

  String? _location; // dropdown (state)

  // new: selected skills list
  final List<String> _selectedSkills = [];

  // quick-select skill options
  final List<String> _quickSkills = const [
    'Transport',
    'Tutoring',
    'Cooking',
    'Cleaning',
    'Pet Care',
    'Elder Care',
    'Gardening',
    'Tech Support',
  ];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _saving = false;

  @override
  void dispose() {
    _about.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  void _toggleQuickSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _addCustomSkill() {
    final text = _customSkillController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedSkills.contains(text)) {
      setState(() {
        _selectedSkills.add(text);
      });
    }
    _customSkillController.clear();
  }

  Future<void> _saveProfile() async {
    // 1) Validate basic form
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_location == null || _location!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location')),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add at least one skill')),
      );
      return;
    }

    // 2) Get current user
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user. Please log in again.')),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() => _saving = true);

    try {
      final now = FieldValue.serverTimestamp();

      // 3) Save to Firestore: users/<uid>
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,

        // New naming to match ProviderProfilePage:
        'bio': _about.text.trim(),
        'state': _location,
        'skills': _selectedSkills, // store as List<String>

        // Keep old keys too (backwards compatibility, safe if used elsewhere)
        'about': _about.text.trim(),
        'location': _location,

        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;

      // 4) Go to Home after success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 4),
            Text(
              'Let other people know more about you!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Describe more about yourself'),
                  TextFormField(
                    controller: _about,
                    maxLines: 3,
                    decoration: _input('Write a short bio'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Please write a bio'
                            : null,
                  ),

                  _label('Where do you stay?'),
                  _LocationDropdown(
                    value: _location,
                    onChanged: (v) => setState(() => _location = v),
                  ),

                  _buildSkillsSection(),

                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39C50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Profile',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Center(child: ClockLogo()),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        ),
      );

  // -------- Skills Section (quick select + chips + custom input) --------
  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('What can you help others with? *'),

        // Quick select label
        Text(
          'Quick select:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 6),

        // Quick select chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSkills.map((skill) {
            final selected = _selectedSkills.contains(skill);
            return ChoiceChip(
              label: Text(skill),
              selected: selected,
              onSelected: (_) => _toggleQuickSkill(skill),
              selectedColor: const Color(0xFFD3F3DE),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Your skills
        Text(
          'Your skills:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        if (_selectedSkills.isEmpty)
          Text(
            'No skills selected yet.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSkills.map((s) {
              return Chip(
                label: Text(s),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedSkills.remove(s);
                  });
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        // Add custom skill
        Text(
          'Add custom skill:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _customSkillController,
          decoration: _input('Type here...').copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCustomSkill,
            ),
          ),
          onSubmitted: (_) => _addCustomSkill(),
        ),
      ],
    );
  }
}

// location dropdown widget (same as before)
class _LocationDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _LocationDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = <String>[
      'Johor',
      'Kedah',
      'Kelantan',
      'Melaka',
      'Negeri Sembilan',
      'Pahang',
      'Perak',
      'Perlis',
      'Penang',
      'Sabah',
      'Sarawak',
      'Selangor',
      'Terengganu',
      'Kuala Lumpur',
    ];

    return DropdownButtonFormField<String>(
      value: value,
      items: options
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        ),
      ),
      hint: const Text('Select your location'),
    );
  }
}
