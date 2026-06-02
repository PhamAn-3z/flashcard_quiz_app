import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernHeader(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Khối nền xanh nối tiếp AppBar
                Container(
                  width: double.infinity,
                  height: 20,
                  color: AppColors.primary,
                ),
                // Thẻ thống kê và nội dung bên dưới
                Transform.translate(
                  offset: const Offset(0, -20), // Đẩy thẻ lên trên để tạo hiệu ứng "floating"
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildFloatingStatsCard(context),
                        const SizedBox(height: 24),
                        _buildMainContent(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  String name = auth.user?.fullName.split(' ').first ?? "Học viên";
                  return Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Chào $name! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (auth.user?.isPremium == true) ...[
                        const SizedBox(width: 8),
                        _buildPremiumBadge(),
                      ],
                    ],
                  );
                },
              ),
              const Text(
                'Hôm nay bạn muốn học gì?',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
      ),
    );
  }

  Widget _buildFloatingStatsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final stats = auth.userStats;
          if (stats == null) return const Center(child: CircularProgressIndicator());
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Streak', '${stats.currentStreak}', Icons.local_fire_department_rounded, Colors.orange),
                  _buildStatItem('Exp', '${stats.totalExp}', Icons.star_rounded, AppColors.accent),
                  _buildStatItem('Cấp', '${stats.level}', Icons.emoji_events_rounded, Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiến trình', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                  Text('${stats.totalExp % 500}/500 XP', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (stats.totalExp % 500) / 500,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CHƯƠNG TRÌNH HỌC'),
        const SizedBox(height: 12),
        _buildMainActions(context),
        const SizedBox(height: 32),
        _buildSectionTitle('TIẾN ĐỘ HÔM NAY'),
        const SizedBox(height: 12),
        _buildModernGoalCard(context),
        const SizedBox(height: 32),
        _buildSectionTitle('DÀNH CHO BẠN'),
        const SizedBox(height: 12),
        _buildHorizontalDecks(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.2),
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard('Ôn tập\nFlashcard', Icons.style_rounded, const Color(0xFFE3F2FD), const Color(0xFF1E88E5)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard('Kiểm tra\nKiến thức', Icons.extension_rounded, const Color(0xFFF3E5F5), const Color(0xFF9C27B0)),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildModernGoalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF4ADE80), size: 30),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Học tập chăm chỉ!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                Text('Bạn đã hoàn thành 80% mục tiêu ngày.', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDecks() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildDeckItem('N5 Từ vựng', '50 từ', Colors.blue),
          _buildDeckItem('Kanji N4', '20 chữ', Colors.orange),
          _buildDeckItem('Ngữ pháp N3', '15 bài', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildDeckItem(String title, String count, Color accent) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.folder_copy_rounded, color: accent, size: 24),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          Text(count, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
