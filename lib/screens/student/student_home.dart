import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'course_list_screen.dart';
import 'assignment_screen.dart';
import 'attendance_screen.dart';
import 'notice_screen.dart';
import 'profile_screen.dart';
import 'fee_payment_screen.dart';
import 'cgpa_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;
  String _userName = '';
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snap.exists && mounted) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      final name = data['name'] ?? '';
      setState(() {
        _userName = name;
        _userInitials = name.isNotEmpty
            ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
            : 'U';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeContent(userName: _userName, userInitials: _userInitials),
      const CourseListScreen(),
      const AssignmentScreen(),
      const AttendanceScreen(),
      const NoticeScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A3C6E),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Notices'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final String userName;
  final String userInitials;

  const _HomeContent({this.userName = '', this.userInitials = 'U'});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  int _courseCount = 0;
  double _cgpa = 0;
  int _attendancePct = 0;
  List<Map<String, dynamic>> _upcomingAssignments = [];
  Map<String, dynamic>? _latestNotice;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Load course count
    final enrollSnap = await FirebaseDatabase.instance
        .ref('enrollments')
        .orderByChild('studentId')
        .equalTo(uid)
        .get();
    if (enrollSnap.exists && mounted) {
      setState(() => _courseCount = (enrollSnap.value as Map).length);
    }

    // Load CGPA
    final gradeSnap = await FirebaseDatabase.instance
        .ref('grades')
        .orderByChild('studentId')
        .equalTo(uid)
        .get();
    if (gradeSnap.exists && mounted) {
      final grades = Map<String, dynamic>.from(gradeSnap.value as Map);
      double totalPoints = 0;
      int totalCredits = 0;
      grades.forEach((key, value) {
        final grade = Map<String, dynamic>.from(value as Map);
        final credit = (grade['credit'] ?? 0) as num;
        final gpa = (grade['gpa'] ?? 0) as num;
        totalPoints += credit.toDouble() * gpa.toDouble();
        totalCredits += credit.toInt();
      });
      if (totalCredits > 0 && mounted) {
        setState(() => _cgpa = totalPoints / totalCredits);
      }
    }

    // Load attendance
    final attSnap =
    await FirebaseDatabase.instance.ref('attendance').get();

    if (attSnap.exists) {
      final attendanceData =
      Map<String, dynamic>.from(attSnap.value as Map);

      int present = 0;
      int total = 0;

      attendanceData.forEach((courseId, dateMap) {
        final dates = Map<String, dynamic>.from(dateMap as Map);

        dates.forEach((date, recordsMap) {
          final records =
          Map<String, dynamic>.from(recordsMap as Map);

          records.forEach((recordId, recordData) {
            final record =
            Map<String, dynamic>.from(recordData as Map);

            if (record['studentId'] == uid) {
              total++;

              if (record['status'] == 'Present') {
                present++;
              }
            }
          });
        });
      });

      if (mounted) {
        setState(() {
          _attendancePct =
          total > 0 ? ((present / total) * 100).round() : 0;
        });
      }
    }

    // Load upcoming assignments
    final assignSnap = await FirebaseDatabase.instance
        .ref('assignments')
        .get();
    if (assignSnap.exists && mounted) {
      final assignments = Map<String, dynamic>.from(assignSnap.value as Map);
      final now = DateTime.now();
      List<Map<String, dynamic>> upcoming = [];
      assignments.forEach((key, value) {
        final a = Map<String, dynamic>.from(value as Map);
        a['id'] = key;
        final deadline = DateTime.tryParse(a['deadline'] ?? '');
        final submittedBy = a['submittedBy'] as Map? ?? {};
        if (deadline != null && deadline.isAfter(now) && !submittedBy.containsKey(uid)) {
          upcoming.add(a);
        }
      });
      upcoming.sort((a, b) => (a['deadline'] ?? '').compareTo(b['deadline'] ?? ''));
      setState(() => _upcomingAssignments = upcoming.take(2).toList());
    }

    // Load latest notice
    final noticeSnap = await FirebaseDatabase.instance
        .ref('notices')
        .get();
    if (noticeSnap.exists && mounted) {
      final notices = Map<String, dynamic>.from(noticeSnap.value as Map);
      Map<String, dynamic>? latest;
      notices.forEach((key, value) {
        final n = Map<String, dynamic>.from(value as Map);
        n['id'] = key;
        if (latest == null ||
            (n['createdAt'] ?? '').compareTo(latest!['createdAt'] ?? '') > 0) {
          latest = n;
        }
      });
      setState(() => _latestNotice = latest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 52, 18, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3C6E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good morning 👋',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white60)),
                        Text(
                            widget.userName.isNotEmpty
                                ? widget.userName
                                : 'Student',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF2196F3),
                      child: Text(widget.userInitials,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      _summaryItem('$_courseCount', 'Courses'),
                      _divider(),
                      _summaryItem(_cgpa.toStringAsFixed(2), 'CGPA'),
                      _divider(),
                      _summaryItem('$_attendancePct%', 'Attendance'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick access',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121))),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      children: [
                        _quickAction(
                          context,
                          Icons.book,
                          'Courses',
                          const Color(0xFFE6F1FB),
                          const Color(0xFF185FA5),
                          1,
                        ),
                        const SizedBox(width: 8),
                        _quickAction(
                          context,
                          Icons.assignment,
                          'Tasks',
                          const Color(0xFFE1F5EE),
                          const Color(0xFF0F6E56),
                          2,
                        ),
                        const SizedBox(width: 8),
                        _quickAction(
                          context,
                          Icons.calendar_today,
                          'Attendance',
                          const Color(0xFFFAEEDA),
                          const Color(0xFFBA7517),
                          3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _quickAction(
                          context,
                          Icons.notifications,
                          'Notices',
                          const Color(0xFFFCEBEB),
                          const Color(0xFFA32D2D),
                          4,
                        ),

                        const SizedBox(width: 8),

                        _quickActionPage(
                          context,
                          Icons.payment,
                          'Payment',
                          const Color(0xFFE8F5E9),
                          const Color(0xFF2E7D32),
                          const FeePaymentScreen(),
                        ),

                        const SizedBox(width: 8),

                        _quickActionPage(
                          context,
                          Icons.school,
                          'CGPA',
                          const Color(0xFFEDE7F6),
                          const Color(0xFF673AB7),
                          const CgpaScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming assignments',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121))),
                    Text('See all',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF2196F3))),
                  ],
                ),
                const SizedBox(height: 10),
                _upcomingAssignments.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: const Color(0xFFE0E4EF)),
                  ),
                  child: Center(
                    child: Text('No upcoming assignments',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey)),
                  ),
                )
                    : Column(
                  children: _upcomingAssignments.map((a) {
                    final deadline =
                        DateTime.tryParse(a['deadline'] ?? '') ??
                            DateTime.now();
                    final daysLeft =
                        deadline.difference(DateTime.now()).inDays;
                    final isUrgent = daysLeft <= 2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _assignmentCard(
                        a['title'] ?? '',
                        a['courseName'] ?? '',
                        '$daysLeft days left',
                        isUrgent
                            ? const Color(0xFFFCEBEB)
                            : const Color(0xFFFAEEDA),
                        isUrgent
                            ? const Color(0xFFA32D2D)
                            : const Color(0xFF854F0B),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                Text('Latest notice',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121))),
                const SizedBox(height: 10),
                _latestNotice == null
                    ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: const Color(0xFFE0E4EF)),
                  ),
                  child: Center(
                    child: Text('No notices yet',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey)),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3C6E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_outlined,
                          color: Colors.white70, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_latestNotice!['title'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                                _latestNotice!['description'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white60),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(label,
              style:
              GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 0.5, height: 36, color: Colors.white24);
  }

  Widget _quickAction(BuildContext context, IconData icon, String label,
      Color bgColor, Color iconColor, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final state =
          context.findAncestorStateOfType<_StudentHomeState>();
          state?.setState(() => state._currentIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4EF)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: const Color(0xFF212121))),
            ],
          ),
        ),
      ),
    );
  }
  Widget _quickActionPage(
      BuildContext context,
      IconData icon,
      String label,
      Color bgColor,
      Color iconColor,
      Widget page,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4EF)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _assignmentCard(String title, String course, String deadline,
      Color badgeBg, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description_outlined,
                color: Color(0xFF185FA5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF212121))),
                Text(course,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(8)),
            child: Text(deadline,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: badgeColor,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}