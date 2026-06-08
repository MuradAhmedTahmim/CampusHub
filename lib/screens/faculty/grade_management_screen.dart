import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

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
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print("No faculty logged in");
        setState(() => _isLoading = false);
        return;
      }

      print("Loading courses for faculty: $uid");

      final snap = await FirebaseDatabase.instance
          .ref('courses')
          .orderByChild('facultyId')
          .equalTo(uid)
          .get();

      if (!snap.exists) {
        print("No courses found");
        setState(() => _isLoading = false);
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);
      List<Map<String, dynamic>> courses = [];

      data.forEach((key, value) {
        final course = Map<String, dynamic>.from(value as Map);
        course['id'] = key;
        courses.add(course);
        print("Course loaded: ${course['courseName']} (${course['courseCode']})");
      });

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading courses: $e");
      setState(() => _isLoading = false);
      _showSnackBar("Error loading courses: $e");
    }
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() {
      _students.clear();
      _isLoading = true;
    });

    try {
      final enrollSnap = await FirebaseDatabase.instance
          .ref('enrollments')
          .orderByChild('courseId')
          .equalTo(courseId)
          .get();

      List<Map<String, dynamic>> students = [];
      List<String> invalidEnrollments = [];

      if (enrollSnap.exists) {
        final enrollments = Map<String, dynamic>.from(enrollSnap.value as Map);

        for (var entry in enrollments.entries) {
          final enrollment = Map<String, dynamic>.from(entry.value as Map);
          final studentUid = enrollment['studentId'].toString();

          // Check if student exists
          final userSnap = await FirebaseDatabase.instance
              .ref('users/$studentUid')
              .get();

          if (userSnap.exists) {
            final userData = Map<String, dynamic>.from(userSnap.value as Map);
            students.add({
              'studentUid': studentUid,
              'studentId': userData['studentId'] ?? 'N/A',
              'name': userData['name'] ?? 'Unknown Student',
              'email': userData['email'] ?? 'No email',
              'selectedGpa': 4.0,
              'enrollmentKey': entry.key, // Store for potential deletion
            });
          } else {
            // Mark for deletion
            invalidEnrollments.add(entry.key);
            print("Invalid enrollment found: ${entry.key} -> studentId: $studentUid");
          }
        }
      }

      // Show dialog to delete invalid entries
      if (invalidEnrollments.isNotEmpty) {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invalid Enrollments Found'),
            content: Text('Found ${invalidEnrollments.length} enrollment(s) with missing student data. Do you want to remove them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Remove'),
              ),
            ],
          ),
        );

        if (shouldDelete == true) {
          for (var key in invalidEnrollments) {
            await FirebaseDatabase.instance
                .ref('enrollments/$key')
                .remove();
            print("Deleted enrollment: $key");
          }
          _showSnackBar('Removed ${invalidEnrollments.length} invalid enrollment(s)');

          // Reload to refresh the list
          await _loadStudents(courseId);
          return;
        }
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });

    } catch (e) {
      print("Error loading students: $e");
      setState(() => _isLoading = false);
      _showSnackBar("Error loading students: $e");
    }
  }

  Future<double?> _getExistingGrade(String studentUid, String courseId) async {
    try {
      final gradesSnap = await FirebaseDatabase.instance
          .ref('grades')
          .orderByChild('studentId')
          .equalTo(studentUid)
          .get();

      if (gradesSnap.exists) {
        final grades = Map<String, dynamic>.from(gradesSnap.value as Map);

        for (var gradeEntry in grades.entries) {
          final grade = Map<String, dynamic>.from(gradeEntry.value as Map);
          if (grade['courseId'] == courseId) {
            final gpa = grade['gpa'];
            if (gpa is int) return gpa.toDouble();
            if (gpa is double) return gpa;
            if (gpa is String) return double.tryParse(gpa);
            return 4.0;
          }
        }
      }
      return null;
    } catch (e) {
      print("Error getting existing grade: $e");
      return null;
    }
  }

  Future<void> _saveGrade(Map<String, dynamic> student) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final facultyId = FirebaseAuth.instance.currentUser?.uid;
      if (facultyId == null) {
        _showSnackBar("Faculty not logged in");
        return;
      }

      final studentUid = student['studentUid']; // This is the actual UID
      final selectedGpa = student['selectedGpa'];

      print("Saving grade for Student UID: $studentUid");
      print("Course: $_selectedCourseName, GPA: $selectedGpa");

      final gradesRef = FirebaseDatabase.instance.ref('grades');

      // Check if grade already exists
      String? existingGradeKey;
      final existingSnap = await gradesRef.get();

      if (existingSnap.exists) {
        final grades = Map<String, dynamic>.from(existingSnap.value as Map);

        grades.forEach((key, value) {
          final grade = Map<String, dynamic>.from(value as Map);
          if (grade['studentId'] == studentUid &&
              grade['courseId'] == _selectedCourseId) {
            existingGradeKey = key;
          }
        });
      }

      // Prepare grade data with UID as studentId
      final gradeData = {
        'studentId': studentUid,
        'courseId': _selectedCourseId,
        'courseName': _selectedCourseName,
        'credit': _selectedCredit,
        'gpa': selectedGpa,
        'facultyId': facultyId,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      if (existingGradeKey != null) {
        // Update existing grade
        await gradesRef.child(existingGradeKey!).update(gradeData);
        _showSnackBar('Grade updated for ${student['name']} (GPA: $selectedGpa)');
        print("Grade updated successfully");
      } else {
        // Create new grade
        await gradesRef.push().set(gradeData);
        _showSnackBar('Grade submitted for ${student['name']} (GPA: $selectedGpa)');
        print("Grade submitted successfully");
      }

    } catch (e) {
      print("Error saving grade: $e");
      _showSnackBar("Error saving grade: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Grade Management'),
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Course Selection Dropdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _courses.map<DropdownMenuItem<String>>((course) {
                    return DropdownMenuItem<String>(
                      value: course['id'].toString(),
                      child: Text(
                        "${course['courseCode']} - ${course['courseName']} (${course['credit']} Credits)",
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final course = _courses.firstWhere(
                          (e) => e['id'] == value,
                    );

                    setState(() {
                      _selectedCourseId = course['id'].toString();
                      _selectedCourseName = course['courseName'].toString();
                      _selectedCredit = (course['credit'] ?? 0) as int;
                    });

                    _loadStudents(value);
                  },
                ),
              ),
            ),
          ),

          // Students List
          Expanded(
            child: _students.isEmpty && _selectedCourseId != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students enrolled',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This course has no enrolled students yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF1A3C6E).withOpacity(0.1),
                              child: Text(
                                student['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF1A3C6E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${student['studentId']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    student['email'],
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Grade Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<double>(
                            value: student['selectedGpa'],
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 4.00, child: Text('A+ (4.00)')),
                              DropdownMenuItem(value: 3.75, child: Text('A (3.75)')),
                              DropdownMenuItem(value: 3.50, child: Text('A- (3.50)')),
                              DropdownMenuItem(value: 3.25, child: Text('B+ (3.25)')),
                              DropdownMenuItem(value: 3.00, child: Text('B (3.00)')),
                              DropdownMenuItem(value: 2.75, child: Text('B- (2.75)')),
                              DropdownMenuItem(value: 2.50, child: Text('C+ (2.50)')),
                              DropdownMenuItem(value: 2.25, child: Text('C (2.25)')),
                              DropdownMenuItem(value: 2.00, child: Text('C- (2.00)')),
                              DropdownMenuItem(value: 0.00, child: Text('F (0.00)')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                student['selectedGpa'] = value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : () => _saveGrade(student),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3C6E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text('Submit Grade'),
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