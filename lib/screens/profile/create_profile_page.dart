import 'package:flutter/material.dart';
import '../welcome/widgets/clock_logo.dart';
import '../../routes.dart';


class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});
  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _about = TextEditingController();
  final _skills = TextEditingController();
  String? _location; // dropdown
  // image picker comes later (backend)

  @override
  void dispose() {
    _about.dispose();
    _skills.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Create Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 4),
            Text('Let other people know more about you!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withOpacity(0.6))),
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
                    validator: (v)=> (v==null || v.trim().isEmpty) ? 'Please write a bio' : null,
                  ),

                  _label('Where do you stayed?'),
                  _LocationDropdown(
                    value: _location,
                    onChanged: (v)=>setState(()=>_location=v),
                  ),

                  _label('What kind of skill you can offer?'),
                  TextFormField(
                    controller: _skills,
                    decoration: _input('e.g., Math tutoring, Cooking'),
                    validator: (v)=> (v==null || v.trim().isEmpty) ? 'Enter at least one skill' : null,
                  ),

                  _label('Add your profile picture (optional)'),
                  TextFormField(
                    readOnly: true,
                    decoration: _input('Tap to choose image').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.upload),
                        onPressed: (){
                          // later: open image picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image picker coming soon')));
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (){
                        if (_formKey.currentState?.validate() ?? false) {
                          //ScaffoldMessenger.of(context).showSnackBar(
                            //const SnackBar(content: Text('Profile created (UI only)')));//
                            Navigator.pushReplacementNamed(context, AppRoutes.home);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39C50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('Create Profile',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 12),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Colors.black12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5)),
  );
}

// location dropdown widget
class _LocationDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _LocationDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = <String>[
      'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan',
      'Pahang', 'Perak', 'Perlis', 'Penang', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu', 'Kuala Lumpur'
    ];
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5)),
      ),
      hint: const Text('Select your location'),
    );
  }
}
