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
  String _studyReminderTime = "19:00";
  List<int> _studyReminderDays = [1, 2, 3, 4, 5, 6, 7];
  
  bool _streakReminderEnabled = true;
  String _streakReminderTime = "20:00";
  
  bool _subExpiryNotify = true;
  bool _promoNotify = true;
  bool _isLoadingSettings = false;

  // Notifications List
  List<AppNotification> _notifications = [];
  bool _isLoadingNotifications = false;

  // Getters
  bool get studyReminderEnabled => _studyReminderEnabled;
  String get studyReminderTime => _studyReminderTime;
  List<int> get studyReminderDays => _studyReminderDays;
  
  bool get streakReminderEnabled => _streakReminderEnabled;
  String get streakReminderTime => _streakReminderTime;
  
  bool get subExpiryNotify => _subExpiryNotify;
  bool get promoNotify => _promoNotify;
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
      final response = await _dio.get('notification-settings');
      final data = response.data['data'] ?? response.data;
      
      if (data != null) {
        _studyReminderEnabled = data['study_reminder'] == 1 || data['study_reminder'] == true;
        _studyReminderTime = data['study_reminder_time'] ?? "19:00";
        _studyReminderDays = List<int>.from(data['study_reminder_days'] ?? [1, 2, 3, 4, 5, 6, 7]);
        
        _streakReminderEnabled = data['streak_reminder'] == 1 || data['streak_reminder'] == true;
        _streakReminderTime = data['streak_reminder_time'] ?? "20:00";
        
        _subExpiryNotify = data['sub_expiry_notify'] == 1 || data['sub_expiry_notify'] == true;
        _promoNotify = data['promo_notify'] == 1 || data['promo_notify'] == true;
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
    bool? streakEnabled,
    String? streakTime,
    bool? subExpiryNotify,
    bool? promoNotify,
  }) async {
    if (_token == null) return false;

    try {
      // Cập nhật study-reminder
      if (enabled != null || time != null || days != null) {
        await _dio.put('notification-settings/study-reminder', data: {
          'is_enabled': enabled ?? _studyReminderEnabled,
          'time': time ?? _studyReminderTime,
          'days': days ?? _studyReminderDays,
        });
        if (enabled != null) _studyReminderEnabled = enabled;
        if (time != null) _studyReminderTime = time;
        if (days != null) _studyReminderDays = days;
      }

      // Cập nhật các cài đặt khác (Giả định backend có endpoint chung hoặc hỗ trợ update từng phần)
      // Ở đây ta gọi endpoint chung nếu có, hoặc lặp lại pattern trên
      if (streakEnabled != null || streakTime != null || subExpiryNotify != null || promoNotify != null) {
        await _dio.put('notification-settings/update', data: {
          'streak_reminder': streakEnabled ?? _streakReminderEnabled,
          'streak_reminder_time': streakTime ?? _streakReminderTime,
          'sub_expiry_notify': subExpiryNotify ?? _subExpiryNotify,
          'promo_notify': promoNotify ?? _promoNotify,
        });
        if (streakEnabled != null) _streakReminderEnabled = streakEnabled;
        if (streakTime != null) _streakReminderTime = streakTime;
        if (subExpiryNotify != null) _subExpiryNotify = subExpiryNotify;
        if (promoNotify != null) _promoNotify = promoNotify;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error updating notification settings: $e");
    }
    return false;
  }

  Future<bool> sendTestNotification() async {
    if (_token == null) return false;
    try {
      await _dio.post('notifications/test');
      return true;
    } catch (e) {
      debugPrint("Error sending test notification: $e");
      return false;
    }
  }

  // --- NOTIFICATIONS API ---
  Future<void> fetchNotifications() async {
    if (_token == null) return;
    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final response = await _dio.get('notifications');
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
      await _dio.put('notifications/$id/read');
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
      await _dio.put('notifications/read-all');
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
      await _dio.post('notifications/register-token', data: {'fcm_token': fcmToken});
      debugPrint("FCM Token registered successfully");
    } catch (e) {
      debugPrint("Error registering FCM token: $e");
    }
  }
}
