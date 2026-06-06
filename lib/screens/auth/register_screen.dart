import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
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
  DateTime? _otpGeneratedTime;

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendOtp() async {
    _generatedOtp = _generateOtp();
    _otpGeneratedTime = DateTime.now();

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
      _showSnackbar('OTP sent successfully');
    } else {
      print(response.body);
      _showSnackbar('Failed to send OTP: ${response.statusCode}');
    }
  }


  bool _validateInputs() {
    String fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      _showSnackbar('Please enter your full name');
      return false;
    }
    if (fullName.length < 3) {
      _showSnackbar('Full name must be at least 3 characters');
      return false;
    }
    if (fullName.length > 50) {
      _showSnackbar('Full name must not exceed 50 characters');
      return false;
    }

    String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Please enter your email');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackbar('Please enter a valid email address');
      return false;
    }

    String password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showSnackbar('Please enter your password');
      return false;
    }
    if (password.length < 6) {
      _showSnackbar('Password must be at least 6 characters');
      return false;
    }

    String phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      if (phone.length < 11 || phone.length > 14) {
        _showSnackbar('Please enter a valid phone number (11-14 digits)');
        return false;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        _showSnackbar('Phone number should contain only digits');
        return false;
      }
    }

    return true;
  }


  Future<bool> _checkDuplicate() async {
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();

    try {

      final signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        _showSnackbar('This email is already registered. Please login instead.');
        return false;
      }

      if (phone.isNotEmpty) {
        final phoneSnapshot = await FirebaseDatabase.instance
            .ref('users')
            .orderByChild('phone')
            .equalTo(phone)
            .once();

        if (phoneSnapshot.snapshot.value != null) {
          _showSnackbar('This phone number is already registered');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Duplicate check failed: $e');
      return true;
    }
  }

  Future<void> _register() async {

    if (!_validateInputs()) {
      return;
    }


    setState(() => _isLoading = true);

    bool isDuplicateFree = await _checkDuplicate();

    if (!isDuplicateFree) {
      setState(() => _isLoading = false);
      return;
    }

    await _sendOtp();

    setState(() => _isLoading = false);

    if (!mounted) return;


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Email Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OTP sent to ${_emailController.text.trim()}'),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  helperText: 'Valid for 15 minutes',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _otpController.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // OTP verify
                if (_otpController.text.trim() != _generatedOtp) {
                  _showSnackbar('Invalid OTP');
                  return;
                }

                // OTP timeout check
                if (_otpGeneratedTime != null) {
                  final difference = DateTime.now().difference(_otpGeneratedTime!);
                  if (difference.inMinutes > 15) {
                    _showSnackbar('OTP has expired. Please try again.');
                    Navigator.pop(dialogContext);
                    return;
                  }
                }


                Navigator.pop(dialogContext);


                setState(() => _isLoading = true);

                try {

                  final credential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );

                  final uid = credential.user!.uid;

                  await FirebaseDatabase.instance
                      .ref('users/$uid')
                      .set({
                    'name': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                    'phone': _phoneController.text.trim(),
                    'role': _selectedRole,
                    'waiver': 0,
                    'createdAt': DateTime.now().toIso8601String(),
                  });

                  // Success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully. Please sign in.'),
                      ),
                    );
                  }


                  await Future.delayed(const Duration(milliseconds: 500));

                  await FirebaseAuth.instance.signOut();


                  if (mounted) {

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  }

                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    _showSnackbar(e.message ?? 'Registration failed');
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
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
    _passwordController.dispose();
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
                  Text(
                    'Campus Hub',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart University Management System',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text('Student'),
                        value: 'Student',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<String>(
                        title: const Text('Faculty'),
                        value: 'Faculty',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
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
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© 2026 Campus Hub',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF616161),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Developed using Flutter & Firebase',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
}