import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];
  int _totalPaid = 0;
  int _paidCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseDatabase.instance
        .ref('payments')
        .orderByChild('studentId')
        .equalTo(uid)
        .get();

    if (!snap.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> payments = [];
    int totalPaid = 0;
    int paidCount = 0;

    data.forEach((key, value) {
      final payment = Map<String, dynamic>.from(value as Map);
      payment['id'] = key;
      payments.add(payment);
      if (payment['status'] == 'Paid') {
        totalPaid += (payment['netFee'] ?? 0) as int;
        paidCount++;
      }
    });

    payments.sort((a, b) =>
        (b['paidAt'] ?? '').compareTo(a['paidAt'] ?? ''));

    setState(() {
      _payments = payments;
      _totalPaid = totalPaid;
      _paidCount = paidCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
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
                    Text('Payment History',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border:
                    Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total paid',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Text('৳ $_totalPaid',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Semesters',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Text('$_paidCount paid',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4CAF50))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No payment records',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Payment records',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121))),
                  );
                }

                final data = _payments[index - 1];
                final isPaid = data['status'] == 'Paid';
                final paidAt = data['paidAt'] != null
                    ? DateTime.tryParse(data['paidAt'])
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPaid
                          ? const Color(0xFFE0E4EF)
                          : const Color(0xFFF0C1C1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['semester'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121)),
                              ),
                              Text(
                                paidAt != null
                                    ? 'Paid on ${paidAt.day}/${paidAt.month}/${paidAt.year}'
                                    : 'Pending',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: isPaid
                                        ? Colors.grey
                                        : const Color(0xFFA32D2D)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFFE1F5EE)
                                  : const Color(0xFFFCEBEB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPaid ? '✓ Paid' : 'Unpaid',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isPaid
                                      ? const Color(0xFF085041)
                                      : const Color(0xFFA32D2D),
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '৳ ${data['netFee'] ?? 0}',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isPaid
                                    ? const Color(0xFF1A3C6E)
                                    : const Color(0xFFA32D2D)),
                          ),
                          if (isPaid)
                            Row(
                              children: [
                                _downloadBtn(
                                    Icons.download_outlined,
                                    'Receipt',
                                    const Color(0xFFE6F1FB),
                                    const Color(0xFF185FA5)),
                                const SizedBox(width: 6),
                                _downloadBtn(
                                    Icons.description_outlined,
                                    'Transcript',
                                    const Color(0xFFEEEDFE),
                                    const Color(0xFF534AB7)),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3C6E),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text('Pay now',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloading all documents...')),
                  );
                },
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                label: Text('Download all documents',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadBtn(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}