import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_history_screen.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class FeePaymentScreen extends StatefulWidget {
  const FeePaymentScreen({super.key});

  @override
  State<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<FeePaymentScreen> {
  final _waiverController = TextEditingController();
  final int _perCreditRate = 1500;
  double _totalCredits = 0;
  double _waiver = 0;
  bool _isLoading = true;
  String _userName = '';
  String _userInitials = 'U';
  double _profileWaiver = 0;
  String _generatedOtp = '';
  bool _otpSent = false;

  final TextEditingController _otpController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  String _generateOtp() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> _sendOtp() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not found')),
      );
      return;
    }

    _generatedOtp = _generateOtp();

    try {
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
            'email': user.email,
            'passcode': _generatedOtp,
            'time': '15 minutes',
          }
        }),
      );

      if (response.statusCode == 200) {
        _otpSent = true;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to email')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (userSnap.exists) {
      final data = Map<String, dynamic>.from(userSnap.value as Map);
      final name = data['name'] ?? '';
      final waiver = (data['waiver'] ?? 0) as num;
      setState(() {
        _userName = name;
        _userInitials = name.isNotEmpty
            ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
            : 'U';
        _profileWaiver = waiver.toDouble();
        _waiver = waiver.toDouble();

      });
    }

    final enrollSnap = await FirebaseDatabase.instance
        .ref('enrollments')
        .orderByChild('studentId')
        .equalTo(uid)
        .get();

    double credits = 0;
    if (enrollSnap.exists) {
      final enrollments = Map<String, dynamic>.from(enrollSnap.value as Map);
      for (var entry in enrollments.values) {
        final enrollment = Map<String, dynamic>.from(entry as Map);
        final courseId = enrollment['courseId'];
        final courseSnap =
        await FirebaseDatabase.instance.ref('courses/$courseId').get();
        if (courseSnap.exists) {
          final course = Map<String, dynamic>.from(courseSnap.value as Map);
          credits += ((course['credit'] ?? 0) as num).toDouble();
        }
      }
    }

    setState(() {
      _totalCredits = credits;
      _isLoading = false;
    });
  }

  int get _grossFee =>
      (_totalCredits * _perCreditRate).round();
  int get _waiverAmount => (_grossFee * _waiver / 100).round();
  int get _netFee => _grossFee - _waiverAmount;

  Future<void> _showPaymentDialog() async {
    String selectedMethod = 'bKash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Demo Payment Gateway'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  DropdownButton<String>(
                    value: selectedMethod,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'bKash',
                        child: Text('bKash'),
                      ),
                      DropdownMenuItem(
                        value: 'Nagad',
                        child: Text('Nagad'),
                      ),
                      DropdownMenuItem(
                        value: 'Rocket',
                        child: Text('Rocket'),
                      ),
                      DropdownMenuItem(
                        value: 'Visa',
                        child: Text('Visa Card'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Amount: ৳ $_netFee',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {

                    Navigator.pop(context);

                    await _showOtpDialog(selectedMethod);

                  },
                  child: const Text('Pay Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _showOtpDialog(String paymentMethod) async {

    await _sendOtp();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email Verification'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'OTP sent to your email',
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {

                if (_otpController.text.trim() !=
                    _generatedOtp) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid OTP'),
                    ),
                  );

                  return;
                }

                Navigator.pop(context);

                await _pay(paymentMethod);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _pay(String paymentMethod) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final txnId =
        "TXN${DateTime.now().millisecondsSinceEpoch}";

    await FirebaseDatabase.instance.ref('payments').push().set({
      'studentId': uid,
      'studentName': _userName,
      'transactionId': txnId,
      'paymentMethod': paymentMethod,
      'semester': 'Spring 2026',
      'grossFee': _grossFee,
      'waiver': _waiver,
      'waiverAmount': _waiverAmount,
      'netFee': _netFee,
      'status': 'Paid',
      'paidAt': DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Successful\nTransaction ID: $txnId',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _waiverController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 52, 18, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3C6E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Fee Calculator',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentHistoryScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('History',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF2196F3),
                          child: Text(_userInitials,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              Text('Spring 2026 • CSE',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white60)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Waiver',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.white60)),
                            Text('${_profileWaiver.toInt()}%',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4CAF50))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E4EF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enrollment info',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121))),
                        const SizedBox(height: 10),
                        _infoRow(
                          'Enrolled credits',
                          '${_totalCredits.toStringAsFixed(1)} credits',
                        ),
                        const Divider(height: 16),
                        _infoRow('Per credit rate', '৳ $_perCreditRate'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E4EF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Waiver adjustment',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121))),
                        const SizedBox(height: 4),
                        Text(
                          'Profile waiver: ${_profileWaiver.toInt()}%',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Waiver: ${_profileWaiver.toInt()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F6E56),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E4EF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fee calculation',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121))),
                        const SizedBox(height: 10),
                        _infoRow('Gross fee', '৳ $_grossFee'),
                        const Divider(height: 16),
                        _infoRow(
                            'Waiver (${_waiver.toInt()}%)',
                            '- ৳ $_waiverAmount',
                            valueColor: const Color(0xFF0F6E56)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Net payable',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121))),
                            Text('৳ $_netFee',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A3C6E))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _showPaymentDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Pay via SSLCommerz',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          Text(
                              'bKash • Nagad • Rocket • Visa • Mastercard',
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Secured by SSLCommerz',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey)),
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

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF212121))),
      ],
    );
  }
}