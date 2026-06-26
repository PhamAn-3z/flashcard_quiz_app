import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ xử lý tải ảnh lên Cloudinary bằng cơ chế REST API (Unsigned Upload).
/// Giải pháp này hoàn toàn hỗ trợ Null Safety và không phụ thuộc vào các thư viện cũ.
class CloudinaryService {
  final String _cloudName;
  final String _uploadPreset;

  CloudinaryService()
      : _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
        _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '' {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      debugPrint('⚠️ CẢNH BÁO: CLOUDINARY_CLOUD_NAME hoặc CLOUDINARY_UPLOAD_PRESET chưa được cấu hình trong .env');
    }
  }

  /// Hàm tải file ảnh vật lý lên Cloudinary thông qua REST API.
  /// imageFile: File ảnh từ bộ nhớ máy.
  /// Trả về: secureUrl (đường dẫn ảnh bảo mật) nếu thành công, ngược lại trả về null.
  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      // 1. Tạo request đa phần (Multipart Request)
      var request = http.MultipartRequest('POST', uri);
      
      // 2. Thêm các trường dữ liệu cần thiết cho Unsigned Upload
      request.fields['upload_preset'] = _uploadPreset;
      
      // 3. Thêm file ảnh vào request
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // 4. Gửi request và nhận phản hồi
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? secureUrl = data['secure_url'];
        debugPrint('✅ Tải ảnh lên Cloudinary thành công: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('❌ Lỗi Cloudinary API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi không xác định khi tải ảnh: ${e.toString()}');
      return null;
    }
  }
}
