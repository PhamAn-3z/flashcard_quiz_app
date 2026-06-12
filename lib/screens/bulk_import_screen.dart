import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _rawTextController = TextEditingController();
  final TextEditingController _customTermDelimiterController = TextEditingController();
  final TextEditingController _customCardDelimiterController = TextEditingController();

  String _publicStatus = 'public';
  int? _parentId;

  String _termDelimiter = '\t';
  String _cardDelimiter = '\n';

  bool _isLoading = false;

  List<Map<String, String>> _previewRows = [];

  @override
  void initState() {
    super.initState();
    _rawTextController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    _titleController.dispose();
    _customTermDelimiterController.dispose();
    _customCardDelimiterController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final rawText = _rawTextController.text;
    if (rawText.isEmpty) {
      setState(() {
        _previewRows = [];
      });
      return;
    }

    final effectiveCardDelim = _cardDelimiter == 'custom' ? _customCardDelimiterController.text : _cardDelimiter;
    final effectiveTermDelim = _termDelimiter == 'custom' ? _customTermDelimiterController.text : _termDelimiter;

    if (effectiveCardDelim.isEmpty || effectiveTermDelim.isEmpty) return;

    List<String> rawLines = rawText.split(effectiveCardDelim);
    rawLines.removeWhere((line) => line.trim().isEmpty);

    List<Map<String, String>> rows = [];
    for (String line in rawLines) {
      List<String> parts = line.split(effectiveTermDelim);
      if (parts.length >= 2) {
        rows.add({
          "term": parts[0].trim(),
          "definition": parts.sublist(1).join(effectiveTermDelim).trim(),
        });
      }
    }

    setState(() {
      _previewRows = rows;
    });
  }

  Future<void> _handleImport() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề bộ đề')));
      return;
    }
    if (_previewRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung thẻ')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<DeckProvider>().bulkImport(
      deckTitle: _titleController.text,
      publicStatus: _publicStatus,
      parentId: _parentId,
      headers: [
        {"key": "term", "name": "Thuật ngữ", "position": 1},
        {"key": "definition", "name": "Định nghĩa", "position": 2}
      ],
      rows: _previewRows,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo bộ đề thành công!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo bộ đề thất bại.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final decks = context.watch<DeckProvider>().decks;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhập hàng loạt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Cấu hình Bộ đề', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề bộ đề', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _publicStatus,
              decoration: const InputDecoration(labelText: 'Trạng thái chia sẻ', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
              ],
              onChanged: (val) => setState(() => _publicStatus = val!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              value: _parentId,
              decoration: const InputDecoration(labelText: 'Vị trí phân cấp (Cha)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Không có')),
                ...decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
              ],
              onChanged: (val) => setState(() => _parentId = val),
            ),
            const SizedBox(height: 24),
            const Text('2. Khung nhập liệu văn bản thô', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _rawTextController,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: "Từ 1 [Tab] Định nghĩa 1\nTừ 2 [Tab] Định nghĩa 2",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('3. Cấu hình Ký tự phân tách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Giữa thuật ngữ và định nghĩa:'),
            Row(
              children: [
                Radio<String>(value: '\t', groupValue: _termDelimiter, onChanged: (v) => setState(() { _termDelimiter = v!; _updatePreview(); })),
                const Text('Tab'),
                Radio<String>(value: ',', groupValue: _termDelimiter, onChanged: (v) => setState(() { _termDelimiter = v!; _updatePreview(); })),
                const Text('Dấu phẩy'),
                Radio<String>(value: 'custom', groupValue: _termDelimiter, onChanged: (v) => setState(() { _termDelimiter = v!; _updatePreview(); })),
                const Text('Tùy chỉnh'),
              ],
            ),
            if (_termDelimiter == 'custom')
              TextField(
                controller: _customTermDelimiterController,
                decoration: const InputDecoration(hintText: 'Nhập ký tự phân tách cột'),
                onChanged: (_) => _updatePreview(),
              ),
            const SizedBox(height: 10),
            const Text('Giữa các thẻ:'),
            Row(
              children: [
                Radio<String>(value: '\n', groupValue: _cardDelimiter, onChanged: (v) => setState(() { _cardDelimiter = v!; _updatePreview(); })),
                const Text('Dòng mới'),
                Radio<String>(value: ';', groupValue: _cardDelimiter, onChanged: (v) => setState(() { _cardDelimiter = v!; _updatePreview(); })),
                const Text('Dấu chấm phẩy'),
                Radio<String>(value: 'custom', groupValue: _cardDelimiter, onChanged: (v) => setState(() { _cardDelimiter = v!; _updatePreview(); })),
                const Text('Tùy chỉnh'),
              ],
            ),
            if (_cardDelimiter == 'custom')
              TextField(
                controller: _customCardDelimiterController,
                decoration: const InputDecoration(hintText: 'Nhập ký tự phân tách hàng'),
                onChanged: (_) => _updatePreview(),
              ),
            const SizedBox(height: 24),
            Text('4. Xem trước dữ liệu trực tiếp (${_previewRows.length} thẻ)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            if (_previewRows.isEmpty)
              const Text('Không có nội dung để xem trước', style: TextStyle(color: Colors.grey))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Thuật ngữ')),
                    DataColumn(label: Text('Định nghĩa')),
                  ],
                  rows: _previewRows.map((r) => DataRow(cells: [
                    DataCell(Text(r['term']!)),
                    DataCell(Text(r['definition']!)),
                  ])).toList(),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleImport,
                      child: const Text('Tạo bộ đề và tải lên'),
                    ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Center(child: Text("Hệ thống đang khởi tạo ma trận dữ liệu, vui lòng không đóng ứng dụng...", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey))),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
