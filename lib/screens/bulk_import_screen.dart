import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';
import 'membership_screen.dart';

class BulkImportScreen extends StatefulWidget {
  final bool returnDataOnly; // Thêm flag để biết là trả về data hay tự import
  final int existingCount;   // Số lượng thẻ đã có sẵn

  const BulkImportScreen({
    super.key, 
    this.returnDataOnly = false,
    this.existingCount = 0,
  });

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _rawTextController = TextEditingController();
  final TextEditingController _customTermDelimiterController =
      TextEditingController();
  final TextEditingController _customCardDelimiterController =
      TextEditingController();

  String _publicStatus = 'public';
  int? _parentId;

  String _termDelimiter = '.';
  String _cardDelimiter = '\n';

  bool _isLoading = false;
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _previewHeaders = [];
  List<Map<String, String>> _previewRows = [];
  Map<String, dynamic>? _limitData;
  int _truncatedCount = 0; // Số thẻ bị cắt bớt

  @override
  void initState() {
    super.initState();
    _checkLimit();
    _rawTextController.addListener(_onTextChanged);
  }

  Future<void> _checkLimit() async {
    final data = await context.read<DeckProvider>().fetchMembershipLimit();
    if (mounted) {
      setState(() => _limitData = data);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _rawTextController.dispose();
    _titleController.dispose();
    _customTermDelimiterController.dispose();
    _customCardDelimiterController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _updatePreview);
  }

  void _updatePreview() {
    final rawText = _rawTextController.text;
    if (rawText.isEmpty) {
      if (mounted) {
        setState(() {
          _previewRows = [];
          _previewHeaders = [];
        });
      }
      return;
    }

    final effectiveCardDelim = _cardDelimiter == 'custom'
        ? _customCardDelimiterController.text
        : _cardDelimiter;
    final effectiveTermDelim = _termDelimiter == 'custom'
        ? _customTermDelimiterController.text
        : _termDelimiter;

    if (effectiveCardDelim.isEmpty || effectiveTermDelim.isEmpty) return;

    // 1. Tách văn bản thô thành các dòng
    List<String> rawLines = rawText.split(effectiveCardDelim);
    rawLines.removeWhere((line) => line.trim().isEmpty);

    // Tính toán số lượng thẻ tối đa có thể thêm vào (Tổng không quá 200)
    final int maxAllowedNew = (200 - widget.existingCount).clamp(0, 200);
    int truncated = 0;

    if (rawLines.length > maxAllowedNew) {
      truncated = rawLines.length - maxAllowedNew;
      rawLines = rawLines.sublist(0, maxAllowedNew);
    }

    if (rawLines.isEmpty) {
      if (mounted) {
        setState(() {
          _previewRows = [];
          _previewHeaders = [];
          _truncatedCount = 0;
        });
      }
      return;
    }

    // 2. Tìm số lượng group tối đa (Giới hạn 6) - Chỉ quét 100 dòng đầu để lấy cấu trúc cho nhanh
    int maxFoundGroups = 0;
    int scanLimit = min(rawLines.length, 100);
    for (int i = 0; i < scanLimit; i++) {
      int count = rawLines[i].split(effectiveTermDelim).length;
      if (count > maxFoundGroups) maxFoundGroups = count;
    }
    int groupCount = min(maxFoundGroups, 6);

    // 3. Sinh headers động
    List<Map<String, dynamic>> headers = [];
    for (int i = 0; i < groupCount; i++) {
      int pos = i + 1;
      String key = "group_$pos";
      String currentName = "Nhóm $pos";
      for (var h in _previewHeaders) {
        if (h['key'] == key) {
          currentName = h['name'];
          break;
        }
      }
      headers.add({"key": key, "name": currentName, "position": pos});
    }

    // 4. Sinh rows động (Map theo headers)
    List<Map<String, String>> rows = [];
    for (String line in rawLines) {
      List<String> parts = line.split(effectiveTermDelim);
      Map<String, String> rowMap = {};

      for (int i = 0; i < groupCount; i++) {
        String key = "group_${i + 1}";
        if (i < parts.length) {
          if (i == groupCount - 1 && parts.length > groupCount) {
            rowMap[key] = parts.sublist(i).join(effectiveTermDelim).trim();
          } else {
            rowMap[key] = parts[i].trim();
          }
        } else {
          rowMap[key] = "";
        }
      }
      rows.add(rowMap);
    }

    if (mounted) {
      setState(() {
        _previewHeaders = headers;
        _previewRows = rows;
        _truncatedCount = truncated;
      });
    }
  }

  void _editHeaderName(Map<String, dynamic> header) {
    final controller = TextEditingController(text: header['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đổi tên nhóm ${header['position']}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Tên nhóm mới', hintText: 'Ví dụ: Từ vựng, Nghĩa...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
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
    if (widget.returnDataOnly) {
      // Trả về dữ liệu cho CreateDeckScreen
      final result = {
        'headers': _previewHeaders.map((h) => h['name'] as String).toList(),
        'rows': _previewRows.map((row) {
          return _previewHeaders
              .map((h) => row[h['key']]?.toString() ?? "")
              .toList();
        }).toList(),
      };
      Navigator.pop(context, result);
      return;
    }

    // Logic tạo deck mới như cũ
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tiêu đề bộ đề')));
      return;
    }
    if (_previewRows.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung')));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nhập thành công!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final decks = context.watch<DeckProvider>().decks;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.returnDataOnly ? 'Nhập dữ liệu' : 'Nhập hàng loạt'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_limitData != null && _limitData!['canCreateMore'] == false && !widget.returnDataOnly)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Bạn đã đạt giới hạn bộ đề. Vui lòng nâng cấp PRO để tiếp tục.', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipScreen()));
                      },
                      child: const Text('NÂNG CẤP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            if (!widget.returnDataOnly) ...[
              const Text('1. Cấu hình Bộ đề',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Tiêu đề bộ đề', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _publicStatus,
                      decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'public', child: Text('Public')),
                        DropdownMenuItem(
                            value: 'private', child: Text('Private')),
                      ],
                      onChanged: (val) => setState(() => _publicStatus = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _parentId,
                      decoration: const InputDecoration(
                          labelText: 'Thư mục', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Mặc định')),
                        ...decks.map((d) => DropdownMenuItem(
                            value: d.id, child: Text(d.title))),
                      ],
                      onChanged: (val) => setState(() => _parentId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            const Text('Khung nhập liệu văn bản thô',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _rawTextController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "Dán dữ liệu từ Excel hoặc Quizlet vào đây...",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cấu hình ký tự phân tách',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                const Text('Giữa cột: '),
                _buildDelimRadio('.', 'Dấu chấm', true),
                _buildDelimRadio(',', 'Dấu phẩy', true),
                _buildDelimRadio('custom', 'Khác', true),
              ],
            ),
            if (_termDelimiter == 'custom')
              TextField(
                controller: _customTermDelimiterController,
                decoration: const InputDecoration(hintText: 'Ký tự cột'),
                onChanged: (_) => _updatePreview(),
              ),
            const SizedBox(height: 20),
            const Text('Xem trước',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_truncatedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dữ liệu quá dài! Đã tự động cắt bớt $_truncatedCount thẻ để không vượt quá giới hạn 200 thẻ.',
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            if (_previewRows.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Chưa có dữ liệu phân tích',
                    style: TextStyle(color: Colors.grey)),
              ))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                  columns: [
                    const DataColumn(
                        label: Text('#',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue))),
                    ..._previewHeaders
                        .map((h) => DataColumn(
                              label: InkWell(
                                onTap: () => _editHeaderName(h),
                                child: Row(
                                  children: [
                                    Text(h['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue)),
                                    const Icon(Icons.edit,
                                        size: 14, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ],
                  rows: _previewRows.asMap().entries.take(10).map((entry) {
                    int idx = entry.key;
                    var r = entry.value;
                    return DataRow(
                        cells: [
                          DataCell(Text('Thẻ ${idx + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 12))),
                          ..._previewHeaders
                              .map((h) => DataCell(Text(r[h['key']] ?? "")))
                              .toList(),
                        ]);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: (_limitData != null && _limitData!['canCreateMore'] == false && !widget.returnDataOnly) ? null : _handleImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.returnDataOnly
                          ? 'XÁC NHẬN NHẬP DỮ LIỆU'
                          : 'TẠO BỘ ĐỀ VÀ TẢI LÊN'),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDelimRadio(String value, String label, bool isTerm) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: isTerm ? _termDelimiter : _cardDelimiter,
          onChanged: (v) => setState(() {
            if (isTerm)
              _termDelimiter = v!;
            else
              _cardDelimiter = v!;
            _updatePreview();
          }),
        ),
        Text(label),
      ],
    );
  }
}
