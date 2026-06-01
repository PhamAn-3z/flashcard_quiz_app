import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            String greeting = "Chào bạn!";
            if (auth.user != null) {
              greeting = "Chào ${auth.user!.fullName.split(' ').first}!";
            }
            return Row(
              children: [
                Text(greeting, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(width: 8),
                if (auth.user?.isPremium == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsBoard(context),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Hoạt động học tập hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 10),
            _buildDailyProgress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsBoard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final stats = auth.userStats;
          if (stats == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(Icons.local_fire_department, '${stats.currentStreak} ngày', 'Chuỗi', Colors.orange),
                  _statItem(Icons.star, '${stats.totalExp} XP', 'Kinh nghiệm', AppColors.accent),
                  _statItem(Icons.emoji_events, 'Cấp ${stats.level}', 'Level', Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 20),
              // Level Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiến trình cấp độ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${stats.totalExp % 500} / 500 XP', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (stats.totalExp % 500) / 500.0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 36),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              title: 'Ôn tập Flashcard',
              icon: Icons.style,
              color: Colors.blue.shade100,
              iconColor: Colors.blue.shade700,
              onTap: () {
                // TODO: Navigate to Flashcard
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionCard(
              title: 'Làm Quiz ngay',
              icon: Icons.quiz,
              color: Colors.purple.shade100,
              iconColor: Colors.purple.shade700,
              onTap: () {
                // Simulate earning EXP when finishing a quiz
                context.read<AuthProvider>().addStudyProgress(50);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+50 XP!')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({required String title, required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 3),
              ),
              child: const Icon(Icons.check, color: AppColors.success, size: 30),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tuyệt vời!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Bạn đã hoàn thành mục tiêu học tập hôm nay.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
