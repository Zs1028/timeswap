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
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
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
    'W.P. Kuala Lumpur',
  ];

  // credits options
  final List<double> _creditOptions = const [
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    3.5,
    4.0,
    4.5,
    5.0,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    _locationDetailsController.dispose();
    _flexibleNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );

  if (picked != null) {
    controller.text =
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

  // 2️⃣ Validate basic fields (title/description/category/state/credits validators)
  if (!_formKey.currentState!.validate()) return;

  final String currentUserId = user.uid;

  // Fetch display name from `users` collection (fallback to auth data)
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .get();

  final String providerName =
      (userDoc.data()?['name'] as String?) ??
      user.displayName ??
      user.email ??
      'TimeSwap User';

  final title = _titleController.text.trim();
  final description = _descriptionController.text.trim();

  // Optional availability window
  final startDate = _startDateController.text.trim();
  final endDate = _endDateController.text.trim();
  final from = _fromTimeController.text.trim();
  final to = _toTimeController.text.trim();
  final flexibleNotes = _flexibleNotesController.text.trim();

  final category = _selectedCategory ?? '';
  final state = _selectedState ?? '';
  final locationDetails = _locationDetailsController.text.trim();
  final creditsRequired = _selectedCreditsRequired;

  // ✅ Required fields only (availability is optional)
  if (title.isEmpty ||
      description.isEmpty ||
      category.isEmpty ||
      state.isEmpty ||
      creditsRequired == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all required fields.')),
    );
    return;
  }

  // ✅ Optional: enforce pairs (avoid half-filled ranges)
  if ((startDate.isNotEmpty && endDate.isEmpty) ||
      (startDate.isEmpty && endDate.isNotEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select both "Available From" and "Available Until" (or leave both field empty).')),
    );
    return;
  }

  if ((from.isNotEmpty && to.isEmpty) || (from.isEmpty && to.isNotEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select both From and To time (or leave both empty).')),
    );
    return;
  }

  // Build location string (state + optional details)
  final location = [
    state,
    if (locationDetails.isNotEmpty) locationDetails,
  ].join(' - ');

  // ✅ Build availableTiming (optional, user-friendly)
  String availableTiming = '';

  if (startDate.isNotEmpty && endDate.isNotEmpty) {
  if (startDate == endDate) {
    // ✅ One-day availability
    availableTiming = startDate;
  } else {
    // ✅ Multi-day range
    availableTiming = '$startDate – $endDate';
  }
}

  if (from.isNotEmpty && to.isNotEmpty) {
    final timePart = '$from – $to';
    availableTiming = availableTiming.isEmpty ? timePart : '$availableTiming, $timePart';
  }

  if (flexibleNotes.isNotEmpty) {
    availableTiming = availableTiming.isEmpty
        ? flexibleNotes
        : '$availableTiming • $flexibleNotes';
  }

  setState(() => _isSubmitting = true);

  try {
    await FirebaseFirestore.instance.collection('services').add({
      'serviceTitle': title,
      'serviceDescription': description,
      'category': category,
      'location': location,
      'state': state,
      'locationDetails': locationDetails,

      // Availability (can be empty string if user left it blank)
      'availableTiming': availableTiming,
      'flexibleNotes': flexibleNotes,

      // keep same field name so existing UI still works
      'creditsPerHour': creditsRequired,

      'serviceStatus': 'open',

      // ⭐ OFFER HELP LOGIC
      'providerId': currentUserId,
      'providerName': providerName,

      // requester stays same logic as before (your current design)
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
                        hint: 'Gardening',
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
                          'Availability Window (Optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Availability is flexible and can be discussed after matching.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54, // grey
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      // Date picker
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(_startDateController),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'Available From',
                                  controller: _startDateController,
                                  hint: 'e.g. 27/7/2025',
                                  // ❌ no validator → optional
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(_endDateController),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'Available Until',
                                  controller: _endDateController,
                                  hint: 'e.g. 30/7/2025',
                                ),
                              ),
                            ),
                          ),
                        ],
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
                        label: 'Location (state) *',
                        value: _selectedState,
                        items: _states,
                        hint: 'Select state',
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
                          'Time credits represent the effort required for this service.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54, // grey
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
                        final bool isWhole = c % 1 == 0;

                        final String label = isWhole
                            ? '${c.toInt()} credits'
                            : '$c credits';

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
             hintStyle: TextStyle(
              color: Colors.grey.shade400, // 👈 lighter placeholder
              fontSize: 14,),
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
