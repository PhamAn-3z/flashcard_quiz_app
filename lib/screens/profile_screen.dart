import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'notification_settings_screen.dart';
import 'membership_screen.dart';
import 'transaction_history_screen.dart';
import 'help_guide_screen.dart';
import 'about_screen.dart';
import 'study_history_screen.dart';
import 'edit_profile_screen.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF64B5F6)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 16),
                            ),
                          ),
                        ),
                        if (user?.isPremium == true)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                              child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 18),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (user?.fullName != null && user!.fullName.isNotEmpty) 
                          ? user.fullName 
                          : 'Học viên NihonGo',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    if (user?.username != null)
                      Text(
                        '@${user!.username}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CÀI ĐẶT HỆ THỐNG",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _buildModernMenu(context, [
                    _menuItem(
                      icon: Icons.notifications_active_rounded,
                      color: Colors.blue,
                      title: 'Thông báo & Nhắc nhở',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                    ),
                    _menuItem(
                      icon: Icons.workspace_premium_rounded,
                      color: Colors.amber.shade700,
                      title: 'Gói Membership',
                      trailing: user?.isPremium == true 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: const Text('PRO', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MembershipScreen()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text(
                    "HỖ TRỢ & THÔNG TIN",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _buildModernMenu(context, [
                    _menuItem(
                      icon: Icons.person_outline_rounded,
                      color: Colors.blueAccent,
                      title: 'Thông tin người dùng',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                    ),
                    _menuItem(
                      icon: Icons.history_rounded, 
                      color: Colors.teal, 
                      title: 'Lịch sử học tập', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyHistoryScreen())),
                    ),
                    _menuItem(
                      icon: Icons.receipt_long_rounded, 
                      color: Colors.orange, 
                      title: 'Lịch sử giao dịch', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen())),
                    ),
                    _menuItem(
                      icon: Icons.help_outline_rounded, 
                      color: Colors.indigo, 
                      title: 'Hướng dẫn sử dụng', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpGuideScreen())),
                    ),
                    _menuItem(
                      icon: Icons.info_outline_rounded, 
                      color: Colors.grey, 
                      title: 'Về ứng dụng', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        auth.logout();
                        // Consumer trong main.dart sẽ tự động đưa user về LoginScreen
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenu(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem({required IconData icon, required Color color, required String title, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
