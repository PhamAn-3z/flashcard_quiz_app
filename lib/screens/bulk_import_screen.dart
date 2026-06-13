import 'dart:math';
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

  List<Map<String, dynamic>> _previewHeaders = [];
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
        _previewHeaders = [];
      });
      return;
    }

    final effectiveCardDelim = _cardDelimiter == 'custom' ? _customCardDelimiterController.text : _cardDelimiter;
    final effectiveTermDelim = _termDelimiter == 'custom' ? _customTermDelimiterController.text : _termDelimiter;

    if (effectiveCardDelim.isEmpty || effectiveTermDelim.isEmpty) return;

    // 1. Tách văn bản thô thành các dòng
    List<String> rawLines = rawText.split(effectiveCardDelim);
    rawLines.removeWhere((line) => line.trim().isEmpty);

    if (rawLines.isEmpty) {
      setState(() {
        _previewRows = [];
        _previewHeaders = [];
      });
      return;
    }

    // 2. Tìm số lượng group tối đa (Giới hạn 6)
    int maxFoundGroups = 0;
    for (String line in rawLines) {
      int count = line.split(effectiveTermDelim).length;
      if (count > maxFoundGroups) maxFoundGroups = count;
    }
    int groupCount = min(maxFoundGroups, 6);

    // 3. Sinh headers động (Giữ lại tên đã sửa của người dùng nếu có)
    List<Map<String, dynamic>> headers = [];
    for (int i = 0; i < groupCount; i++) {
      int pos = i + 1;
      String key = "group_$pos";
      
      // Tìm xem key này đã tồn tại trong previewHeaders hiện tại chưa để giữ lại "name"
      String currentName = "Group $pos";
      for (var h in _previewHeaders) {
        if (h['key'] == key) {
          currentName = h['name'];
          break;
        }
      }

      headers.add({
        "key": key,
        "name": currentName,
        "position": pos,
      });
    }

    // 4. Sinh rows động map theo headers
    List<Map<String, String>> rows = [];
    for (String line in rawLines) {
      List<String> parts = line.split(effectiveTermDelim);
      Map<String, String> rowMap = {};
      
      for (int i = 0; i < groupCount; i++) {
        String key = "group_${i + 1}";
        if (i < parts.length) {
          // Nếu là group cuối cùng, gom hết phần còn lại của line (đề phòng nội dung chứa delimiter)
          if (i == groupCount - 1 && parts.length > groupCount) {
             rowMap[key] = parts.sublist(i).join(effectiveTermDelim).trim();
          } else {
             rowMap[key] = parts[i].trim();
          }
        } else {
          rowMap[key] = ""; // Ô trống nếu dòng thiếu cột
        }
      }
      rows.add(rowMap);
    }

    setState(() {
      _previewHeaders = headers;
      _previewRows = rows;
    });
  }

  void _editHeaderName(Map<String, dynamic> header) {
    final controller = TextEditingController(text: header['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đổi tên ${header['key']}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên nhóm mới', hintText: 'Ví dụ: Kanji, Hiragana...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                header['name'] = controller.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
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
      headers: _previewHeaders,
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
                ...decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.title))),
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
                hintText: "Dán dữ liệu từ Excel hoặc Quizlet vào đây...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('3. Cấu hình Ký tự phân tách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Giữa các cột trong 1 thẻ:'),
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
            const Text('Giữa các tấm thẻ:'),
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
            const Text('Mẹo: Nhấn vào tên cột để đổi tên nhóm (vd: Kanji, Nghĩa...)', style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            if (_previewRows.isEmpty)
              const Text('Không có nội dung để xem trước', style: TextStyle(color: Colors.grey))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: _previewHeaders.map((h) => DataColumn(
                    label: InkWell(
                      onTap: () => _editHeaderName(h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(h['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14, color: Colors.blue),
                        ],
                      ),
                    ),
                  )).toList(),
                  rows: _previewRows.map((r) => DataRow(
                    cells: _previewHeaders.map((h) => DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(r[h['key']] ?? "", overflow: TextOverflow.ellipsis),
                      )
                    )).toList()
                  )).toList(),
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
