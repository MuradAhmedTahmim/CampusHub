import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  String _filter = 'All';
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;

  final Map<String, Map<String, dynamic>> _typeStyles = {
    'Important': {
      'bg': const Color(0xFFFCEBEB),
      'color': const Color(0xFFA32D2D),
      'borderColor': const Color(0xFFA32D2D),
      'emoji': '🔴',
    },
    'Exam': {
      'bg': const Color(0xFFFAEEDA),
      'color': const Color(0xFF854F0B),
      'borderColor': const Color(0xFFBA7517),
      'emoji': '📝',
    },
    'Event': {
      'bg': const Color(0xFFE1F5EE),
      'color': const Color(0xFF085041),
      'borderColor': const Color(0xFF0F6E56),
      'emoji': '🎉',
    },
    'General': {
      'bg': const Color(0xFFE6F1FB),
      'color': const Color(0xFF0C447C),
      'borderColor': const Color(0xFF2196F3),
      'emoji': '📢',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    final snap = await FirebaseDatabase.instance.ref('notices').get();
    if (!snap.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> notices = [];
    data.forEach((key, value) {
      final notice = Map<String, dynamic>.from(value as Map);
      notice['id'] = key;
      notices.add(notice);
    });

    notices.sort((a, b) =>
        (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

    setState(() {
      _notices = notices;
      _isLoading = false;
    });
  }

  String _timeAgo(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _notices
        : _notices.where((n) => n['type'] == _filter).toList();

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notices',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const Icon(Icons.notifications_outlined, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Important', 'Exam', 'Event', 'General']
                        .map((filter) {
                      final isSelected = _filter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
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
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
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
                  const Icon(Icons.notifications_none,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No notices yet',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data = filtered[index];
                final type = data['type'] ?? 'General';
                final style = _typeStyles[type] ?? _typeStyles['General']!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E4EF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: style['bg'] as Color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${style['emoji']} $type',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: style['color'] as Color,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            _timeAgo(data['createdAt'] ?? ''),
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['title'] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            data['postedBy'] ?? 'Admin',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.grey),
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