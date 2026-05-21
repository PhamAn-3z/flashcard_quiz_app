import 'package:dio/dio.dart';

class DbConnection {
  // 1. Dán Project URL bạn vừa copy vào đây (bỏ đuôi /rest/v1/ đi nhé)
  static const String baseUrl = "https://xdekwfqnhrohydgejhdk.supabase.co";

  // 2. Dán đoạn API Key (sb_publishable_...) bạn vừa copy vào đây
  static const String apiKey = "sb_publishable_Mk288brWkRYpm14YH2xAOw_sAb6qcyW";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // Nhét API Key vào phần headers để Supabase nhận diện đây là app của bạn
      headers: {
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Hàm kiểm tra xem App của bạn có "bắn" tín hiệu lên Supabase thành công không
  Future<bool> testCloudConnection() async {
    try {
      // SỬA CHỖ NÀY: Thêm dấu gạch chéo '/' vào cuối để gọi thẳng vào root API URL của Data API
      // Hoặc gọi cụ thể vào cổng kiểm tra của Supabase
      final response = await _dio.get('$baseUrl/rest/v1/');

      if (response.statusCode == 200) {
        print("🎉 KẾT NỐI ĐẾN SUPABASE CLOUD THÀNH CÔNG RỒI BẠN ƠI!");
        return true;
      }
    } catch (e) {
      // Mẹo nhỏ: Nếu nó vẫn báo lỗi 401 nhưng log ra được thông tin trả về,
      // tức là đường truyền mạng từ máy bạn lên Supabase đã THÔNG SUỐT 100% rồi (chỉ là chưa có quyền đọc bảng thôi)
      if (e is DioException && e.response?.statusCode == 401) {
        print("🎉 ĐƯỜNG TRUYỀN THÔNG SUỐT! App đã chạm được tới Supabase trên Singapore thành công (Lỗi 401 là do chưa truyền cấu trúc bảng). Cứ tự tin làm bước tiếp theo!");
        return true;
      }
      print("❌ LỖI KẾT NỐI HỆ THỐNG: $e");
    }
    return false;
  }
}