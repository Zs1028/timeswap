import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddOfferingPage extends StatefulWidget {
  const AddOfferingPage({super.key});

  @override
  State<AddOfferingPage> createState() => _AddOfferingPageState();
}

class _AddOfferingPageState extends State<AddOfferingPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _fromTimeController = TextEditingController();
  final _toTimeController = TextEditingController();

  // location details (optional)
  final _locationDetailsController = TextEditingController();

  // flexible timing notes (optional)
  final _flexibleNotesController = TextEditingController();

  // dropdown selections
  String? _selectedCategory;
  String? _selectedState;
  double? _selectedCreditsRequired;

  bool _isSubmitting = false;

  // category options
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

  // 14 Malaysia states + KL
  final List<String> _states = const [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
  ];

  // credits options
  final List<double> _creditOptions = const [
    1.0,
    1.5,
    2.0,
    3.0,
    4.0,
    5.0,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    _locationDetailsController.dispose();
    _flexibleNotesController.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    // 1️⃣ Get logged-in user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    // 2️⃣ Validate basic fields
    if (!_formKey.currentState!.validate()) return;

    final String currentUserId = user.uid;
    final String currentUserName = user.email ?? 'TimeSwap User';

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();
    final from = _fromTimeController.text.trim();
    final to = _toTimeController.text.trim();
    final category = _selectedCategory ?? '';
    final state = _selectedState ?? '';
    final locationDetails = _locationDetailsController.text.trim();
    final flexibleNotes = _flexibleNotesController.text.trim();
    final creditsRequired = _selectedCreditsRequired;

    // extra safety (should already be covered by validators)
    if (title.isEmpty ||
        description.isEmpty ||
        date.isEmpty ||
        from.isEmpty ||
        to.isEmpty ||
        category.isEmpty ||
        state.isEmpty ||
        creditsRequired == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    // build location string (state + optional details) – keeps old `location` usage working
    final location = [
      state,
      if (locationDetails.isNotEmpty) locationDetails,
    ].join(' - ');

    final availableTiming = '$date, $from - $to';

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('services').add({
        'serviceTitle': title,
        'serviceDescription': description,
        'category': category,
        'location': location,
        'state': state,
        'locationDetails': locationDetails,
        'availableTiming': availableTiming,
        'flexibleNotes': flexibleNotes,
        // NOTE: field name kept as creditsPerHour so existing cards continue to work
        'creditsPerHour': creditsRequired,
        'serviceStatus': 'open',

        // ⭐ OFFER HELP LOGIC
        'providerId': currentUserId,
        'providerName': currentUserName,

        // requester stays same logic as before
        'requesterId': currentUserId,
        'serviceType': 'offer',
        'createdDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offering created successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create offering: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
          'Add Offerings Form',
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
                        hint: 'Offer Help with Gardening',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Please enter a title'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Description *',
                        controller: _descriptionController,
                        hint:
                            'I can help with basic gardening, watering plants, and trimming.',
                        maxLines: 3,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Please enter a description'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      // Available Date & Time
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available Date & Time *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Date picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Date',
                            controller: _dateController,
                            hint: '27/7/2025',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please select a date'
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time pickers
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
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Select a start time'
                                          : null,
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
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Select an end time'
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Flexible timing notes (optional)
                      _buildTextField(
                        label: 'Flexible timing notes (optional)',
                        controller: _flexibleNotesController,
                        hint: 'e.g. Weekdays after 7 PM, weekends flexible',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Category dropdown
                      _buildDropdown<String>(
                        label: 'Category *',
                        value: _selectedCategory,
                        items: _categories,
                        hint: 'Select category',
                        validator: (v) =>
                            v == null ? 'Please select a category' : null,
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: 12),

                      // State dropdown
                      _buildDropdown<String>(
                        label: 'Location (state / area) *',
                        value: _selectedState,
                        items: _states,
                        hint: 'Select state or area',
                        validator: (v) =>
                            v == null ? 'Please select a state' : null,
                        onChanged: (v) =>
                            setState(() => _selectedState = v),
                      ),
                      const SizedBox(height: 8),

                      // Optional location details
                      _buildTextField(
                        label: 'Location details (optional)',
                        controller: _locationDetailsController,
                        hint: 'e.g. Setapak, condo name, street',
                      ),
                      const SizedBox(height: 12),

                      // Time credits required
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Standard rate: 1 credit = 1 hour',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      DropdownButtonFormField<double>(
                        value: _selectedCreditsRequired,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                        items: _creditOptions.map((c) {
                          String label;
                          if (c == 1.0) {
                            label = '1 hour (1 credit)';
                          } else if (c == 5.0) {
                            label = '5+ hours (5+ credits)';
                          } else {
                            label = '${c.toString()} hours (${c.toString()} credits)';
                          }
                          return DropdownMenuItem<double>(
                            value: c,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCreditsRequired = v),
                        validator: (v) =>
                            v == null ? 'Please select time credits' : null,
                      ),
                      const SizedBox(height: 80),
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
                          'Create Offering',
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

  // Shared text field builder (keeps your design)
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
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

  // Shared dropdown builder using same label style
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String hint,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
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
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(e.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
