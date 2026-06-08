import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hướng dẫn sử dụng', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildGuideSection(
            '1. Cách học Flashcard',
            'Chọn một bộ thẻ từ danh sách, sau đó nhấn nút "Học". Bạn có thể chạm vào thẻ để xem mặt sau và vuốt để chuyển thẻ.',
            Icons.style_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '2. Theo dõi tiến trình',
            'Ứng dụng sẽ tự động ghi lại chuỗi ngày học (Streak) và điểm kinh nghiệm (EXP) của bạn mỗi khi hoàn thành bài học.',
            Icons.local_fire_department_rounded,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '3. Nâng cấp Premium',
            'Vào mục Membership để mở khóa toàn bộ các bộ thẻ nâng cao và loại bỏ quảng cáo hoàn toàn.',
            Icons.workspace_premium_rounded,
            Colors.amber,
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '4. Cài đặt thông báo',
            'Đừng quên bật thông báo nhắc nhở học tập trong phần cài đặt để duy trì thói quen học tiếng Nhật hàng ngày nhé!',
            Icons.notifications_active_rounded,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
