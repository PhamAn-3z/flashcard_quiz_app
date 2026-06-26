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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildMaziiHeader(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchOverlay(context),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickMenu(context),
                      const SizedBox(height: 24),
                      _buildFloatingStatsCard(context),
                      const SizedBox(height: 32),
                      _buildSectionHeader('NỘI DUNG HÀNG NGÀY'),
                      const SizedBox(height: 12),
                      _buildDailyContentGrid(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('BỘ THẺ ĐỀ XUẤT'),
                      const SizedBox(height: 12),
                      _buildHorizontalDecks(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaziiHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text('NihonGo!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('Học tiếng Nhật thật dễ dàng', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                    ),
                    const SizedBox(width: 4),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm từ vựng, Hán tự, ngữ pháp...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
            icon: Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: Icon(Icons.camera_alt_rounded, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuIcon(Icons.style_rounded, 'Flashcard', Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DeckListScreen()));
          }),
          _buildMenuIcon(Icons.translate_rounded, 'Dịch', Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslationScreen()));
          }),
          _buildMenuIcon(Icons.psychology_rounded, 'Quiz', Colors.red, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizListScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDailyContentGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildDailyCard('Từ vựng ngày', '学習 (Gakushuu)', 'Học tập, nghiên cứu', Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDailyCard('Hán tự ngày', '強 (Cường)', 'Mạnh mẽ, sức mạnh', Colors.orange),
        ),
      ],
    );
  }

  Widget _buildDailyCard(String label, String main, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(main, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFloatingStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final stats = auth.userStats;
          if (stats == null) return const SizedBox();
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiến độ học tập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${stats.totalExp} XP', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (stats.totalExp % 500) / 500,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatSmall('${stats.currentStreak}', 'Streak', Icons.local_fire_department_rounded, Colors.orange),
                  _buildStatSmall('${stats.level}', 'Cấp độ', Icons.emoji_events_rounded, Colors.amber),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatSmall(String value, String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
        const Text('Tất cả', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHorizontalDecks(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, deckProvider, _) {
        final list = deckProvider.publicDecks;
        if (deckProvider.isLoading && list.isEmpty) return const Center(child: CircularProgressIndicator());
        
        if (list.isEmpty) {
          return const Center(child: Text('Không có bộ thẻ công khai.', style: TextStyle(color: Colors.grey, fontSize: 12)));
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final deck = list[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardLearningScreen(deckId: deck.id, deckName: deck.title)));
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.folder_rounded, color: Colors.blue.withOpacity(0.5), size: 30),
                      const Spacer(),
                      Text(deck.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMiniDot(Colors.blue, deck.ankiStats.newCount),
                          const SizedBox(width: 4),
                          _buildMiniDot(Colors.red, deck.ankiStats.learningCount),
                          const SizedBox(width: 4),
                          _buildMiniDot(Colors.green, deck.ankiStats.dueCount),
                          if (deck.totalCards == 0) 
                             Text('0 thẻ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMiniDot(Color color, int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
