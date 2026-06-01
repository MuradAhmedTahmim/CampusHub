import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class CgpaScreen extends StatefulWidget {
  const CgpaScreen({super.key});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _grades = [];
  double _cgpa = 0;
  int _totalCredits = 0;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseDatabase.instance
        .ref('grades')
        .orderByChild('studentId')
        .equalTo(uid)
        .get();

    if (!snap.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> grades = [];
    double totalPoints = 0;
    int totalCredits = 0;

    data.forEach((key, value) {
      final grade = Map<String, dynamic>.from(value as Map);
      grade['id'] = key;
      grades.add(grade);

      final credit = (grade['credit'] ?? 0) as num;
      final gpa = (grade['gpa'] ?? 0) as num;
      totalPoints += credit.toDouble() * gpa.toDouble();
      totalCredits += credit.toInt();
    });

    setState(() {
      _grades = grades;
      _totalCredits = totalCredits;
      _cgpa = totalCredits > 0 ? totalPoints / totalCredits : 0;
      _isLoading = false;
    });
  }

  String _getLetterGrade(double gpa) {
    if (gpa >= 4.0) return 'A';
    if (gpa >= 3.7) return 'A-';
    if (gpa >= 3.3) return 'B+';
    if (gpa >= 3.0) return 'B';
    if (gpa >= 2.7) return 'B-';
    if (gpa >= 2.3) return 'C+';
    if (gpa >= 2.0) return 'C';
    return 'F';
  }

  Color _getGradeColor(double gpa) {
    if (gpa >= 3.7) return const Color(0xFF185FA5);
    if (gpa >= 3.0) return const Color(0xFF0F6E56);
    if (gpa >= 2.0) return const Color(0xFFBA7517);
    return const Color(0xFFA32D2D);
  }

  final List<Map<String, dynamic>> _colorSets = [
    {'bg': const Color(0xFFE6F1FB), 'icon': const Color(0xFF185FA5), 'iconData': Icons.code},
    {'bg': const Color(0xFFE1F5EE), 'icon': const Color(0xFF0F6E56), 'iconData': Icons.calculate},
    {'bg': const Color(0xFFFAEEDA), 'icon': const Color(0xFFBA7517), 'iconData': Icons.storage},
    {'bg': const Color(0xFFFCEBEB), 'icon': const Color(0xFFA32D2D), 'iconData': Icons.phone_android},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 52, 18, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3C6E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CGPA Calculator',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _cgpa / 4.0,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: const Color(0xFF2196F3),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _cgpa.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text('out of 4.00',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.white60)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _summaryBox('${_grades.length}', 'Courses'),
                    const SizedBox(width: 8),
                    _summaryBox('$_totalCredits', 'Credits'),
                    const SizedBox(width: 8),
                    _summaryBox(_getLetterGrade(_cgpa), 'Grade'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _grades.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.grade_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No grades yet',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _grades.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Course grades',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121))),
                  );
                }

                if (index == _grades.length + 1) {
                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E4EF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grade scale',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _gradeBox('A', '4.00', const Color(0xFFE6F1FB), const Color(0xFF0C447C)),
                            const SizedBox(width: 6),
                            _gradeBox('A-', '3.70', const Color(0xFFE1F5EE), const Color(0xFF085041)),
                            const SizedBox(width: 6),
                            _gradeBox('B+', '3.30', const Color(0xFFFAEEDA), const Color(0xFF633806)),
                            const SizedBox(width: 6),
                            _gradeBox('B', '3.00', const Color(0xFFFCEBEB), const Color(0xFF791F1F)),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                final data = _grades[index - 1];
                final gpa = (data['gpa'] ?? 0.0) as num;
                final letterGrade = _getLetterGrade(gpa.toDouble());
                final gradeColor = _getGradeColor(gpa.toDouble());
                final colorSet = _colorSets[(index - 1) % _colorSets.length];

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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorSet['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(colorSet['iconData'] as IconData,
                            color: colorSet['icon'] as Color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['courseName'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF212121)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${data['credit']} credits',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            letterGrade,
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: gradeColor),
                          ),
                          Text(
                            gpa.toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey),
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

  Widget _summaryBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _gradeBox(String grade, String point, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(grade,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            Text(point, style: GoogleFonts.poppins(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }
}