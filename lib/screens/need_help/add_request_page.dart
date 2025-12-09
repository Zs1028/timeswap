import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRequestPage extends StatefulWidget {
  const AddRequestPage({super.key});

  @override
  State<AddRequestPage> createState() => _AddRequestPageState();
}

class _AddRequestPageState extends State<AddRequestPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController(); // e.g. 27/7/2025
  final _fromTimeController = TextEditingController(); // e.g. 4:00 PM
  final _toTimeController = TextEditingController(); // e.g. 6:00 PM

  // optional flexible timing note
  final _flexibleNotesController = TextEditingController();

  // location details (optional)
  final _locationDetailsController = TextEditingController();

  // Dropdown selections
  String? _selectedCategory;
  String? _selectedState;
  double? _selectedCredits;

  bool _isSubmitting = false;

  // Category options
  final List<String> _categories = const [
    'Home Services',
    'Education & Tutoring',
    'Transportation',
    'Care & Support',
    'Food & Cooking',
    'Handyman & Repairs',
    'Technology & IT',
    'Creative & Arts',
    'Other',
  ];

  // Malaysia states
  final List<String> _states = const [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'W.P. Kuala Lumpur',
  ];

  // Time credits required options
  final List<Map<String, dynamic>> _creditOptions = const [
    {'label': '1 hour (1 credit)', 'value': 1.0},
    {'label': '1.5 hours (1.5 credits)', 'value': 1.5},
    {'label': '2 hours (2 credits)', 'value': 2.0},
    {'label': '3 hours (3 credits)', 'value': 3.0},
    {'label': '4 hours (4 credits)', 'value': 4.0},
    {'label': '5+ hours (5+ credits)', 'value': 5.0},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    _flexibleNotesController.dispose();
    _locationDetailsController.dispose();
    super.dispose();
  }

  // ---------- DATE & TIME PICKERS (same behaviour as AddOfferingPage) ----------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateController.text =
          '${picked.day}/${picked.month}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      controller.text = picked.format(context);
      setState(() {});
    }
  }

  // --------------- SUBMIT LOGIC ---------------

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    final String currentUserId = user.uid;

    // ⭐ NEW: try to use profile name from `users` collection
    String currentUserName;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final data = userDoc.data();
      final profileName = (data?['name'] as String?)?.trim();

      if (profileName != null && profileName.isNotEmpty) {
        currentUserName = profileName;
      } else if ((user.displayName ?? '').trim().isNotEmpty) {
        currentUserName = user.displayName!.trim();
      } else {
        currentUserName = user.email ?? 'TimeSwap User';
      }
    } catch (_) {
      // if anything fails, fall back to email
      currentUserName = user.email ?? 'TimeSwap User';
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();
    final from = _fromTimeController.text.trim();
    final to = _toTimeController.text.trim();
    final flexibleNotes = _flexibleNotesController.text.trim();
    final locationDetails = _locationDetailsController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        date.isEmpty ||
        from.isEmpty ||
        to.isEmpty ||
        _selectedCategory == null ||
        _selectedState == null ||
        _selectedCredits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final String state = _selectedState!;
    final double creditsRequired = _selectedCredits!;

    // For main "location" field, combine state + details if provided
    final String location =
        locationDetails.isEmpty ? state : '$state - $locationDetails';

    final availableTiming = '$date, $from - $to';

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('services').add({
        'serviceTitle': title,
        'serviceDescription': description,
        'category': _selectedCategory,
        'location': location,
        'locationState': state,
        'locationDetails': locationDetails,
        'availableTiming': availableTiming,
        'flexibleNotes': flexibleNotes,
        'creditsPerHour': creditsRequired, // double
        'serviceStatus': 'open',

        // The person who needs help
        'requesterId': currentUserId,
        // For "need help", requester also owns the listing
        'providerId': currentUserId,
        'providerName': currentUserName,

        'serviceType': 'need',
        'createdDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request created successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // --------------- UI ---------------

  @override
  Widget build(BuildContext context) {
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
          'Add Request Form',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Title *',
                        controller: _titleController,
                        hint: 'Need Help with Moving Boxes',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Description *',
                        controller: _descriptionController,
                        hint:
                            'I need help moving several boxes from my apartment to a nearby storage unit.',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // Date & Time (with pickers)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Date & Time *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Date picker (tap to open calendar)
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Date',
                            controller: _dateController,
                            hint: '27/7/2025',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time pickers (From / To)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickTime(_fromTimeController),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'From',
                                  controller: _fromTimeController,
                                  hint: '4:00 PM',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickTime(_toTimeController),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'To',
                                  controller: _toTimeController,
                                  hint: '6:00 PM',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _buildTextField(
                        label: 'Flexible timing (optional)',
                        controller: _flexibleNotesController,
                        hint:
                            'e.g. Weeknights after 7pm, can discuss timing',
                        maxLines: 2,
                      ),

                      const SizedBox(height: 12),

                      // Category dropdown
                      _buildDropdown<String>(
                        label: 'Category *',
                        value: _selectedCategory,
                        items: _categories,
                        hint: 'Select a category',
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                        },
                      ),

                      const SizedBox(height: 12),

                      // Location state + details
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Location *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildDropdown<String>(
                        label: 'State',
                        value: _selectedState,
                        items: _states,
                        hint: 'Select state',
                        onChanged: (val) {
                          setState(() => _selectedState = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        label: 'Location details (optional)',
                        controller: _locationDetailsController,
                        hint: 'e.g. Sunway City, hostel block B',
                      ),

                      const SizedBox(height: 12),

                      // Time credits required dropdown
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Time Credits Required *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<double>(
                        value: _selectedCredits,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black12),
                          ),
                        ),
                        hint: const Text('Select time credits required'),
                        items: _creditOptions
                            .map(
                              (opt) => DropdownMenuItem<double>(
                                value: opt['value'] as double,
                                child: Text(opt['label'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedCredits = val);
                        },
                      ),

                      const SizedBox(height: 80), // space above button
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: const Color(0xFFFFF4D1),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Request',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------- HELPERS ---------------

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
          hint: Text(hint),
          items: items
              .map(
                (it) => DropdownMenuItem<T>(
                  value: it,
                  child: Text(it.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
