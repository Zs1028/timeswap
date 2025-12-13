import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      _nameCtrl.text = (data['name'] as String?)?.trim() ?? '';
      _phoneCtrl.text = (data['phone'] as String?)?.trim() ?? '';
    } catch (_) {
      // ignore, show empty fields
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _saving = true);

    try {
      final fs = FirebaseFirestore.instance;

      // 1) Update the main profile doc
      await fs.collection('users').doc(user.uid).set({
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2) OPTIONAL QUICK FIX:
      // Update old services that already stored providerName inside services docs.
      // If you later refactor UI to read from users/{providerId}, you can REMOVE this.
      final servicesSnap = await fs
          .collection('services')
          .where('providerId', isEqualTo: user.uid)
          .get();

      final batch = fs.batch();
      for (final d in servicesSnap.docs) {
        batch.update(d.reference, {
          'providerName': name,
          // if you store phone in services in future, update here too:
          // 'providerPhone': phone,
        });
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context, true); // return "updated" to previous page
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFF4D1);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _lineField(
                        label: 'Name',
                        controller: _nameCtrl,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      _lineField(
                        label: 'Phone Number',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF39C50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _lineField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
