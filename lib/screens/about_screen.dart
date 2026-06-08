import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
            _buildInfoTile(Icons.code_rounded, 'Phát triển bởi', 'NihonGo Team'),
            _buildInfoTile(Icons.email_outlined, 'Liên hệ hỗ trợ', 'support@nihongo.com'),
            _buildInfoTile(Icons.language_rounded, 'Website', 'www.nihongo-app.com'),
            const SizedBox(height: 60),
            const Text(
              '© 2024 NihonGo! All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
