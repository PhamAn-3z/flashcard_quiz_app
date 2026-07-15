import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Điều khoản & Bảo mật', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildSection(
              '1. Điều khoản sử dụng',
              'Bằng việc sử dụng NihonGo!, bạn đồng ý tuân thủ các quy định về việc tạo và chia sẻ nội dung lành mạnh. Không sử dụng ứng dụng cho mục đích vi phạm pháp luật hoặc đăng tải nội dung xúc phạm người khác.',
            ),
            _buildSection(
              '2. Quyền sở hữu nội dung',
              'Bạn sở hữu toàn bộ nội dung flashcard mình tạo ra. Khi bạn để chế độ "Công khai", các người dùng khác có thể xem và lưu bộ đề của bạn vào thư viện cá nhân của họ.',
            ),
            _buildSection(
              '3. Dữ liệu thu thập',
              'Chúng tôi thu thập email để xác thực tài khoản và các dữ liệu học tập (EXP, Streak, lịch sử thẻ) nhằm mục đích đồng bộ hóa quá trình học tập của bạn trên nhiều thiết bị.',
            ),
            _buildSection(
              '4. Bảo mật hình ảnh & âm thanh',
              'Các tệp đa phương tiện bạn tải lên (ảnh thẻ, âm thanh phát âm) được lưu trữ an toàn trên các hệ thống đám mây uy tín (Cloudinary/R2) và chỉ được truy cập theo quyền hạn của bộ đề.',
            ),
            _buildSection(
              '5. Quyền xóa dữ liệu',
              'Người dùng có quyền xóa vĩnh viễn tài khoản và toàn bộ dữ liệu học tập bất cứ lúc nào thông qua phần cài đặt tài khoản.',
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Cập nhật lần cuối: 15/07/2024',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cam kết bảo mật',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sự an toàn và riêng tư của bạn là ưu tiên hàng đầu của chúng tôi.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}
