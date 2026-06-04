import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];

  String? _selectedCourseId;
  String? _selectedCourseName;
  int _selectedCredit = 0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final snap = await FirebaseDatabase.instance
        .ref('courses')
        .orderByChild('facultyId')
        .equalTo(uid)
        .get();

    if (!snap.exists) {
      setState(() => _isLoading = false);
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
      _isLoading = false;
    });
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() {
      _students.clear();
      _isLoading = true;
    });

    final enrollSnap = await FirebaseDatabase.instance
        .ref('enrollments')
        .orderByChild('courseId')
        .equalTo(courseId)
        .get();

    List<Map<String, dynamic>> students = [];

    if (enrollSnap.exists) {
      final enrollments = Map<String, dynamic>.from(enrollSnap.value as Map);

      for (var item in enrollments.values) {
        final enrollment = Map<String, dynamic>.from(item as Map);

        final studentId = enrollment['studentId'].toString();

        final userSnap = await FirebaseDatabase.instance
            .ref('users/$studentId')
            .get();

        if (userSnap.exists) {
          final user = Map<String, dynamic>.from(userSnap.value as Map);

          students.add({
            'studentId': user['studentId'] ?? '',
            'name': user['name'] ?? '',
            'email': user['email'] ?? '',
            'selectedGpa': 4.0,
          });
        }
      }
    }

    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _saveGrade(Map<String, dynamic> student) async {
    final facultyId = FirebaseAuth.instance.currentUser?.uid;

    if (facultyId == null) return;

    final gradesRef = FirebaseDatabase.instance.ref('grades');

    final existingSnap = await gradesRef.get();

    String? existingGradeKey;

    if (existingSnap.exists) {
      final grades =
      Map<String, dynamic>.from(existingSnap.value as Map);

      grades.forEach((key, value) {
        final grade =
        Map<String, dynamic>.from(value as Map);

        if (grade['studentId'] == student['studentId'] &&
            grade['courseId'] == _selectedCourseId) {
          existingGradeKey = key;
        }
      });
    }

    final gradeData = {
      'studentId': student['studentId'],
      'courseId': _selectedCourseId,
      'courseName': _selectedCourseName,
      'credit': _selectedCredit,
      'gpa': student['selectedGpa'],
      'facultyId': facultyId,
      'submittedAt': DateTime.now().toIso8601String(),
    };

    if (existingGradeKey != null) {
      await gradesRef
          .child(existingGradeKey!)
          .update(gradeData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Grade updated for ${student['name']}'),
        ),
      );
    } else {
      await gradesRef.push().set(gradeData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Grade submitted for ${student['name']}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Grade Management'),
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                    ),
                    items: _courses.map<DropdownMenuItem<String>>((course) {
                      return DropdownMenuItem<String>(
                        value: course['id'].toString(),
                        child: Text(
                          "${course['courseCode']} - ${course['courseName']}",
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      final course = _courses.firstWhere(
                        (e) => e['id'] == value,
                      );

                      _selectedCourseId = course['id'].toString();

                      _selectedCourseName =
                          course['courseName'].toString();

                      _selectedCredit = (course['credit'] ?? 0);

                      _loadStudents(value);
                    },
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                'ID: ${student['studentId'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 10),

                              DropdownButton<double>(
                                value: student['selectedGpa'],
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 4.00,
                                    child: Text('A+ (4.00)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 3.75,
                                    child: Text('A (3.75)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 3.50,
                                    child: Text('A- (3.50)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 3.25,
                                    child: Text('B+ (3.25)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 3.00,
                                    child: Text('B (3.00)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2.75,
                                    child: Text('B- (2.75)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2.50,
                                    child: Text('C+ (2.50)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2.25,
                                    child: Text('C (2.25)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2.00,
                                    child: Text('A- (2.00)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0.0,
                                    child: Text('F'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    student['selectedGpa'] = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _saveGrade(student),
                                  child: const Text('Submit Grade'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
