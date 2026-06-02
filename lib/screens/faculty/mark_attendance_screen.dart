import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  String? _selectedCourseName;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceStatus = {};
  bool _isLoadingCourses = true;
  bool _isLoadingStudents = false;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseDatabase.instance
        .ref('courses')
        .orderByChild('facultyId')
        .equalTo(uid)
        .get();

    if (!snap.exists) {
      setState(() => _isLoadingCourses = false);
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> courses = [];
    data.forEach((key, value) {
      final course = Map<String, dynamic>.from(value as Map);
      course['id'] = key;
      courses.add(course);
    });

    setState(() {
      _courses = courses;
      _isLoadingCourses = false;
    });
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() => _isLoadingStudents = true);
    print("Course ID: $courseId");
    final enrollSnap = await FirebaseDatabase.instance
        .ref('enrollments')
        .orderByChild('courseId')
        .equalTo(courseId)
        .get();

    print("Enroll Exists: ${enrollSnap.exists}");
    print(enrollSnap.value);

    if (!enrollSnap.exists) {
      setState(() {
        _students = [];
        _isLoadingStudents = false;
      });
      return;
    }

    final enrollments = Map<String, dynamic>.from(enrollSnap.value as Map);
    List<Map<String, dynamic>> students = [];

    for (var entry in enrollments.values) {
      final enrollment = Map<String, dynamic>.from(entry as Map);
      final studentId = enrollment['studentId'];
      final userSnap = await FirebaseDatabase.instance
          .ref('users/$studentId')
          .get();

      if (userSnap.exists) {
        final user = Map<String, dynamic>.from(userSnap.value as Map);
        user['uid'] = studentId;
        students.add(user);
        _attendanceStatus[studentId] = 'Present';
      }
    }

    setState(() {
      _students = students;
      _isLoadingStudents = false;
    });
  }

  Future<void> _saveAttendance() async {
    if (_selectedCourseId == null || _students.isEmpty) return;

    setState(() => _isSaving = true);

    final dateKey =
        "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";

    for (var student in _students) {
      final uid = student['uid'];
      final status = _attendanceStatus[uid] ?? 'Present';

      await FirebaseDatabase.instance
          .ref('attendance/$_selectedCourseId/$dateKey/$uid')
          .set({
        'studentId': uid,
        'studentName': student['name'] ?? '',
        'courseId': _selectedCourseId,
        'courseName': _selectedCourseName,
        'status': status,
        'date': _selectedDate.toIso8601String(),
      });
    }

    setState(() => _isSaving = false);
    _showSnackbar('Attendance saved successfully!');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Mark Attendance',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 14),

                // Course selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourseId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A3C6E),
                      hint: Text('Select course',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.white54)),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white54),
                      items: _courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text(course['courseName'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCourseId = val;
                          _selectedCourseName = _courses
                              .firstWhere((c) => c['id'] == val)['courseName'];
                        });
                        _loadStudents(val!);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student list
          Expanded(
            child: _isLoadingCourses || _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _selectedCourseId == null
                ? Center(
              child: Text('Select a course to mark attendance',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey)),
            )
                : _students.isEmpty
                ? Center(
              child: Text('No students enrolled',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey)),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final uid = student['uid'];
                final status =
                    _attendanceStatus[uid] ?? 'Present';
                final isPresent = status == 'Present';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPresent
                          ? const Color(0xFFE1F5EE)
                          : const Color(0xFFF0C1C1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isPresent
                            ? const Color(0xFF0F6E56)
                            : const Color(0xFFA32D2D),
                        child: Text(
                          (student['name'] ?? 'S')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(student['name'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF212121))),
                            Text(student['email'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() =>
                            _attendanceStatus[uid] = 'Present'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? const Color(0xFF0F6E56)
                                    : const Color(0xFFE1F5EE),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text('P',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isPresent
                                          ? Colors.white
                                          : const Color(0xFF0F6E56))),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() =>
                            _attendanceStatus[uid] = 'Absent'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !isPresent
                                    ? const Color(0xFFA32D2D)
                                    : const Color(0xFFFCEBEB),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text('A',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: !isPresent
                                          ? Colors.white
                                          : const Color(0xFFA32D2D))),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Save button
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3C6E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save attendance',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}