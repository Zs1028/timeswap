import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/service_model.dart';

class EditServicePage extends StatefulWidget {
  final Service service;
  final bool isOfferedTab; // true = offered, false = requested

  const EditServicePage({
    super.key,
    required this.service,
    required this.isOfferedTab,
  });

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ✅ NEW: date range
  final _availableFromController = TextEditingController();
  final _availableUntilController = TextEditingController();

  // time range
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

  @override
  void initState() {
    super.initState();

    final s = widget.service;

    _titleController.text = s.serviceTitle;
    _descriptionController.text = s.serviceDescription;
    _flexibleNotesController.text = s.flexibleNotes ?? '';

    // ✅ Parse state + location details from `location`
    String parsedState = '';
    String parsedLocationDetails = '';

    if (s.location.contains(' - ')) {
      final parts = s.location.split(' - ');
      parsedState = parts[0].trim();
      parsedLocationDetails = parts.length > 1 ? parts[1].trim() : '';
    } else {
      parsedState = s.location.trim();
    }

    _selectedState = _states.contains(parsedState) ? parsedState : null;
    _locationDetailsController.text = parsedLocationDetails;

    _selectedCategory = _categories.contains(s.category) ? s.category : null;

    _selectedCreditsRequired =
        (s.creditsPerHour is num) ? (s.creditsPerHour as num).toDouble() : null;

    // ✅ Backward compatible: parse time + date from availableTiming
    // Old format: "27/7/2025, 4:00 PM - 6:00 PM"
    String datePart = '';
    String from = '';
    String to = '';

    if (s.availableTiming.isNotEmpty) {
      final parts = s.availableTiming.split(',');
      if (parts.isNotEmpty) datePart = parts[0].trim();

      if (parts.length > 1) {
        final timeRange = parts[1].split('-');
        if (timeRange.isNotEmpty) from = timeRange[0].trim();
        if (timeRange.length > 1) to = timeRange[1].trim();
      }
    }

    // ✅ If you already store availableFrom/availableUntil in Firestore,
    // put them into your Service model and read them here.
    // If not available, fallback to old datePart and set both same day.
    _availableFromController.text = datePart;
    _availableUntilController.text = datePart;

    _fromTimeController.text = from;
    _toTimeController.text = to;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _availableFromController.dispose();
    _availableUntilController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    _locationDetailsController.dispose();
    _flexibleNotesController.dispose();
    super.dispose();
  }

  // ---------- date helpers ----------
  DateTime? _parseDdMmYyyy(String s) {
    // expects dd/mm/yyyy
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  String _formatDdMmYyyy(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _pickDateInto(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDdMmYyyy(controller.text) ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = _formatDdMmYyyy(picked);
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

  String _buildDateDisplay(String fromDate, String untilDate) {
    if (fromDate.isEmpty && untilDate.isEmpty) return '';
    if (fromDate.isNotEmpty && untilDate.isNotEmpty) {
      return (fromDate == untilDate) ? fromDate : '$fromDate - $untilDate';
    }
    // should not happen if validated properly
    return fromDate.isNotEmpty ? fromDate : untilDate;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();

    final fromDate = _availableFromController.text.trim();
    final untilDate = _availableUntilController.text.trim();

    final fromTime = _fromTimeController.text.trim();
    final toTime = _toTimeController.text.trim();

    final category = _selectedCategory ?? '';
    final state = _selectedState ?? '';
    final locationDetails = _locationDetailsController.text.trim();
    final flexibleNotes = _flexibleNotesController.text.trim();
    final creditsRequired = _selectedCreditsRequired;

    if (description.isEmpty ||
        fromDate.isEmpty ||
        untilDate.isEmpty ||
        fromTime.isEmpty ||
        toTime.isEmpty ||
        category.isEmpty ||
        state.isEmpty ||
        creditsRequired == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    // ✅ date validation (until >= from)
    final fromDt = _parseDdMmYyyy(fromDate);
    final untilDt = _parseDdMmYyyy(untilDate);

    if (fromDt == null || untilDt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid dates.')),
      );
      return;
    }

    if (untilDt.isBefore(fromDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '"Available Until" must be the same or after "Available From".'),
        ),
      );
      return;
    }

    final location = [
      state,
      if (locationDetails.isNotEmpty) locationDetails,
    ].join(' - ');

    // keep your existing availableTiming string for UI
    final dateDisplay = _buildDateDisplay(fromDate, untilDate);
    final availableTiming = '$dateDisplay, $fromTime - $toTime';

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.service.id)
          .update({
        'serviceDescription': description,
        'location': location,
        'state': state,
        'locationDetails': locationDetails,
        'availableTiming': availableTiming,

        // ✅ NEW fields (so future pages can read them)
        'availableFrom': fromDate,
        'availableUntil': untilDate,

        'flexibleNotes': flexibleNotes,
        'updatedDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service updated successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update service: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle =
        widget.isOfferedTab ? 'Edit Service Offered' : 'Edit Service Requested';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Title (cannot be edited) *',
                        controller: _titleController,
                        hint: 'Gardening',
                        validator: null,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Description *',
                        controller: _descriptionController,
                        hint:
                            'I can help with basic gardening, watering plants, and trimming.',
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a description'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ✅ Available Date Range + Time
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

                      // ✅ Date range
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDateInto(_availableFromController),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'Available From',
                                  controller: _availableFromController,
                                  hint: '12/12/2025',
                                  validator: (v) {
                                    final until = _availableUntilController.text.trim();
                                    final from = (v ?? '').trim();
                                    if (from.isEmpty && until.isNotEmpty) {
                                      return 'Please select Available From';
                                    }
                                    if (from.isEmpty) return 'Please select a date';
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDateInto(_availableUntilController),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'Available Until',
                                  controller: _availableUntilController,
                                  hint: '12/12/2025',
                                  validator: (v) {
                                    final from = _availableFromController.text.trim();
                                    final until = (v ?? '').trim();
                                    if (until.isEmpty && from.isNotEmpty) {
                                      return 'Please select Available Until';
                                    }
                                    if (until.isEmpty) return 'Please select a date';
                                    return null;
                                  },
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
                                  label: 'From (time)',
                                  controller: _fromTimeController,
                                  hint: '4:00 PM',
                                  validator: (v) => (v == null || v.trim().isEmpty)
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
                                  label: 'To (time)',
                                  controller: _toTimeController,
                                  hint: '6:00 PM',
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Select an end time'
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      _buildTextField(
                        label: 'Flexible timing notes (optional)',
                        controller: _flexibleNotesController,
                        hint: 'e.g. Weekdays after 7 PM, weekends flexible',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      _buildDropdown<String>(
                        label: 'Category (cannot be edited) *',
                        value: _selectedCategory,
                        items: _categories,
                        hint: 'Select category',
                        onChanged: (v) {},
                        enabled: false,
                      ),
                      const SizedBox(height: 12),

                      _buildDropdown<String>(
                        label: 'Location (state / area) *',
                        value: _selectedState,
                        items: _states,
                        hint: 'Select state or area',
                        validator: (v) => v == null ? 'Please select a state' : null,
                        onChanged: (v) => setState(() => _selectedState = v),
                      ),
                      const SizedBox(height: 8),

                      _buildTextField(
                        label: 'Location details (optional)',
                        controller: _locationDetailsController,
                        hint: 'e.g. Setapak, condo name, street',
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Time Credits Required (cannot be edited)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          '${_selectedCreditsRequired?.toString() ?? ''} credits',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom buttons: Cancel (red) + Save (green)
            Container(
              color: const Color(0xFFFFF4D1),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
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
          ],
        ),
      ),
    );
  }

  // Shared text field builder
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
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
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  // Shared dropdown builder
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String hint,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    bool enabled = true,
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
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString()),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
        ),
      ],
    );
  }
}
