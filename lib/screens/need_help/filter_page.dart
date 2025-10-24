import 'package:flutter/material.dart';

/// --------------------
/// Model to carry filters
/// --------------------
class NeedHelpFilters {
  final String? category; // e.g. "Transportation"
  final String? location; // e.g. "Setapak"
  final String? status;   // "Open" | "Pending"

  const NeedHelpFilters({this.category, this.location, this.status});

  NeedHelpFilters copyWith({String? category, String? location, String? status}) {
    return NeedHelpFilters(
      category: category ?? this.category,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }

  static const empty = NeedHelpFilters();
  bool get isEmpty => category == null && location == null && status == null;
}

/// --------------------------------------------
/// The filter screen (dim backdrop + centered card)
/// --------------------------------------------
class NeedHelpFiltersPage extends StatefulWidget {
  final NeedHelpFilters initial;

  const NeedHelpFiltersPage({super.key, this.initial = NeedHelpFilters.empty});

  @override
  State<NeedHelpFiltersPage> createState() => _NeedHelpFiltersPageState();
}

class _NeedHelpFiltersPageState extends State<NeedHelpFiltersPage> {
  /// You’ll probably replace these with data from Firestore / your repo later.
  static const _categories = <String>[
    'Transportation',
    'Home Services',
    'Education',
    'Elderly Support',
    'Other',
  ];
  static const _locations = <String>[
    'Setapak',
    'Wangsa Maju',
    'Selayang',
    'Kepong',
    'Gombak',
  ];
  static const _statuses = <String>['Open', 'Pending'];

  String? _category;
  String? _location;
  String? _status;

  @override
  void initState() {
    super.initState();
    _category = widget.initial.category;
    _location = widget.initial.location;
    _status   = widget.initial.status;
  }

  @override
  Widget build(BuildContext context) {
    // Use Material with a semi-transparent color to create the dim background
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        color: Colors.black54, // dim the background
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with title + close button
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter by',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context), // cancel
                      )
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row: Category + Location
                  Row(
                    children: [
                      Expanded(child: _dropdownField(
                        label: 'Category',
                        value: _category,
                        items: _categories,
                        onChanged: (v) => setState(() => _category = v),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _dropdownField(
                        label: 'Location',
                        value: _location,
                        items: _locations,
                        onChanged: (v) => setState(() => _location = v),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status (single in the middle like your Figma)
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: _dropdownField(
                        label: 'Status',
                        value: _status,
                        items: _statuses,
                        onChanged: (v) => setState(() => _status = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buttons: Reset | Apply
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _category = null;
                            _location = null;
                            _status = null;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 180,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB84D), // warm orange
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () {
                            Navigator.pop(
                              context,
                              NeedHelpFilters(category: _category, location: _location, status: _status),
                            );
                          },
                          child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFFFF9EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
    );
  }
}
