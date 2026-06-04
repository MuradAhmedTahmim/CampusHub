import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  String _filter = 'All';
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  String? _uid;
  final _submissionController = TextEditingController();
  Map<String, dynamic> _mySubmissions = {};
  List<String> _enrolledCourseIds = [];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadEnrollments();
    _loadAssignments();
    _loadMySubmissions();
  }
    @override
    void dispose() {
      _submissionController.dispose();
      super.dispose();
    }


  void _loadAssignments() {
    FirebaseDatabase.instance
        .ref('assignments')
        .onValue
        .listen((event) {
      if (!event.snapshot.exists) {
        setState(() {
          _assignments = [];
          _isLoading = false;
        });
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
            (a, b) =>
            (a['deadline'] ?? '')
                .compareTo(b['deadline'] ?? ''),
      );

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    });
  }
  void _loadMySubmissions() {
    if (_uid == null) return;

    FirebaseDatabase.instance
        .ref('submissions')
        .onValue
        .listen((event) {

      if (!event.snapshot.exists) {
        setState(() {
          _mySubmissions = {};
        });
        return;
      }

      final data =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      Map<String, dynamic> temp = {};

      data.forEach((assignmentId, value) {
        final submissions =
        Map<String, dynamic>.from(value as Map);

        if (submissions.containsKey(_uid)) {
          temp[assignmentId] =
          Map<String, dynamic>.from(submissions[_uid]);
        }
      });

      setState(() {
        _mySubmissions = temp;
      });
    });
  }
  Future<void> _loadEnrollments() async {
    if (_uid == null) return;

    final snap =
    await FirebaseDatabase.instance.ref('enrollments').get();

    if (!snap.exists) return;

    final data =
    Map<String, dynamic>.from(snap.value as Map);

    List<String> enrolled = [];

    data.forEach((key, value) {
      final item =
      Map<String, dynamic>.from(value as Map);

      if (item['studentId'] == _uid) {
        enrolled.add(item['courseId']);
      }
    });

    setState(() {
      _enrolledCourseIds = enrolled;
    });
  }

  Future<void> _submitAssignment(
      String assignmentId,
      String submissionText,
      ) async {
    if (_uid == null) return;

    final userSnap = await FirebaseDatabase.instance
        .ref('users/$_uid')
        .get();

    String studentName = 'Student';
    String studentId = '';

    if (userSnap.exists) {
      final userData =
      Map<String, dynamic>.from(userSnap.value as Map);

      studentName = userData['name'] ?? 'Student';
      studentId = userData['studentId'] ?? '';
    }

    await FirebaseDatabase.instance
        .ref('submissions/$assignmentId/$_uid')
        .set({
      'studentId': studentId,
      'studentName': studentName,
      'submissionText': submissionText,
      'submittedAt': DateTime.now().toIso8601String(),
      'marks': '',
      'feedback': '',
    });

    await FirebaseDatabase.instance
        .ref('assignments/$assignmentId/submittedBy/$_uid')
        .set(true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully'),
        ),
      );
    }
  }

  void _showSubmitDialog(String assignmentId) {
    _submissionController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Assignment'),
          content: TextField(
            controller: _submissionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
              'Paste GitHub link, Drive link, or write your answer',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text =
                _submissionController.text.trim();

                if (text.isEmpty) return;

                Navigator.pop(context);

                await _submitAssignment(
                  assignmentId,
                  text,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    List<Map<String, dynamic>> filtered =
    _assignments.where((data) {

      if (!_enrolledCourseIds.contains(
          data['courseId'])) {
        return false;
      }

      final deadline =
          DateTime.tryParse(
            data['deadline'] ?? '',
          ) ??
              now;

      final submittedBy =
          data['submittedBy'] as Map? ?? {};

      final submitted =
      submittedBy.containsKey(_uid);

      if (_filter == 'Submitted') return submitted;
      if (_filter == 'Overdue')
        return !submitted &&
            deadline.isBefore(now);
      if (_filter == 'Pending')
        return !submitted &&
            deadline.isAfter(now);

      return true;
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
                Text('Assignments',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'Submitted', 'Overdue'].map((filter) {
                      final isSelected = _filter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2196F3)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(filter,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No assignments',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data = filtered[index];
                final deadline = DateTime.tryParse(data['deadline'] ?? '') ?? now;
                final submittedBy = data['submittedBy'] as Map? ?? {};
                final submitted = submittedBy.containsKey(_uid);
                final isOverdue = !submitted && deadline.isBefore(now);
                final daysLeft = deadline.difference(now).inDays;
                final mySubmission = _mySubmissions[data['id']] ?? {};
                print(_mySubmissions);
                final marks = mySubmission['marks']?.toString() ?? '';
                final feedback = mySubmission['feedback']?.toString() ?? '';

                Color badgeBg;
                Color badgeColor;
                String badgeText;

                if (submitted) {
                  badgeBg = const Color(0xFFE1F5EE);
                  badgeColor = const Color(0xFF085041);
                  badgeText = 'Submitted';
                } else if (isOverdue) {
                  badgeBg = const Color(0xFFFCEBEB);
                  badgeColor = const Color(0xFFA32D2D);
                  badgeText = 'Overdue';
                } else if (daysLeft <= 2) {
                  badgeBg = const Color(0xFFFCEBEB);
                  badgeColor = const Color(0xFFA32D2D);
                  badgeText = '$daysLeft days left';
                } else {
                  badgeBg = const Color(0xFFE1F5EE);
                  badgeColor = const Color(0xFF085041);
                  badgeText = '$daysLeft days left';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
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
                            child: Text(
                              data['title'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212121)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(badgeText,
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: badgeColor)),
                          ),
                        ],
                      ),
                      if (submitted) ...[
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Marks: ${marks.isEmpty ? "Not graded yet" : marks}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Feedback: ${feedback.isEmpty ? "No feedback yet" : feedback}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(data['courseName'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 13,
                                  color: isOverdue
                                      ? const Color(0xFFA32D2D)
                                      : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${deadline.day}/${deadline.month}/${deadline.year}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: isOverdue
                                        ? const Color(0xFFA32D2D)
                                        : Colors.grey),
                              ),
                            ],
                          ),
                          if (!submitted)
                            GestureDetector(
                              onTap: () => _showSubmitDialog(data['id']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3C6E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Submit',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
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
        ],
      ),
    );
  }
}