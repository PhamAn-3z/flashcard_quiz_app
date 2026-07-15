import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppColors {
  static const Color primary = Color(0xFF1E88E5); // Mazii-like blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color cardBg = Colors.white;
}

class ApiConstants {
  static const String supabaseUrl = "https://xdekwfqnhrohydgejhdk.supabase.co";
  static const String supabaseKey = "sb_publishable_Mk288brWkRYpm14YH2xAOw_sAb6qcyW";
  
  // Tự động xác định Base URL dựa trên môi trường chạy
  static String get baseUrl {
    // 1. Cấu hình IP (Hãy thay bằng IP máy tính của bạn khi dùng điện thoại thật chung WiFi)
    const String localIp = "192.168.1.10"; 
    
    // 2. Cấu hình Tunnel (Chỉ dán link vào đây khi dùng điện thoại thật khác mạng/4G)
    const String tunnelUrl = ""; 

    // ƯU TIÊN 1: Nếu là Máy ảo Android (Emulator) -> Luôn dùng 10.0.2.2 để ổn định nhất
    // Lưu ý: kIsWeb phải check trước Platform
    if (!kIsWeb) {
      try {
        // Một số môi trường không hỗ trợ Platform.isAndroid nên cần bọc try-catch
        if (Platform.isAndroid) {
          // Bạn có thể đổi dòng dưới thành true nếu muốn dùng Tunnel trên máy ảo
          bool useTunnelOnEmulator = false; 
          if (!useTunnelOnEmulator) {
             return 'http://10.0.2.2:8080/api/v1';
          }
        }
      } catch (e) {}
    }

    // ƯU TIÊN 2: Nếu có Tunnel Url -> Dùng cho điện thoại thật
    if (tunnelUrl.isNotEmpty && (tunnelUrl.contains(".lhr.life") || tunnelUrl.contains("ngrok"))) {
      return '$tunnelUrl/api/v1';
    }

    if (kIsWeb) return 'http://localhost:8080/api/v1';

    // ƯU TIÊN 3: Dùng IP nội bộ cho điện thoại thật chung WiFi
    return 'http://$localIp:8080/api/v1';
  }

  // Chuyển sang dạng getter để luôn lấy giá trị baseUrl mới nhất
  static String get memberships => '$baseUrl/memberships';
  static String get receipts => '$baseUrl/receipts';
  static String get vnpay => '$baseUrl/vnpay';

  // Auth Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';

  // User Endpoints
  static String get profile => '$baseUrl/user/profile';
  static String get transactions => '$baseUrl/user/transactions';

  // Notification Endpoints
  static String get notifications => '$baseUrl/notifications';
  static String get notificationSettings => '$baseUrl/notification-settings';
  static String get registerFcmToken => '$baseUrl/notifications/register-token';

  // Deck Endpoints
  static String get decks => '$baseUrl/decks';

  // Admin Endpoints
  static String get adminUsers => '$baseUrl/admin/users';
  static String get adminReceipts => '$baseUrl/receipts';
  static String get adminCleanupReceipts => '$baseUrl/receipts/cleanup';
}
