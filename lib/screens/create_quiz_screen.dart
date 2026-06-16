import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  int _numQuestions = 5;
  final List<QuestionDraft> _questions = [];

  @override
  void initState() {
    super.initState();
    _updateQuestionCount(_numQuestions);
  }

  void _updateQuestionCount(int count) {
    setState(() {
      _numQuestions = count;
      if (_questions.length < count) {
        for (int i = _questions.length; i < count; i++) {
          _questions.add(QuestionDraft());
        }
      } else if (_questions.length > count) {
        _questions.removeRange(count, _questions.length);
      }
    });
  }

  void _submitQuiz() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Logic để lưu Quiz vào database hoặc gửi lên server sẽ ở đây
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang lưu bài Quiz...'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Tạo Quiz mới', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitQuiz,
            child: const Text('LƯU', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  const Text('Số lượng câu hỏi:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _numQuestions,
                      isExpanded: true,
                      items: List.generate(50, (index) => index + 1)
                          .map((e) => DropdownMenuItem(value: e, child: Text('$e câu')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _updateQuestionCount(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _numQuestions,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final draft = _questions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Nhập nội dung câu hỏi...',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập câu hỏi' : null,
            onSaved: (v) => draft.questionText = v ?? '',
          ),
          const SizedBox(height: 24),
          const Text('Các lựa chọn đáp án:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...List.generate(4, (optIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: draft.correctOptionIndex,
                    onChanged: (val) {
                      setState(() {
                        draft.correctOptionIndex = val!;
                      });
                    },
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Đáp án ${String.fromCharCode(65 + optIndex)}',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Nhập đáp án' : null,
                      onSaved: (v) => draft.options[optIndex] = v ?? '',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class QuestionDraft {
  String questionText = '';
  List<String> options = ['', '', '', ''];
  int correctOptionIndex = 0;
}
