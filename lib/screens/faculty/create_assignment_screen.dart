import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assignment_submissions_screen.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _deadline;
  String? _selectedCourseId;
  String? _selectedCourseName;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadAssignments();
  }

  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseDatabase.instance
        .ref('courses')
        .orderByChild('facultyId')
        .equalTo(uid)
        .get();

    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> courses = [];
    data.forEach((key, value) {
      final course = Map<String, dynamic>.from(value as Map);
      course['id'] = key;
      courses.add(course);
    });
    setState(() => _courses = courses);
  }

  void _loadAssignments() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    FirebaseDatabase.instance
        .ref('assignments')
        .orderByChild('facultyId')
        .equalTo(uid)
        .onValue
        .listen((event) {

      if (!event.snapshot.exists) {
        setState(() => _assignments = []);
        return;
      }

      final data =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      List<Map<String, dynamic>> assignments = [];

      data.forEach((key, value) {
        final item =
        Map<String, dynamic>.from(value as Map);

        item['id'] = key;

        assignments.add(item);
      });

      assignments.sort(
            (a, b) => (a['deadline'] ?? '')
            .compareTo(b['deadline'] ?? ''),
      );

      setState(() {
        _assignments = assignments;
      });
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _createAssignment() async {
    if (_titleController.text.isEmpty ||
        _selectedCourseId == null ||
        _deadline == null) {
      _showSnackbar('Please fill all fields and select deadline');
      return;
    }

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseDatabase.instance.ref('assignments').push().set({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'courseId': _selectedCourseId,
      'courseName': _selectedCourseName,
      'facultyId': uid,
      'deadline': _deadline!.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'submittedBy': {},
    });

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _deadline = null;
      _selectedCourseId = null;
      _selectedCourseName = null;
      _isLoading = false;
    });

    Navigator.pop(context);
    _loadAssignments();
    _showSnackbar('Assignment created!');
  }

  Future<void> _deleteAssignment(String id) async {
    await FirebaseDatabase.instance.ref('assignments/$id').remove();
    _loadAssignments();
    _showSnackbar('Assignment deleted!');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create assignment',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // Course dropdown
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                hint: Text('Select course',
                    style: GoogleFonts.poppins(fontSize: 13)),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _courses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course['id'],
                    child: Text(course['courseName'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setModalState(() {
                    _selectedCourseId = val;
                    _selectedCourseName = _courses
                        .firstWhere((c) => c['id'] == val)['courseName'];
                  });
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Assignment title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Deadline picker
              GestureDetector(
                onTap: () async {
                  await _pickDeadline();
                  setModalState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFF2196F3), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _deadline != null
                            ? 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                            : 'Select deadline',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _deadline != null ? const Color(0xFF212121) : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3C6E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Create assignment',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF1A3C6E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
            child: Text('Assignments',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          Expanded(
            child: _assignments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No assignments yet',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Tap + to create an assignment',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                final data = _assignments[index];
                final deadline = DateTime.tryParse(data['deadline'] ?? '') ?? DateTime.now();
                final isOverdue = deadline.isBefore(DateTime.now());
                final submittedCount = (data['submittedBy'] as Map? ?? {}).length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverdue
                          ? const Color(0xFFF0C1C1)
                          : const Color(0xFFE0E4EF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(data['title'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFFA32D2D), size: 20),
                            onPressed: () => _deleteAssignment(data['id']),
                          ),
                        ],
                      ),
                      Text(data['courseName'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: isOverdue
                                ? const Color(0xFFA32D2D)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${deadline.day}/${deadline.month}/${deadline.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isOverdue
                                  ? const Color(0xFFA32D2D)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F1FB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$submittedCount submitted',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF185FA5),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignmentSubmissionsScreen(
                                    assignmentId: data['id'],
                                    assignmentTitle: data['title'],
                                  ),
                                ),
                              );
                            },
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    ],
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