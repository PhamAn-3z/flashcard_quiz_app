import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class NotificationProvider with ChangeNotifier {
  String? _token;
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  // Settings
  bool _studyReminderEnabled = true;
  String _studyReminderTime = "20:00";
  List<int> _studyReminderDays = [1, 2, 3, 4, 5, 6, 7];
  bool _subExpiryNotify = true;
  bool _isLoadingSettings = false;

  // Notifications List
  List<AppNotification> _notifications = [];
  bool _isLoadingNotifications = false;

  // Getters
  bool get studyReminderEnabled => _studyReminderEnabled;
  String get studyReminderTime => _studyReminderTime;
  List<int> get studyReminderDays => _studyReminderDays;
  bool get subExpiryNotify => _subExpiryNotify;
  bool get isLoadingSettings => _isLoadingSettings;
  
  List<AppNotification> get notifications => _notifications;
  bool get isLoadingNotifications => _isLoadingNotifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void updateToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      fetchSettings();
      fetchNotifications();
    }
  }

  // --- SETTINGS API ---
  Future<void> fetchSettings() async {
    if (_token == null) return;
    _isLoadingSettings = true;
    notifyListeners();

    try {
      final response = await _dio.get('/notification-settings');
      final data = response.data['data'] ?? response.data;
      
      if (data != null) {
        _studyReminderEnabled = data['study_reminder_enabled'] == 1 || data['study_reminder_enabled'] == true;
        _studyReminderTime = data['study_reminder_time'] ?? "20:00";
        _studyReminderDays = List<int>.from(data['study_reminder_days'] ?? [1, 2, 3, 4, 5, 6, 7]);
        _subExpiryNotify = data['sub_expiry_notify'] == 1 || data['sub_expiry_notify'] == true;
      }
    } catch (e) {
      debugPrint("Error fetching notification settings: $e");
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings({
    bool? enabled,
    String? time,
    List<int>? days,
    bool? subNotify,
  }) async {
    if (_token == null) return false;

    try {
      final response = await _dio.put('/notification-settings', data: {
        'study_reminder_enabled': enabled ?? _studyReminderEnabled,
        'study_reminder_time': time ?? _studyReminderTime,
        'study_reminder_days': days ?? _studyReminderDays,
        'sub_expiry_notify': subNotify ?? _subExpiryNotify,
      });

      if (response.statusCode == 200) {
        if (enabled != null) _studyReminderEnabled = enabled;
        if (time != null) _studyReminderTime = time;
        if (days != null) _studyReminderDays = days;
        if (subNotify != null) _subExpiryNotify = subNotify;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error updating notification settings: $e");
    }
    return false;
  }

  // --- NOTIFICATIONS API ---
  Future<void> fetchNotifications() async {
    if (_token == null) return;
    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final response = await _dio.get('/notifications');
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
      for (var n in _notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
    }
  }

  Future<void> registerFcmToken(String fcmToken) async {
    if (_token == null) return;
    try {
      await _dio.post('/notifications/register-token', data: {'fcm_token': fcmToken});
      debugPrint("FCM Token registered successfully");
    } catch (e) {
      debugPrint("Error registering FCM token: $e");
    }
  }
}
