import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import 'admin_user_management_screen.dart';
import 'admin_transaction_management_screen.dart';
import 'admin_membership_management_screen.dart';
import 'admin_promo_code_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              // Quay về màn hình gốc trước khi đăng xuất để xóa stack
              Navigator.of(context).popUntil((route) => route.isFirst);
              auth.logout();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(auth.user?.fullName ?? 'Admin'),
            const SizedBox(height: 30),
            const Text(
              "QUẢN LÝ HỆ THỐNG",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            _buildAdminMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'Chào mừng, $name',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Bạn có toàn quyền kiểm soát hệ thống NihonGo!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildMenuCard(
          context,
          title: 'Người dùng',
          subtitle: 'Cảnh cáo & Ban',
          icon: Icons.people_alt_rounded,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserManagementScreen())),
        ),
        _buildMenuCard(
          context,
          title: 'Tài chính',
          subtitle: 'Hóa đơn & Cleanup',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTransactionManagementScreen())),
        ),
        _buildMenuCard(
          context,
          title: 'Gói thành viên',
          subtitle: 'Giá & Quyền lợi',
          icon: Icons.card_membership_rounded,
          color: Colors.pink,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMembershipManagementScreen())),
        ),
        _buildMenuCard(
          context,
          title: 'Mã khuyến mãi',
          subtitle: 'Giảm giá & Coupon',
          icon: Icons.confirmation_number_rounded,
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPromoCodeManagementScreen())),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
