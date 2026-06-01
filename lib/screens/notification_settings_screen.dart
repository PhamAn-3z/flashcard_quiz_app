import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifyProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra light gray/blue background
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "LỊCH HỌC & NHẮC NHỞ",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildModernSwitch(
                title: 'Duy trì chuỗi (Streak)',
                subtitle: 'Nhắc khi bạn sắp mất chuỗi học tập',
                value: notifyProvider.streakReminder,
                onChanged: (val) => notifyProvider.toggleStreakReminder(val),
                icon: Icons.local_fire_department_rounded,
                accentColor: Colors.orange,
              ),
              _buildModernSwitch(
                title: 'Nhắc nhở hàng ngày',
                subtitle: 'Theo sát kế hoạch học tập đã đề ra',
                value: notifyProvider.studyReminder,
                onChanged: (val) => notifyProvider.toggleStudyReminder(val),
                icon: Icons.calendar_today_rounded,
                accentColor: AppColors.primary,
              ),
              if (notifyProvider.studyReminder)
                _buildTimePickerTile(
                  context,
                  time: notifyProvider.reminderTime,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: notifyProvider.reminderTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) notifyProvider.setReminderTime(picked);
                  },
                ),
            ]),
            const SizedBox(height: 32),
            const Text(
              "CẬP NHẬT ỨNG DỤNG",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildModernSwitch(
                title: 'Nội dung & Bài học mới',
                subtitle: 'Thông báo khi có từ vựng, ngữ pháp mới',
                value: notifyProvider.newContentNotify,
                onChanged: (val) => notifyProvider.toggleNewContentNotify(val),
                icon: Icons.auto_awesome_rounded,
                accentColor: Colors.purple,
              ),
            ]),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Lưu cấu hình',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(BuildContext context, {required TimeOfDay time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thời gian nhắc', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Row(
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
