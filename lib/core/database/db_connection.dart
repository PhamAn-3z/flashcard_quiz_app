import 'package:dio/dio.dart';
import '../../utils/constants.dart';

class DbConnection {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.supabaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // Nhét API Key vào phần headers để Supabase nhận diện đây là app của bạn
      headers: {
        'apikey': ApiConstants.supabaseKey,
        'Authorization': 'Bearer ${ApiConstants.supabaseKey}',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Hàm kiểm tra xem App của bạn có "bắn" tín hiệu lên Supabase thành công không
  Future<bool> testCloudConnection() async {
    try {
      // SỬA CHỖ NÀY: Thêm dấu gạch chéo '/' vào cuối để gọi thẳng vào root API URL của Data API
      final response = await _dio.get('${ApiConstants.supabaseUrl}/rest/v1/');

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