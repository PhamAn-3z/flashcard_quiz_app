import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/deck_provider.dart';
import '../providers/auth_provider.dart';
import 'deck_overview_screen.dart';

class StudyHistoryScreen extends StatefulWidget {
  const StudyHistoryScreen({super.key});

  @override
  State<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().fetchRecentDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lịch sử học tập', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer2<DeckProvider, AuthProvider>(
        builder: (context, deckProvider, authProvider, child) {
          final historyItems = deckProvider.recentDecks;
          final userStats = authProvider.userStats;

          if (deckProvider.isLoading && historyItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildHistorySummary(userStats),
              if (historyItems.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Chưa có lịch sử học tập.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = historyItems[index];
                        return _buildHistoryItem(context, item);
                      },
                      childCount: historyItems.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistorySummary(dynamic userStats) {
    String exp = userStats?.totalExp?.toString() ?? '0';
    String streak = userStats?.currentStreak?.toString() ?? '0';
    String level = userStats?.level?.toString() ?? '1';

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(label: 'Tổng EXP', value: exp),
            _SummaryStat(label: 'Chuỗi ngày', value: streak),
            _SummaryStat(label: 'Cấp độ', value: level),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item) {
    // Backend returns flattened data in getRecentlyViewedDecks
    final String title = item['title'] ?? 'Bộ đề không tên';
    final String authorName = item['authorName'] ?? 'Ẩn danh';
    final dynamic deckId = item['deckId'];
    
    final DateTime studiedAt = DateTime.tryParse(item['lastStudiedAt'] ?? '') ?? DateTime.now();
    final dateFormat = DateFormat('dd/MM HH:mm');
    
    // Last session stats
    final lastSession = item['lastSession'] ?? {};
    final int learned = lastSession['learned'] ?? 0;
    final int reviewed = lastSession['reviewed'] ?? 0;
    final int duration = lastSession['seconds'] ?? 0;
    
    // Anki stats for navigation
    final Map<String, dynamic> ankiStats = {
      'newCount': item['newCount'] ?? 0,
      'learningCount': item['learningCount'] ?? 0,
      'dueCount': item['dueCount'] ?? 0,
    };

    String durationText = '';
    if (duration < 60) {
      durationText = '$duration giây';
    } else {
      durationText = '${(duration / 60).floor()} phút';
    }

    return GestureDetector(
      onTap: () {
        if (deckId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeckOverviewScreen(
                deckId: deckId,
                title: title,
                ankiStats: ankiStats,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Tác giả: $authorName', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(
                    'Đã học $learned thẻ • Ôn tập $reviewed thẻ',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(studiedAt)} • $durationText',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
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
