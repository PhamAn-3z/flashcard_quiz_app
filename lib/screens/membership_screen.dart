import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../models/membership_plan.dart';
import 'package:intl/intl.dart';
import 'payment_status_screen.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  int? _selectedPlanId;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchMembershipPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('NihonGo! Premium', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: transactionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 32),
                  _buildBenefitSection(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('CHỌN GÓI CỦA BẠN'),
                  const SizedBox(height: 12),
                  if (transactionProvider.plans.isEmpty)
                    const Text('Hiện không có gói hội viên nào khả dụng.')
                  else
                    ...transactionProvider.plans.map((plan) => _buildPlanCard(plan)),
                  const SizedBox(height: 32),
                  _buildPromoCodeSection(),
                  const SizedBox(height: 40),
                  _buildPaymentButton(authProvider, transactionProvider),
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
            color: AppColors.primary.withOpacity(0.3),
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
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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

  Widget _buildPlanCard(MembershipPlan plan) {
    bool isSelected = _selectedPlanId == plan.id;
    bool isBestValue = plan.name.toLowerCase().contains('năm');

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan.id),
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
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                plan.durationDays >= 365 ? Icons.auto_awesome_rounded : Icons.calendar_today_outlined,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('GIÁ TỐT NHẤT', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(plan.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormat.format(plan.price), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                Text(plan.durationDays >= 9999 ? 'Vĩnh viễn' : '/${plan.durationDays} ngày', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

  Widget _buildPaymentButton(AuthProvider auth, TransactionProvider trans) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedPlanId == null ? null : () => _handlePayment(auth, trans),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_rounded),
            const SizedBox(width: 12),
            Text(
              trans.isLoading ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN THANH TOÁN',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment(AuthProvider auth, TransactionProvider trans) async {
    if (_selectedPlanId == null || auth.user == null) return;

    final plan = trans.plans.firstWhere((p) => p.id == _selectedPlanId);

    final result = await trans.createPaymentRequest(
      userId: auth.user!.id,
      membershipId: plan.id,
      amount: plan.price,
    );

    if (result != null) {
      final String url = result['url'];
      final String receiptId = result['receiptId'];

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Đang xử lý thanh toán'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Vui lòng hoàn tất thanh toán tại cửa sổ mới.'),
                SizedBox(height: 20),
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Hệ thống sẽ tự động cập nhật sau khi bạn thanh toán thành công.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ĐÓNG', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                child: const Text('MỞ LẠI TRANG THANH TOÁN'),
              ),
            ],
          ),
        );

        // Mở trang VNPay ngay lập tức
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

        // Bắt đầu Polling: Cứ 3 giây kiểm tra status 1 lần
        bool paid = false;
        for (int i = 0; i < 20; i++) { // Thử trong vòng 60 giây
          await Future.delayed(const Duration(seconds: 3));
          paid = await trans.checkReceiptStatus(receiptId, auth.user!.id);
          if (paid) break;
        }

        if (mounted) {
          Navigator.pop(context); // Đóng dialog chờ
          
          // Chuyển hướng sang trang kết quả
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentStatusScreen(isSuccess: paid),
            ),
          );
        }
      }
    }
  }
}
