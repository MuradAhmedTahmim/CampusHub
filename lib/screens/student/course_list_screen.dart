import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _searchController = TextEditingController();

  String _searchQuery = '';

  bool _isLoading = true;

  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> _availableCourses = [];

  final List<Map<String, dynamic>> _courseColors = [
    {
      'bg': const Color(0xFFE6F1FB),
      'icon': const Color(0xFF185FA5),
      'iconData': Icons.code,
    },
    {
      'bg': const Color(0xFFE1F5EE),
      'icon': const Color(0xFF0F6E56),
      'iconData': Icons.calculate,
    },
    {
      'bg': const Color(0xFFFAEEDA),
      'icon': const Color(0xFFBA7517),
      'iconData': Icons.storage,
    },
    {
      'bg': const Color(0xFFFCEBEB),
      'icon': const Color(0xFFA32D2D),
      'iconData': Icons.phone_android,
    },
    {
      'bg': const Color(0xFFEEEDFE),
      'icon': const Color(0xFF534AB7),
      'iconData': Icons.hub,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      final enrolledIds = <String>{};

      final enrollmentSnap = await FirebaseDatabase.instance
          .ref('enrollments')
          .orderByChild('studentId')
          .equalTo(uid)
          .get();

      if (enrollmentSnap.exists) {
        final enrollmentData =
        Map<dynamic, dynamic>.from(enrollmentSnap.value as Map);

        enrollmentData.forEach((key, value) {
          final data = Map<dynamic, dynamic>.from(value);
          enrolledIds.add(data['courseId'].toString());
        });
      }

      final coursesSnap =
      await FirebaseDatabase.instance.ref('courses').get();

      List<Map<String, dynamic>> enrolledCourses = [];
      List<Map<String, dynamic>> availableCourses = [];

      if (coursesSnap.exists) {
        final coursesData =
        Map<dynamic, dynamic>.from(coursesSnap.value as Map);

        coursesData.forEach((key, value) {
          final course =
          Map<String, dynamic>.from(value as Map<dynamic, dynamic>);

          course['id'] = key;

          if (enrolledIds.contains(key)) {
            enrolledCourses.add(course);
          } else {
            availableCourses.add(course);
          }
        });
      }

      setState(() {
        _enrolledCourses = enrolledCourses;
        _availableCourses = availableCourses;
        _isLoading = false;
      });
    } catch (e) {
      print('LOAD COURSE ERROR: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollCourse(String courseId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      await FirebaseDatabase.instance.ref('enrollments').push().set({
        'studentId': uid,
        'courseId': courseId,
        'enrolledAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course enrolled successfully'),
        ),
      );

      await _loadCourses();
    } catch (e) {
      print('ENROLL ERROR: $e');
    }
  }

  Widget _buildCourseCard(
      Map<String, dynamic> course,
      int index, {
        bool showEnrollButton = false,
      }) {
    final colorSet = _courseColors[index % _courseColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E4EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colorSet['bg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              colorSet['iconData'] as IconData,
              color: colorSet['icon'] as Color,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['courseName'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${course['courseCode']} • ${course['credit']} Credits',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  course['facultyName'] ?? 'Faculty',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          if (showEnrollButton)
            ElevatedButton(
              onPressed: () => _enrollCourse(course['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C6E),
              ),
              child: const Text(
                'Enroll',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enrolledFiltered = _enrolledCourses.where((course) {
      return (course['courseName'] ?? '')
          .toString()
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();

    final availableFiltered = _availableCourses.where((course) {
      return (course['courseName'] ?? '')
          .toString()
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();

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
                Text(
                  'Courses',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Enrolled Courses',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                if (enrolledFiltered.isEmpty)
                  const Text('No enrolled courses'),

                ...List.generate(
                  enrolledFiltered.length,
                      (index) => _buildCourseCard(
                    enrolledFiltered[index],
                    index,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Available Courses',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                if (availableFiltered.isEmpty)
                  const Text('No available courses'),

                ...List.generate(
                  availableFiltered.length,
                      (index) => _buildCourseCard(
                    availableFiltered[index],
                    index,
                    showEnrollButton: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}