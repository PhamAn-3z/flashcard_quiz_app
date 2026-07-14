import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Kết quả trả về sau khi upload lên Cloudinary
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  CloudinaryUploadResult({required this.secureUrl, required this.publicId});
}

/// Dịch vụ xử lý tải file lên Cloudinary.
/// Hỗ trợ cả Unsigned Upload (cũ) và Signed Upload (mới qua backend).
class CloudinaryService {
  CloudinaryService();

  /// Hàm tải file lên Cloudinary sử dụng Signature từ backend.
  /// [file]: File cần tải lên.
  /// [signatureData]: Dữ liệu chữ ký nhận được từ API /images/generate-signature.
  /// [resourceType]: 'image', 'video' (cho audio), hoặc 'raw'.
  Future<CloudinaryUploadResult?> uploadFile({
    required File file,
    required Map<String, dynamic> signatureData,
    String resourceType = 'image',
  }) async {
    try {
      final String cloudName = signatureData['cloudName'];
      final String apiKey = signatureData['apiKey'];
      final String signature = signatureData['signature'];
      final String timestamp = signatureData['timestamp'].toString();
      final String uploadPreset = signatureData['uploadPreset'];

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Các trường bắt buộc cho Signed Upload
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['upload_preset'] = uploadPreset;
      
      // Thêm file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? secureUrl = data['secure_url'];
        final String? publicId = data['public_id'];
        
        if (secureUrl != null && publicId != null) {
          debugPrint('✅ Tải lên Cloudinary thành công ($resourceType): $secureUrl');
          return CloudinaryUploadResult(secureUrl: secureUrl, publicId: publicId);
        }
        return null;
      } else {
        debugPrint('❌ Lỗi Cloudinary API ($resourceType): ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi không xác định khi tải file ($resourceType): ${e.toString()}');
      return null;
    }
  }

  /// (DEPRECATED) Unsigned Upload - Hạn chế sử dụng vì lý do bảo mật.
  Future<String?> uploadImage(File imageFile, {String cloudName = '', String uploadPreset = ''}) async {
    try {
      if (cloudName.isEmpty || uploadPreset.isEmpty) return null;
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
