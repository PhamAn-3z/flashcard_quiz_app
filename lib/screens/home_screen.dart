import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'quiz_list_screen.dart';
import 'translation_screen.dart';
import 'deck_list_screen.dart';
import 'flashcard_learning_screen.dart';
import 'deck_overview_screen.dart';
import 'explore_decks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentDeckPage = 0;
  int _currentReviewPage = 0;
  int _currentHistoryPage = 0;
  final PageController _pageController = PageController();
  final PageController _reviewPageController = PageController();
  final PageController _historyPageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DeckProvider>();
      provider.fetchExploreDecks(filter: 'not_in_library');
      provider.fetchMyDecks();
      provider.fetchRecentDecks();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reviewPageController.dispose();
    _historyPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getStudyReminders(List<dynamic> decks) {
    List<dynamic> allDecks = [];
    void flatten(List<dynamic> list) {
      for (var d in list) {
        if (d.ankiStats.dueCount > 0 || d.ankiStats.learningCount > 0 || d.ankiStats.newCount > 0) {
          allDecks.add(d);
        }
        if (d.subDecks.isNotEmpty) flatten(d.subDecks);
      }
    }
    flatten(decks);
    allDecks.sort((a, b) {
      if (a.ankiStats.dueCount != b.ankiStats.dueCount) return b.ankiStats.dueCount.compareTo(a.ankiStats.dueCount);
      if (a.ankiStats.learningCount != b.ankiStats.learningCount) return b.ankiStats.learningCount.compareTo(a.ankiStats.learningCount);
      return b.ankiStats.newCount.compareTo(a.ankiStats.newCount);
    });
    return allDecks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildMaziiHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickMenu(context),
                  const SizedBox(height: 24),
                  _buildFloatingStatsCard(context),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Bộ đề đề xuất', showAll: true, onShowAll: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreDecksScreen()));
                  }),
                  const SizedBox(height: 16),
                  _buildRecommendedDecks(context),
                  const SizedBox(height: 32),
                  
                  _buildReviewReminders(context),
                  
                  _buildRecentStudyHistory(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaziiHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true, // Cho phép app bar giãn ra khi kéo xuống
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NihonGo!', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              Text('Học tiếng Nhật thật dễ dàng', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),
        Consumer<AuthProvider>(builder: (context, auth, _) => GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: const Padding(
            padding: EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: Icon(Icons.person_rounded, color: Colors.white, size: 18)),
          ),
        )),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ExploreDecksScreen(initialSearchQuery: value.trim())));
                  _searchController.clear();
                }
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bộ đề cộng đồng...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                icon: GestureDetector(
                  onTap: () {
                    final val = _searchController.text.trim();
                    if (val.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ExploreDecksScreen(initialSearchQuery: val)));
                      _searchController.clear();
                    }
                  },
                  child: const Icon(Icons.search_rounded, color: AppColors.primary),
                ),
                suffixIcon: const Icon(Icons.camera_alt_rounded, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentStudyHistory(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, provider, _) {
        final list = provider.recentDecks.take(8).toList();
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('LỊCH SỬ HỌC TẬP'),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _historyPageController,
                onPageChanged: (index) => setState(() => _currentHistoryPage = index),
                itemCount: list.length,
                itemBuilder: (context, index) => _buildHistoryCard(context, list[index]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(list.length, (index) => Container(
                width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _currentHistoryPage == index ? AppColors.primary : Colors.black.withOpacity(0.1)),
              )),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic data) {
    // Xử lý dữ liệu lồng nhau từ API /decks/recent
    final deckInfo = data['decks'] ?? {};
    final authorInfo = deckInfo['author'] ?? {};
    final String title = data['title'] ?? deckInfo['title'] ?? 'Bộ đề không tên';
    final String authorName = authorInfo['username'] ?? data['authorName'] ?? "Ẩn danh";
    
    // Thống kê phiên học
    final int learned = data['cards_learned'] ?? 0;
    final int reviewed = data['cards_reviewed'] ?? 0;
    final int totalInSession = learned + reviewed;
    
    // Thống kê tổng quan bộ đề để tính progress bar (nếu có)
    final stats = data['ankiStats'] ?? deckInfo['ankiStats'];
    final int totalCards = stats?['totalCount'] ?? deckInfo['total_cards'] ?? 10;
    final progress = totalCards > 0 ? (learned / totalCards).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        final deckId = data['deckId'] ?? data['deck_id'] ?? deckInfo['id'];
        if (deckId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DeckOverviewScreen(
            deckId: deckId, title: title,
            ankiStats: stats ?? {'newCount': 0, 'learningCount': 0, 'dueCount': 0},
          )));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Stack(
          children: [
            Positioned(right: 0, bottom: 0, top: 20, width: MediaQuery.of(context).size.width * 0.4, child: Opacity(opacity: 0.08, child: Transform.rotate(angle: -0.1, child: const Icon(Icons.collections_bookmark_rounded, size: 100, color: Colors.blue)))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Tác giả: $authorName', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress, child: Container(decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10))))),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Vừa học $totalInSession thẻ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    Text(_formatLastStudied(DateTime.tryParse(data['studied_at'] ?? data['lastStudiedAt'] ?? '')), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewReminders(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, provider, _) {
        final reminders = _getStudyReminders(provider.myDecks);
        if (reminders.isEmpty) return const SizedBox.shrink();
        final displayList = reminders.take(7).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('TIẾN ĐỘ HỌC TẬP', showAll: true, onShowAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeckListScreen(initialFilter: 'Đến hạn')));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _reviewPageController,
                onPageChanged: (index) => setState(() => _currentReviewPage = index),
                itemCount: displayList.length,
                itemBuilder: (context, index) => _buildReviewCard(context, displayList[index]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayList.length, (index) => Container(
                width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _currentReviewPage == index ? AppColors.primary : Colors.black.withOpacity(0.1)),
              )),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic deck) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DeckOverviewScreen(
          deckId: deck.id, title: deck.title,
          ankiStats: {'newCount': deck.ankiStats.newCount, 'learningCount': deck.ankiStats.learningCount, 'dueCount': deck.ankiStats.dueCount},
        )));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, child: SizedBox(width: 60, height: 60, child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: const Size(60, 60), painter: DeckProgressPainter(newCount: deck.ankiStats.newCount, learningCount: deck.ankiStats.learningCount, dueCount: deck.ankiStats.dueCount, masteredCount: deck.masteredCount, totalCount: deck.effectiveTotalCards)),
              Text('${deck.effectiveTotalCards > 0 ? ((deck.masteredCount / deck.effectiveTotalCards) * 100).floor() : 0}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]))),
            Positioned(top: 0, right: 0, child: Row(children: [
              _buildMiniStat(deck.ankiStats.newCount, Colors.blue),
              const SizedBox(width: 6),
              _buildMiniStat(deck.ankiStats.learningCount, Colors.red),
              const SizedBox(width: 6),
              _buildMiniStat(deck.ankiStats.dueCount, Colors.green),
            ])),
            Positioned(left: 0, bottom: 0, right: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(deck.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.history_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('Học lần cuối: ${_formatLastStudied(deck.lastStudiedAt)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ]),
            ])),
          ],
        ),
      ),
    );
  }

  String _formatLastStudied(DateTime? date) {
    if (date == null) return 'Chưa học lần nào';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }

  Widget _buildMiniStat(int count, Color color) {
    return Container(
      width: 32, padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text('$count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildRecommendedDecks(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, deckProvider, _) {
        final list = deckProvider.exploreDecks;
        if (deckProvider.isLoading && list.isEmpty) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        final displayList = list.where((deck) => deck.isInLibrary == false).take(8).toList();
        if (displayList.isEmpty) return const Center(child: Text('Không có bộ đề đề xuất mới.', style: TextStyle(color: Colors.grey, fontSize: 12)));
        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentDeckPage = index),
                itemCount: displayList.length,
                itemBuilder: (context, index) => _buildDeckCard(context, displayList[index]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayList.length, (index) => Container(
                width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _currentDeckPage == index ? AppColors.primary : Colors.black.withOpacity(0.1)),
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeckCard(BuildContext context, dynamic deck) {
    final stats = deck.stats;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DeckOverviewScreen(
          deckId: deck.id, title: deck.title,
          ankiStats: {'newCount': deck.ankiStats.newCount, 'learningCount': deck.ankiStats.learningCount, 'dueCount': deck.ankiStats.dueCount},
        )));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, child: Container(
              padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
            )),
            Positioned(top: 0, right: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${stats?.totalViews ?? 0} lượt xem', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('${stats?.viewsToday ?? 0} học hôm nay 🔥', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
            ])),
            Positioned(left: 0, bottom: 0, right: 0, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(deck.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('${deck.totalCards} thẻ • Tác giả: ${deck.author?.username ?? "Ẩn danh"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${stats?.favoritesCount ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                ]),
              ),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showAll = false, VoidCallback? onShowAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (showAll) GestureDetector(onTap: onShowAll, child: const Text('Tất cả', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildMenuIcon(Icons.style_rounded, 'Flashcard', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeckListScreen()))),
        _buildMenuIcon(Icons.translate_rounded, 'Dịch', Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslationScreen()))),
      ]),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]));
  }

  Widget _buildFloatingStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24)),
      child: Consumer<AuthProvider>(builder: (context, auth, _) {
        final stats = auth.userStats;
        if (stats == null) return const SizedBox();
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tiến độ học tập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${stats.totalExp} XP', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (stats.totalExp % 500) / 500, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent), minHeight: 8)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildStatSmall('${stats.currentStreak}', 'Streak', Icons.local_fire_department_rounded, Colors.orange),
            _buildStatSmall('${stats.level}', 'Cấp độ', Icons.emoji_events_rounded, Colors.amber),
          ]),
        ]);
      }),
    );
  }

  Widget _buildStatSmall(String value, String label, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}

class DeckProgressPainter extends CustomPainter {
  final int newCount;
  final int learningCount;
  final int dueCount;
  final int masteredCount;
  final int totalCount;

  DeckProgressPainter({
    required this.newCount,
    required this.learningCount,
    required this.dueCount,
    required this.masteredCount,
    required this.totalCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCount <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 5.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    paint.color = Colors.black.withOpacity(0.05);
    canvas.drawCircle(center, radius - strokeWidth / 2, paint);
    double startAngle = -1.5708;
    double masteredSweep = (masteredCount / totalCount) * 2 * 3.14159;
    double newSweep = (newCount / totalCount) * 2 * 3.14159;
    double learningSweep = (learningCount / totalCount) * 2 * 3.14159;
    double dueSweep = (dueCount / totalCount) * 2 * 3.14159;
    if (masteredSweep > 0) { paint.color = Colors.tealAccent.shade700; canvas.drawArc(rect, startAngle, masteredSweep, false, paint); startAngle += masteredSweep; }
    if (newSweep > 0) { paint.color = Colors.blue; canvas.drawArc(rect, startAngle, newSweep, false, paint); startAngle += newSweep; }
    if (learningSweep > 0) { paint.color = Colors.orange; canvas.drawArc(rect, startAngle, learningSweep, false, paint); startAngle += learningSweep; }
    if (dueSweep > 0) { paint.color = Colors.green; canvas.drawArc(rect, startAngle, dueSweep, false, paint); }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
