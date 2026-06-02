import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  List<Map<String, dynamic>> _courseAttendance = [];

  @override
  void initState() {
    super.initState();

    FirebaseDatabase.instance
        .ref('attendance')
        .onValue
        .listen((event) {
      _loadAttendance();
    });

    _loadAttendance();
  }
  Future<void> _loadAttendance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Load enrollments
    final enrollSnap = await FirebaseDatabase.instance
        .ref('enrollments')
        .orderByChild('studentId')
        .equalTo(uid)
        .get();

    if (!enrollSnap.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final enrollments = Map<String, dynamic>.from(enrollSnap.value as Map);
    List<Map<String, dynamic>> courseAttendance = [];
    int totalPresent = 0;
    int totalAbsent = 0;

    for (var entry in enrollments.values) {
      final enrollment = Map<String, dynamic>.from(entry as Map);
      final courseId = enrollment['courseId'];

      // Load course info
      final courseSnap = await FirebaseDatabase.instance
          .ref('courses/$courseId')
          .get();
      if (!courseSnap.exists) continue;
      final course = Map<String, dynamic>.from(courseSnap.value as Map);

      // Load attendance
      final attSnap = await FirebaseDatabase.instance
          .ref('attendance/$courseId')
          .get();

      int present = 0;
      int absent = 0;

      if (attSnap.exists) {
        final dates =
        Map<String, dynamic>.from(attSnap.value as Map);

        dates.forEach((date, students) {
          final studentMap =
          Map<String, dynamic>.from(students as Map);

          if (studentMap.containsKey(uid)) {
            final att =
            Map<String, dynamic>.from(studentMap[uid] as Map);

            if (att['status'] == 'Present') {
              present++;
            } else {
              absent++;
            }
          }
        });
      }

      totalPresent += present;
      totalAbsent += absent;

      courseAttendance.add({
        'courseName': course['courseName'] ?? '',
        'courseCode': course['courseCode'] ?? '',
        'present': present,
        'absent': absent,
      });
    }

    setState(() {
      _totalPresent = totalPresent;
      _totalAbsent = totalAbsent;
      _courseAttendance = courseAttendance;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPresent + _totalAbsent;
    final avgPct = total > 0 ? (_totalPresent / total * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
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
                Text('Attendance',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      _summaryItem('$avgPct%', 'Average', const Color(0xFF4CAF50)),
                      _divider(),
                      _summaryItem('$_totalPresent', 'Present', Colors.white),
                      _divider(),
                      _summaryItem('$_totalAbsent', 'Absent', const Color(0xFFF09595)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _courseAttendance.isEmpty
                ? Center(
              child: Text('No attendance records',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey)),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courseAttendance.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Course wise',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121))),
                  );
                }

                final data = _courseAttendance[index - 1];
                final present = data['present'] as int;
                final absent = data['absent'] as int;
                final total = present + absent;
                final pct = total > 0 ? present / total : 0.0;
                final pctInt = (pct * 100).toInt();

                Color progressColor;
                if (pctInt >= 80) {
                  progressColor = const Color(0xFF4CAF50);
                } else if (pctInt >= 70) {
                  progressColor = const Color(0xFFEF9F27);
                } else {
                  progressColor = const Color(0xFFE24B4A);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E4EF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['courseName'],
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF212121)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  data['courseCode'],
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$pctInt%',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: progressColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: const Color(0xFFF5F7FA),
                          color: progressColor,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Present: $present',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: Colors.grey)),
                          Text('Absent: $absent',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: pctInt < 75
                                      ? const Color(0xFFA32D2D)
                                      : Colors.grey)),
                        ],
                      ),
                      if (pctInt < 60) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  size: 14, color: Color(0xFFA32D2D)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Attendance below 60%! Please attend more classes.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFF791F1F)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: valueColor)),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 0.5, height: 36, color: Colors.white24);
  }
}