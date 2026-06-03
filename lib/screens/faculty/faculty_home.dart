import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_course_screen.dart';
import 'create_assignment_screen.dart';
import 'mark_attendance_screen.dart';
import '../student/profile_screen.dart';
import 'create_notice_screen.dart';
import 'grade_management_screen.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  int _currentIndex = 0;
  String _userName = '';
  String _userInitials = 'F';

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
            : 'F';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _FacultyHomeContent(
        userName: _userName,
        userInitials: _userInitials,
      ),
      const ManageCourseScreen(),
      const CreateAssignmentScreen(),
      const MarkAttendanceScreen(),
      const GradeManagementScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Assignments'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Attendance'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade_outlined),
            activeIcon: Icon(Icons.grade),
            label: 'Grades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _FacultyHomeContent extends StatelessWidget {
  final String userName;
  final String userInitials;

  const _FacultyHomeContent({this.userName = '', this.userInitials = 'F'});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
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
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
                        Text(userName.isNotEmpty ? userName : 'Faculty',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text('Faculty',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
                      ],
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0F6E56),
                      child: Text(userInitials,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Summary card
                FutureBuilder(
                  future: Future.wait([
                    FirebaseDatabase.instance
                        .ref('courses')
                        .orderByChild('facultyId')
                        .equalTo(uid)
                        .get(),

                    FirebaseDatabase.instance
                        .ref('assignments')
                        .orderByChild('facultyId')
                        .equalTo(uid)
                        .get(),

                    FirebaseDatabase.instance
                        .ref('enrollments')
                        .get(),
                  ]),
                  builder: (context, snapshot) {

                    if (snapshot.hasError) {
                      return Text(
                        'ERROR: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final results = snapshot.data! as List;

                    print(results[0].value);
                    print(results[1].value);
                    print(results[2].value);

                    final coursesSnap = results[0];
                    final assignmentsSnap = results[1];
                    final enrollmentsSnap = results[2];

                    int courseCount = 0;
                    int assignmentCount = 0;
                    int studentCount = 0;

                    Set<String> facultyCourseIds = {};
                    Set<String> uniqueStudents = {};

                    // Courses
                    if (coursesSnap.exists) {
                      final courses =
                      Map<String, dynamic>.from(coursesSnap.value as Map);

                      courseCount = courses.length;

                      courses.forEach((key, value) {
                        facultyCourseIds.add(key);
                      });
                    }

                    // Assignments
                    if (assignmentsSnap.exists) {
                      final assignments =
                      Map<String, dynamic>.from(assignmentsSnap.value as Map);

                      assignmentCount = assignments.length;
                    }

                    // Unique Students
                    if (enrollmentsSnap.exists) {
                      final enrollments =
                      Map<String, dynamic>.from(enrollmentsSnap.value as Map);

                      enrollments.forEach((enrollmentId, value) {
                        final enrollment =
                        Map<String, dynamic>.from(value as Map);

                        final courseId =
                            enrollment['courseId']?.toString() ?? '';

                        final studentId =
                            enrollment['studentId']?.toString() ?? '';

                        if (facultyCourseIds.contains(courseId)) {
                          uniqueStudents.add(studentId);
                        }
                      });

                      studentCount = uniqueStudents.length;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          _summaryItem('$courseCount', 'Courses'),
                          _divider(),
                          _summaryItem('$assignmentCount', 'Assignments'),
                          _divider(),
                          _summaryItem('$studentCount', 'Students'),
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick access
                Text('Quick access',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _quickAction(context, Icons.book, 'Courses',
                        const Color(0xFFE6F1FB), const Color(0xFF185FA5), 1),
                    const SizedBox(width: 8),
                    _quickAction(context, Icons.assignment_add, 'Assignment',
                        const Color(0xFFE1F5EE), const Color(0xFF0F6E56), 2),
                    const SizedBox(width: 8),
                    _quickAction(context, Icons.how_to_reg, 'Attendance',
                        const Color(0xFFFAEEDA), const Color(0xFFBA7517), 3),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateNoticeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.campaign),
                    label: const Text('Create Notice'),
                  ),
                ),

                // My courses
                Text('My courses',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
                const SizedBox(height: 10),
                FutureBuilder<DataSnapshot>(
                  future: FirebaseDatabase.instance
                      .ref('courses')
                      .orderByChild('facultyId')
                      .equalTo(uid)
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData || !snap.data!.exists) {
                      return Center(
                        child: Text('No courses assigned',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                      );
                    }

                    final courses = Map<String, dynamic>.from(snap.data!.value as Map);
                    final List<Map<String, dynamic>> courseColors = [
                      {'bg': const Color(0xFFE6F1FB), 'icon': const Color(0xFF185FA5), 'iconData': Icons.code},
                      {'bg': const Color(0xFFE1F5EE), 'icon': const Color(0xFF0F6E56), 'iconData': Icons.calculate},
                      {'bg': const Color(0xFFFAEEDA), 'icon': const Color(0xFFBA7517), 'iconData': Icons.storage},
                      {'bg': const Color(0xFFFCEBEB), 'icon': const Color(0xFFA32D2D), 'iconData': Icons.phone_android},
                    ];

                    int i = 0;
                    return Column(
                      children: courses.entries.map((entry) {
                        final course = Map<String, dynamic>.from(entry.value as Map);
                        final colorSet = courseColors[i++ % courseColors.length];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E4EF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorSet['bg'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(colorSet['iconData'] as IconData,
                                    color: colorSet['icon'] as Color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(course['courseName'] ?? '',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF212121))),
                                    Text('${course['credit']} credits',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorSet['bg'] as Color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(course['courseCode'] ?? '',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: colorSet['icon'] as Color)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
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
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
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
          final state = context.findAncestorStateOfType<_FacultyHomeState>();
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
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF212121))),
            ],
          ),
        ),
      ),
    );
  }
}