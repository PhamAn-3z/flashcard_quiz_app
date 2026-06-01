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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 90), // Tăng từ 80 lên 90 để cân đối với thẻ mới
                  _buildSectionTitle('CHƯƠNG TRÌNH HỌC'),
                  const SizedBox(height: 12),
                  _buildMainActions(context),
                  const SizedBox(height: 32),
                  _buildSectionTitle('TIẾN ĐỘ HÔM NAY'),
                  const SizedBox(height: 12),
                  _buildModernGoalCard(context),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('DÀNH CHO BẠN'),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  _buildHorizontalDecks(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Decorative background pattern
            Positioned(
              right: -50,
              top: -20,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      String name = auth.user?.fullName.split(' ').first ?? "Học viên";
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Chào $name! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (auth.user?.isPremium == true) ...[
                                const SizedBox(width: 10),
                                _buildPremiumBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bạn đã sẵn sàng cho bài học mới chưa?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: _buildFloatingStatsCard(context),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA000)]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, size: 12, color: Colors.black),
          SizedBox(width: 2),
          Text(
            'PRO',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStatsCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20), // Dùng padding để tự co giãn
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final stats = auth.userStats;
              if (stats == null) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              return Column(
                mainAxisSize: MainAxisSize.min, // Ép Column chỉ chiếm diện tích tối thiểu cần thiết
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Streak', '${stats.currentStreak}', Icons.local_fire_department_rounded, Colors.orange),
                      _buildVerticalDivider(),
                      _buildStatItem('Kinh nghiệm', '${stats.totalExp}', Icons.star_rounded, AppColors.accent),
                      _buildVerticalDivider(),
                      _buildStatItem('Cấp độ', '${stats.level}', Icons.emoji_events_rounded, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tiến trình cấp độ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                            Text('${stats.totalExp % 500}/500 XP', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 24, width: 1.5, color: const Color(0xFFF1F5F9));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBigActionCard(
            context,
            'Ôn tập\nFlashcard',
            '50 từ mới',
            Icons.style_rounded,
            const Color(0xFFE3F2FD),
            const Color(0xFF1E88E5),
            () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBigActionCard(
            context,
            'Kiểm tra\nKiến thức',
            'Làm Quiz',
            Icons.extension_rounded,
            const Color(0xFFF3E5F5),
            const Color(0xFF9C27B0),
            () {
              context.read<AuthProvider>().addStudyProgress(50);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBigActionCard(BuildContext context, String title, String subtitle, IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.1)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGoalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: 0.8,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFF4ADE80), size: 24),
            ],
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Học tập chăm chỉ!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Bạn đã hoàn thành 80% mục tiêu ngày. Cố gắng lên!',
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDecks() {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildDeckCard('N5 Từ vựng', 'Giao tiếp cơ bản', '50 từ', Colors.blue),
          _buildDeckCard('Kanji N4', '20 chữ thông dụng', '20 chữ', Colors.orange),
          _buildDeckCard('Ngữ pháp N3', 'Cấu trúc Shinkanzen', '15 bài', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildDeckCard(String title, String subtitle, String count, Color accent) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_copy_rounded, color: accent, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(count, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
          ),
        ],
      ),
    );
  }
}
