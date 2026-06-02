import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageCourseScreen extends StatefulWidget {
  const ManageCourseScreen({super.key});

  @override
  State<ManageCourseScreen> createState() => _ManageCourseScreenState();
}

class _ManageCourseScreenState extends State<ManageCourseScreen> {
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _creditController = TextEditingController();

  bool _isLoading = false;

  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userSnap =
      await FirebaseDatabase.instance.ref('users/$uid').get();

      final userData =
      Map<String, dynamic>.from(userSnap.value as Map);

      final facultyName = userData['name'] ?? 'Faculty';

      print('CURRENT UID: $uid');

      final snap = await FirebaseDatabase.instance
          .ref('courses')
          .orderByChild('facultyId')
          .equalTo(uid)
          .get();

      print('SNAP EXISTS: ${snap.exists}');
      print('SNAP VALUE: ${snap.value}');

      if (!snap.exists) {
        setState(() {
          _courses = [];
        });
        return;
      }

      final Map<dynamic, dynamic> rawData =
      snap.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> loadedCourses = [];

      rawData.forEach((key, value) {
        final course = Map<String, dynamic>.from(value);

        course['id'] = key;

        loadedCourses.add(course);
      });

      print('LOADED COURSES: $loadedCourses');

      setState(() {
        _courses = loadedCourses;
      });
    } catch (e) {
      print('LOAD COURSE ERROR: $e');

      _showSnackbar('Failed to load courses');
    }
  }

  Future<void> _addCourse() async {
    if (_courseNameController.text.trim().isEmpty ||
        _courseCodeController.text.trim().isEmpty ||
        _creditController.text.trim().isEmpty) {
      _showSnackbar('Please fill in all fields');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showSnackbar('User not logged in');
        return;
      }

      final uid = user.uid;

      // Faculty name load
      final userSnap =
      await FirebaseDatabase.instance.ref('users/$uid').get();

      String facultyName = 'Faculty';

      if (userSnap.exists) {
        final userData =
        Map<String, dynamic>.from(userSnap.value as Map);

        facultyName = userData['name'] ?? 'Faculty';
      }

      final newRef = FirebaseDatabase.instance.ref('courses').push();

      await newRef.set({
        'courseName': _courseNameController.text.trim(),
        'courseCode': _courseCodeController.text.trim(),
        'credit': double.tryParse(_creditController.text.trim()) ?? 3.0,
        'facultyId': uid,
        'facultyName': facultyName,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _courseNameController.clear();
      _courseCodeController.clear();
      _creditController.clear();

      Navigator.pop(context);

      await _loadCourses();

      _showSnackbar('Course added successfully!');
    } catch (e) {
      print('ADD COURSE ERROR: $e');
      _showSnackbar('Failed to add course');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await FirebaseDatabase.instance
          .ref('courses/$courseId')
          .remove();

      await _loadCourses();

      _showSnackbar('Course deleted');
    } catch (e) {
      print('DELETE ERROR: $e');

      _showSnackbar('Delete failed');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showAddCourseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Course',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _courseNameController,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _courseCodeController,
                decoration: InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _creditController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3C6E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    'Add Course',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _creditController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        backgroundColor: const Color(0xFF1A3C6E),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 55, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3C6E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Text(
              'Manage Courses',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: _courses.isEmpty
                ? Center(
              child: Text(
                'No courses found',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.book,
                        color: Color(0xFF1A3C6E),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['courseName'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${course['courseCode']} • ${course['credit']} Credits',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          _deleteCourse(course['id']);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
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
}