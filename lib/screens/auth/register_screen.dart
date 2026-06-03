import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'login_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _otpController = TextEditingController();

  String _generatedOtp = '';
  bool _otpSent = false;
  bool _otpVerified = false;

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendOtp() async {
    _generatedOtp = _generateOtp();

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': 'service_mr4sur2',
        'template_id': 'template_oqnrrft',
        'user_id': 'AIHNwXuZKFx_qXrXF',
        'template_params': {
          'email': _emailController.text.trim(),
          'passcode': _generatedOtp,
          'time': '15 minutes',
        }
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _otpSent = true;
      });

      _showSnackbar('OTP sent successfully');
    } else {
      print(response.body);

      _showSnackbar(
        'Failed: ${response.statusCode}',
      );
    }
  }

  void _verifyOtp() {
    if (_otpController.text.trim() == _generatedOtp) {
      setState(() {
        _otpVerified = true;
      });

      _showSnackbar('OTP verified successfully');
    } else {
      _showSnackbar('Invalid OTP');
    }
  }

  Future<void> _register() async {

    if (!_otpVerified) {
      _showSnackbar('Verify OTP first');
      return;
    }

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackbar('Please fill in all fields');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      await FirebaseDatabase.instance.ref('users/$uid').set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'waiver': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _showSnackbar('Account created successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? 'Registration failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3C6E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_add, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Create account',
                      style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('Join Campus Hub today',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Full name', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Your full name',
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Email', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'you@university.edu',
                      prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      child: const Text('Send OTP'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  if (_otpSent) ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter OTP',
                        prefixIcon: const Icon(Icons.security),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        child: const Text('Verify OTP'),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                  Text('Phone number', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '01XXXXXXXXX',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Role', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2196F3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        items: ['Student', 'Faculty'].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                const Icon(Icons.badge_outlined, color: Color(0xFF2196F3), size: 20),
                                const SizedBox(width: 10),
                                Text(role, style: GoogleFonts.poppins(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedRole = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Password', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3C6E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Create account',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: Text('Sign in',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}