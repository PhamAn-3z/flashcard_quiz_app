import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _result = "";
  bool _isJpToVi = true; // Hướng dịch: JP -> VI hoặc VI -> JP

  void _translate() {
    // Giả lập logic dịch thuật (Trong thực tế sẽ gọi API Google Translate hoặc tương tự)
    setState(() {
      if (_inputController.text.isEmpty) {
        _result = "";
        return;
      }
      _result = "Đây là kết quả dịch giả lập cho: \"${_inputController.text}\". \n\n(Bạn có thể tích hợp Google Translate API tại đây)";
    });
  }

  void _swapLanguage() {
    setState(() {
      _isJpToVi = !_isJpToVi;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dịch thuật NihonGo!', style: TextStyle(fontWeight: FontWeight.w800)),
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
                    onChanged: (val) => _translate(),
                  ),
                  if (_inputController.text.isNotEmpty)
                    IconButton(
                      onPressed: () => setState(() { _inputController.clear(); _result = ""; }),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kết quả dịch
            if (_result.isNotEmpty)
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
                        Icon(Icons.translate_rounded, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text('BẢN DỊCH', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result,
                      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {}, // Logic copy
                          icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                        ),
                        IconButton(
                          onPressed: () {}, // Logic phát âm
                          icon: const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 20),
                        ),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
