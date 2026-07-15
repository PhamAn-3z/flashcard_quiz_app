import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final List<String> _daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final notifyProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Cài đặt nhắc nhở',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: notifyProvider.isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("NHẮC NHỞ HỌC TẬP"),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _buildModernSwitch(
                      title: 'Bật nhắc nhở',
                      subtitle: 'Nhận thông báo khi đến giờ học',
                      value: notifyProvider.studyReminderEnabled,
                      onChanged: (val) => notifyProvider.updateSettings(enabled: val),
                      icon: Icons.alarm_rounded,
                      accentColor: AppColors.primary,
                    ),
                    if (notifyProvider.studyReminderEnabled) ...[
                      const Divider(height: 1, indent: 70),
                      _buildTimePickerTile(
                        context,
                        timeStr: notifyProvider.studyReminderTime,
                        onTap: () async {
                          final timeParts = notifyProvider.studyReminderTime.split(':');
                          final initialTime = TimeOfDay(
                            hour: int.parse(timeParts[0]),
                            minute: int.parse(timeParts[1]),
                          );
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                          );
                          if (picked != null) {
                            final formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                            notifyProvider.updateSettings(time: formattedTime);
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 70),
                      _buildDaysPicker(notifyProvider),
                    ]
                  ]),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('LƯU CÀI ĐẶT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
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
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
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
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(BuildContext context, {required String timeStr, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: const SizedBox(width: 44, child: Icon(Icons.access_time_rounded, color: Colors.grey)),
      title: const Text('Thời gian nhắc', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(timeStr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDaysPicker(NotificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Text('Lặp lại vào các ngày', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final isSelected = provider.studyReminderDays.contains(dayNum);
              return GestureDetector(
                onTap: () {
                  List<int> newDays = List.from(provider.studyReminderDays);
                  if (isSelected) {
                    if (newDays.length > 1) newDays.remove(dayNum);
                  } else {
                    newDays.add(dayNum);
                  }
                  provider.updateSettings(days: newDays);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _daysOfWeek[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
