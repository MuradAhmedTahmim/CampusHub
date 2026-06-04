import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

 class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    FirebaseDatabase.instance
        .ref('submissions/${widget.assignmentId}')
        .onValue
        .listen((event) async {
      if (!event.snapshot.exists) {
        setState(() {
          _submissions = [];
          _isLoading = false;
        });
        return;
      }

      final data =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      List<Map<String, dynamic>> loaded = [];

      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        final submission =
        Map<String, dynamic>.from(value as Map);

        submission['studentUid'] = key;

        try {
          final userSnap = await FirebaseDatabase.instance
              .ref('users/$key')
              .get();

          if (userSnap.exists) {
            final userData =
            Map<String, dynamic>.from(userSnap.value as Map);

            submission['studentId'] =
                userData['studentId'] ?? '';
          }
        } catch (_) {
          submission['studentId'] = '';
        }

        loaded.add(submission);
      }

      loaded.sort((a, b) {
        return (b['submittedAt'] ?? '')
            .compareTo(a['submittedAt'] ?? '');
      });

      if (mounted) {
        setState(() {
          _submissions = loaded;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
        title: Text(
          widget.assignmentTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _submissions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'No submissions yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _submissions.length,
        itemBuilder: (context, index) {
          final data = _submissions[index];

          final submittedAt = DateTime.tryParse(
            data['submittedAt'] ?? '',
          ) ??
              DateTime.now();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE0E4EF),
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor:
                      Color(0xFF1A3C6E),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['studentName'] ?? 'Student',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          if ((data['studentId'] ?? '').toString().isNotEmpty)
                            Text(
                              'ID: ${data['studentId']}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  'Submitted:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Submission:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF5F7FA),
                    borderRadius:
                    BorderRadius.circular(
                        10),
                  ),
                  child: Text(
                    data['submissionText'] ??
                        '',
                    style:
                    GoogleFonts.poppins(
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 8,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                              0xFFE6F1FB),
                          borderRadius:
                          BorderRadius
                              .circular(
                              8),
                        ),
                        child: Center(
                          child: Text(
                            'Marks: ${data['marks'] ?? '-'}',
                            style:
                            GoogleFonts
                                .poppins(
                              fontSize: 11,
                              color:
                              const Color(
                                  0xFF185FA5),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEvaluateDialog(data),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Evaluate',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF085041),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Future<void> _showEvaluateDialog(Map<String, dynamic> data) async {
    final marksController = TextEditingController(
      text: data['marks']?.toString() ?? '',
    );

    final feedbackController = TextEditingController(
      text: data['feedback']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Evaluate Submission'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: marksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                await FirebaseDatabase.instance
                    .ref(
                  'submissions/${widget.assignmentId}/${data['studentUid']}',
                )
                    .update({
                  'marks': marksController.text.trim(),
                  'feedback': feedbackController.text.trim(),
                });

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}