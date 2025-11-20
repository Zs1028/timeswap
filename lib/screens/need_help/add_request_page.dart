import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRequestPage extends StatefulWidget {
  const AddRequestPage({super.key});

  @override
  State<AddRequestPage> createState() => _AddRequestPageState();
}

class _AddRequestPageState extends State<AddRequestPage> {
  // TEMP user info – later replace with FirebaseAuth + users collection
  static const String currentUserId = 'demoUser123';
  static const String currentUserName = 'Me'; // shown on cards later if you want

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();       // e.g. 27/7/2025
  final _fromTimeController = TextEditingController();   // e.g. 4:00 PM
  final _toTimeController = TextEditingController();     // e.g. 6:00 PM
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeLimitController = TextEditingController();  // days
  final _creditsController = TextEditingController();    // credits per hour

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _timeLimitController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();
    final from = _fromTimeController.text.trim();
    final to = _toTimeController.text.trim();
    final category = _categoryController.text.trim();
    final location = _locationController.text.trim();
    final timeLimitStr = _timeLimitController.text.trim();
    final creditsStr = _creditsController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        date.isEmpty ||
        from.isEmpty ||
        to.isEmpty ||
        category.isEmpty ||
        location.isEmpty ||
        timeLimitStr.isEmpty ||
        creditsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final timeLimitDays = int.tryParse(timeLimitStr);
    final creditsPerHour = int.tryParse(creditsStr);

    if (timeLimitDays == null || creditsPerHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Time limit and time credits must be valid numbers.'),
        ),
      );
      return;
    }

    final availableTiming = '$date, $from - $to';

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('services').add({
        'serviceTitle': title,
        'serviceDescription': description,
        'category': category,
        'location': location,
        'availableTiming': availableTiming,
        'timeLimitDays': timeLimitDays,
        'creditsPerHour': creditsPerHour,
        'serviceStatus': 'open',        // new requests start as open
        'requesterId': currentUserId,   // the person who needs help
        // helper/provider not chosen yet
        'providerId': '',
        'providerName': '',
        'serviceType' : 'need',
        'createdDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request created successfully.')),
      );
      Navigator.of(context).pop(); // go back to Need Help page
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
                      _buildTextField(
                        label: 'Date',
                        controller: _dateController,
                        hint: '27/7/2025',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'From',
                              controller: _fromTimeController,
                              hint: '4:00 PM',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              label: 'To',
                              controller: _toTimeController,
                              hint: '6:00 PM',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Category *',
                        controller: _categoryController,
                        hint: 'Home Services',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Location *',
                        controller: _locationController,
                        hint: 'Setapak',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Duration of Time Limit (days) *',
                        controller: _timeLimitController,
                        hint: '2',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Time Credits Offered (per hour) *',
                        controller: _creditsController,
                        hint: '4',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 80), // space above button
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: const Color(0xFFFFF4D1),
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
}
