import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class StudyHistoryScreen extends StatelessWidget {
  const StudyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for study history
    final List<Map<String, dynamic>> historyItems = [
      {
        'type': 'flashcard',
        'title': 'Ôn tập Flashcard N5',
        'subtitle': 'Đã hoàn thành 20/20 thẻ',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'exp': '+50 EXP',
        'color': Colors.blue,
        'icon': Icons.style_rounded,
      },
      {
        'type': 'quiz',
        'title': 'Kiểm tra Từ vựng N4',
        'subtitle': 'Đạt điểm tuyệt đối: 10/10',
        'time': DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        'exp': '+100 EXP',
        'color': Colors.purple,
        'icon': Icons.extension_rounded,
      },
      {
        'type': 'flashcard',
        'title': 'Học từ vựng Kanji N3',
        'subtitle': 'Đã học thêm 15 từ mới',
        'time': DateTime.now().subtract(const Duration(days: 2, hours: 1)),
        'exp': '+40 EXP',
        'color': Colors.orange,
        'icon': Icons.menu_book_rounded,
      },
      {
        'type': 'quiz',
        'title': 'Mini Quiz: Trợ từ',
        'subtitle': 'Hoàn thành bài kiểm tra nhanh',
        'time': DateTime.now().subtract(const Duration(days: 3, hours: 10)),
        'exp': '+25 EXP',
        'color': Colors.teal,
        'icon': Icons.timer_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lịch sử học tập', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          _buildHistorySummary(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = historyItems[index];
                  return _buildHistoryItem(item);
                },
                childCount: historyItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySummary() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(label: 'Tổng giờ học', value: '12.5h'),
            _SummaryStat(label: 'Bài học', value: '48'),
            _SummaryStat(label: 'Từ vựng', value: '350'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final dateFormat = DateFormat('dd/MM HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(item['icon'], color: item['color'], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(item['subtitle'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(item['time']),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item['exp'],
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
