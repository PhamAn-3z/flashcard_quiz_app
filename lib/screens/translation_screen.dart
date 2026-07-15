import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  
  String _result = "";
  bool _isLoading = false;
  bool _isJpToVi = true; 

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _result = "");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _dio.post(
        '/translate',
        data: {
          'text': text,
          'source_lang': _isJpToVi ? 'ja' : 'vi',
          'target_lang': _isJpToVi ? 'vi' : 'ja',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _result = response.data['translated_text'] ?? "Không có kết quả dịch.";
        });
      }
    } on DioException catch (e) {
      setState(() {
        _result = "Lỗi: ${e.response?.data['message'] ?? 'Không thể kết nối đến máy chủ dịch'}";
      });
    } catch (e) {
      setState(() {
        _result = "Đã xảy ra lỗi ngoài ý muốn: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _swapLanguage() {
    setState(() {
      _isJpToVi = !_isJpToVi;
      // Dịch lại ngay khi đổi ngôn ngữ nếu có text
      if (_inputController.text.isNotEmpty) {
        _translate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dịch thuật AI', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Thanh chuyển đổi ngôn ngữ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isJpToVi ? 'Tiếng Nhật' : 'Tiếng Việt', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: _swapLanguage,
                    icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 20),
                  Text(_isJpToVi ? 'Tiếng Việt' : 'Tiếng Nhật', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Ô nhập liệu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: _isJpToVi ? 'Nhập văn bản tiếng Nhật...' : 'Nhập văn bản tiếng Việt...',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_inputController.text.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(() { _inputController.clear(); _result = ""; }),
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                        ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _translate,
                        icon: _isLoading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.translate_rounded, size: 18),
                        label: const Text('DỊCH NGAY'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kết quả dịch
            if (_result.isNotEmpty || _isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text('BẢN DỊCH AI', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: Colors.white70))
                    else
                      Text(
                        _result,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
