import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Về ứng dụng', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.auto_stories_rounded, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'NihonGo!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            const Text(
              'NihonGo! là ứng dụng học tiếng Nhật qua Flashcard và Quiz thông minh, giúp bạn ghi nhớ từ vựng và Kanji một cách hiệu quả nhất theo phương pháp lặp lại ngắt quãng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
            ),
            const SizedBox(height: 40),
            
            // Thông tin chi tiết từ Footer
            _buildFooterInfoItem(
              Icons.location_on_rounded, 
              'Trụ sở Hà Nội:', 
              'Khu Công Nghệ Cao Hòa Lạc, CT03, Hòa Lạc, Hà Nội',
              onTap: () => _launchURL('https://www.google.com/maps/search/?api=1&query=Trường+Đại+học+FPT+Hà+Nội'),
            ),
            const SizedBox(height: 16),
            _buildFooterInfoItem(
              Icons.location_on_rounded, 
              'Chi nhánh TP. HCM:', 
              '7 Đ. D1, Tăng Nhơn Phú, TP. Thủ Đức, Hồ Chí Minh',
              onTap: () => _launchURL('https://www.google.com/maps/search/?api=1&query=Trường+Đại+học+FPT+TP.HCM'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFooterInfoItem(
                    Icons.phone_iphone_rounded, 
                    'Hotline:', 
                    '0822.858.489',
                    onTap: () => _launchURL('tel:0822858489'),
                  ),
                ),
                Expanded(
                  child: _buildFooterInfoItem(
                    Icons.mail_outline_rounded, 
                    'Email:', 
                    'anphamgm2k5@gmail.com',
                    onTap: () => _launchURL('mailto:anphamgm2k5@gmail.com'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFooterInfoItem(
              Icons.access_time_rounded, 
              'Giờ làm việc:', 
              'Thứ 2 - Thứ 7 (08:30 - 17:30)',
            ),
            
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              child: const Text('Điều khoản & Bảo mật', style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2024 NihonGo Team. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterInfoItem(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onTap != null ? AppColors.primary : AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (url.startsWith('mailto:') || url.startsWith('tel:')) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}
