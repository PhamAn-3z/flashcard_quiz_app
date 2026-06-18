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
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    // Nếu là Android Emulator thì dùng 10.0.2.2, các trường hợp khác (iOS/Desktop) dùng localhost
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (e) {
      // Phòng trường hợp Platform throw lỗi trên một số môi trường lạ
    }
    return 'http://localhost:8080/api/v1';
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

  // Deck Endpoints
  static String get decks => '$baseUrl/decks';
}
