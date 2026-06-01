import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  int _selectedPlanIndex = 1; // Default to Yearly

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Hàng tháng',
      'price': '99.000đ',
      'period': '/tháng',
      'description': 'Phù hợp để trải nghiệm ngắn hạn',
      'icon': Icons.calendar_today_outlined,
    },
    {
      'name': 'Hàng năm',
      'price': '699.000đ',
      'period': '/năm',
      'description': 'Tiết kiệm 40% so với gói tháng',
      'icon': Icons.auto_awesome_rounded,
      'isBestValue': true,
    },
    {
      'name': 'Vĩnh viễn',
      'price': '1.599.000đ',
      'period': '',
      'description': 'Sở hữu trọn đời, không gia hạn',
      'icon': Icons.all_inclusive_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('NihonGo! Premium', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 32),
            _buildBenefitSection(),
            const SizedBox(height: 32),
            _buildSectionHeader('CHỌN GÓI CỦA BẠN'),
            const SizedBox(height: 12),
            ..._plans.asMap().entries.map((entry) => _buildPlanCard(entry.key, entry.value)),
            const SizedBox(height: 32),
            _buildPromoCodeSection(),
            const SizedBox(height: 40),
            _buildPaymentButton(),
            const SizedBox(height: 20),
            const Text(
              'Hủy bất cứ lúc nào trong cài đặt App Store / Play Store',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 60),
          SizedBox(height: 16),
          Text(
            'Mở khóa toàn bộ sức mạnh',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Học không giới hạn, không quảng cáo và nhiều tính năng đặc biệt khác.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitSection() {
    return Column(
      children: [
        _buildBenefitItem(Icons.all_inclusive_rounded, 'Flashcards không giới hạn', 'Tạo bao nhiêu bộ thẻ tùy thích'),
        _buildBenefitItem(Icons.block_rounded, 'Không quảng cáo', 'Trải nghiệm học tập liền mạch'),
        _buildBenefitItem(Icons.offline_bolt_rounded, 'Chế độ ngoại tuyến', 'Học mọi lúc mọi nơi không cần mạng'),
        _buildBenefitItem(Icons.psychology_rounded, 'AI Tutor cá nhân', 'Phân tích lỗi sai và gợi ý bài học'),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildPlanCard(int index, Map<String, dynamic> plan) {
    bool isSelected = _selectedPlanIndex == index;
    bool isBestValue = plan['isBestValue'] ?? false;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(plan['icon'], color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('GIÁ TỐT NHẤT', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(plan['description'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan['price'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                if (plan['period'].isNotEmpty)
                  Text(plan['period'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Nhập mã giảm giá (nếu có)',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          border: InputBorder.none,
          suffixIcon: TextButton(
            onPressed: () {},
            child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showPaymentSuccess(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_rounded),
            SizedBox(width: 12),
            Text('THANH TOÁN QUA VNPAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text('Thành công!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Chúc mừng! Bạn hiện là thành viên Premium của NihonGo!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('BẮT ĐẦU HỌC', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
