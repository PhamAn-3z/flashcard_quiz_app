import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  bool _streakReminder = true;
  bool _newContentNotify = true;
  bool _studyReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  bool get streakReminder => _streakReminder;
  bool get newContentNotify => _newContentNotify;
  bool get studyReminder => _studyReminder;
  TimeOfDay get reminderTime => _reminderTime;

  NotificationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _streakReminder = prefs.getBool('streakReminder') ?? true;
    _newContentNotify = prefs.getBool('newContentNotify') ?? true;
    _studyReminder = prefs.getBool('studyReminder') ?? true;
    
    final hour = prefs.getInt('reminderHour') ?? 20;
    final minute = prefs.getInt('reminderMinute') ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    
    notifyListeners();
  }

  Future<void> toggleStreakReminder(bool value) async {
    _streakReminder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streakReminder', value);
    notifyListeners();
  }

  Future<void> toggleNewContentNotify(bool value) async {
    _newContentNotify = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('newContentNotify', value);
    notifyListeners();
  }

  Future<void> toggleStudyReminder(bool value) async {
    _studyReminder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('studyReminder', value);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderHour', time.hour);
    await prefs.setInt('reminderMinute', time.minute);
    notifyListeners();
  }
}
