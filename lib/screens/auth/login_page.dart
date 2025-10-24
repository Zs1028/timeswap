import 'package:flutter/material.dart';
import '../welcome/widgets/clock_logo.dart'; // path from /auth to /welcome/widgets
import '../../routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _hide = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text(''), // keep minimal, mock has no title in bar
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),
            Text('Hi, Welcome Back!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Hello again, you have been missed!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.6))),
            const SizedBox(height: 18),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Email'),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _input('Enter your email'),
                    validator: (v){
                      if (v==null || v.trim().isEmpty) return 'Enter email';
                      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                      return ok ? null : 'Invalid email';
                    },
                  ),
                  const SizedBox(height: 12),

                  _label('Password'),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    decoration: _input('Enter your password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_hide? Icons.visibility_off: Icons.visibility),
                        onPressed: ()=>setState(()=>_hide=!_hide),
                      ),
                    ),
                    validator: (v)=> (v==null || v.length<6) ? 'Min 6 chars' : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: ()=>debugPrint('Forgot Password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (){
                        if (_formKey.currentState?.validate() ?? false) {
                          // For now: just show a message. Later: Firebase login.
                         // ScaffoldMessenger.of(context).showSnackBar(
                            //const SnackBar(content: Text('Login (UI only)')));//
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
                      child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: TextStyle(color: Colors.black.withOpacity(0.46))),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.signup), // later: pushNamed('/signup')
                        child: const Text('Sign Up'),
                      ),
                    ],
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

  // Helpers
  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 6),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5)),
  );
}
