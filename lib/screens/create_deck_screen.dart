import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:io' show File;
import 'dart:typed_data';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'bulk_import_screen.dart';
import '../data/services/cloudinary_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// Class định nghĩa cấu trúc dữ liệu cho từng ô trong ma trận
/// Giúp kiểm soát kiểu dữ liệu chặt chẽ, tránh lỗi subtype
class CellData {
  final TextEditingController controller;
  String? imageUrl;
  String? localPreviewPath; // Thêm biến lưu đường dẫn cục bộ
  String? audioUrl;

  CellData({
    required this.controller,
    this.imageUrl,
    this.localPreviewPath,
    this.audioUrl,
  });

  void dispose() {
    controller.dispose();
  }
}

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  // 1. THÔNG TIN CHUNG BỘ ĐỀ
  final Map<String, dynamic> dbContext = {
    'title': TextEditingController(),
    'description': TextEditingController(),
  };

  // 2. CẤU HÌNH CỘT (HEADERS)
  List<Map<String, String>> headers = [
    {'id': 'kanji', 'label': 'THUẬT NGỮ'},
    {'id': 'hiragana', 'label': 'ĐỊNH NGHĨA'},
  ];

  // 3. DỮ LIỆU MA TRẬN 2 CHIỀU: Sử dụng Class CellData để đảm bảo an toàn
  List<Map<String, CellData>> matrixRows = [];

  String _publicStatus = 'public';
  int? _parentId;
  bool _isSaving = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingUrl;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _addNewRow();
    _addNewRow();

    // Lắng nghe sự kiện kết thúc âm thanh để cập nhật UI
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    (dbContext['title'] as TextEditingController).dispose();
    (dbContext['description'] as TextEditingController).dispose();
    for (var row in matrixRows) {
      for (var cell in row.values) {
        cell.dispose();
      }
    }
    super.dispose();
  }

  // --- LOGIC XỬ LÝ MA TRẬN ---

  void _addNewColumn(String label) {
    if (label.isEmpty) return;
    setState(() {
      final String newId = 'col_${DateTime.now().millisecondsSinceEpoch}';
      headers.add({'id': newId, 'label': label.toUpperCase()});
      for (var row in matrixRows) {
        row[newId] = CellData(controller: TextEditingController());
      }
    });
  }

  void _addNewRow() {
    setState(() {
      Map<String, CellData> newRow = {};
      for (var header in headers) {
        newRow[header['id']!] = CellData(controller: TextEditingController());
      }
      matrixRows.add(newRow);
    });
  }

  void _removeRow(int index) {
    setState(() {
      for (var cell in matrixRows[index].values) {
        cell.dispose();
      }
      matrixRows.removeAt(index);
    });
  }

  // --- LOGIC MEDIA ---

  Future<void> _pickImage(CellData cell) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final String localPath = result.files.single.path!;
        // Hiển thị ảnh cục bộ ngay lập tức
        setState(() {
          cell.localPreviewPath = localPath;
          cell.imageUrl = 'uploading';
        });

        final String? uploadedUrl = await _cloudinaryService.uploadImage(
          File(localPath),
        );

        if (mounted) {
          setState(() {
            cell.imageUrl = uploadedUrl;
          });

          if (uploadedUrl != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tải ảnh lên thành công!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tải ảnh lên thất bại. Kiểm tra cấu hình .env'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      setState(() => cell.imageUrl = null);
    }
  }

  Future<void> _startRecording(CellData cell) async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        String? path;
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        if (!mounted) return;
        _showRecordingDialog(cell, path);
        await _audioRecorder.start(const RecordConfig(), path: path ?? '');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có quyền truy cập Microphone.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      debugPrint('Recording error: $e');
    }
  }

  void _showRecordingDialog(CellData cell, String? path) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Đang thu âm...', style: TextStyle(fontSize: 16)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic, size: 50, color: Colors.redAccent), SizedBox(height: 10), Text('Hãy phát âm rõ ràng')]),
        actions: [
          TextButton(onPressed: () async { await _audioRecorder.stop(); if (mounted) Navigator.pop(ctx); }, child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final pathResult = await _audioRecorder.stop();
              if (mounted) Navigator.pop(ctx);
              if (pathResult != null) _processRecordedFile(cell, pathResult);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Dừng & Tải lên'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRecordedFile(CellData cell, String path) async {
    try {
      Uint8List bytes;
      String fileName;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        bytes = response.bodyBytes;
        fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.webm';
      } else {
        File file = File(path);
        bytes = await file.readAsBytes();
        fileName = path.split('/').last;
        if (await file.exists()) await file.delete();
      }
      
      setState(() => cell.audioUrl = 'uploading');
      
      final uploadedUrl = await context.read<DeckProvider>().uploadAudio(fileName, bytes);
      
      if (mounted) {
        setState(() => cell.audioUrl = uploadedUrl);
        if (uploadedUrl != null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tải âm thanh thành công!')));
      }
    } catch (e) {
      debugPrint('Process audio error: $e');
      setState(() => cell.audioUrl = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tải âm thanh: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_playingUrl == url) {
        await _audioPlayer.stop();
        setState(() => _playingUrl = null);
        return;
      }

      await _audioPlayer.stop();
      setState(() => _playingUrl = url);
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() => _playingUrl = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể phát âm thanh')),
        );
      }
    }
  }

  // --- LOGIC SAVE ---

  Future<void> _handleCreateDeck() async {
    final String title = (dbContext['title'] as TextEditingController).text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề bộ đề'))); return; }
    
    setState(() => _isSaving = true);
    try {
      List<Map<String, dynamic>> headersForApi = [];
      for (int i = 0; i < headers.length; i++) {
        headersForApi.add({'key': headers[i]['id'], 'name': headers[i]['label'], 'position': i + 1});
      }
      
      List<Map<String, dynamic>> rowsForApi = matrixRows.map((row) {
        Map<String, dynamic> rowMap = {};
        for (var header in headers) {
          final cell = row[header['id']];
          if (cell != null) {
            rowMap[header['id']!] = {
              'text': cell.controller.text,
              'image_url': cell.imageUrl == 'uploading' ? null : cell.imageUrl,
              'audio_url': cell.audioUrl == 'uploading' ? null : cell.audioUrl
            };
          }
        }
        return rowMap;
      }).toList();

      final success = await context.read<DeckProvider>().bulkImport(
        deckTitle: title, 
        publicStatus: _publicStatus, 
        parentId: _parentId, 
        headers: headersForApi, 
        rows: rowsForApi
      );
      
      if (mounted && success) { 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo bộ đề thành công!'))); 
        Navigator.pop(context); 
      }
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Tính toán chiều rộng cell linh hoạt: nếu ít cột thì giãn đều, nhiều cột thì scroll
    final double availableWidth = screenWidth - 64; // 16*2 padding lề + 16*2 padding card
    final double cellWidth = headers.length <= 2
        ? (availableWidth - (headers.length - 1) * 12) / headers.length
        : screenWidth * 0.45;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo bộ đề Ma trận', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isSaving ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
                    : IconButton(onPressed: _handleCreateDeck, icon: const Icon(Icons.done, color: AppColors.primary, size: 28)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeckInfo(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                    icon: Icons.add_rounded,
                    label: 'Nhập',
                    onPressed: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BulkImportScreen()));
                      if (result != null && result is List<List<String>>) {
                        setState(() {
                          for (var rowData in result) {
                            Map<String, CellData> newRow = {};
                            for (int i = 0; i < headers.length; i++) {
                              String val =
                                  (i < rowData.length) ? rowData[i] : "";
                              newRow[headers[i]['id']!] = CellData(
                                  controller:
                                      TextEditingController(text: val));
                            }
                            matrixRows.add(newRow);
                          }
                        });
                      }
                    }),
                _buildActionButton(
                    icon: Icons.view_column_rounded,
                    label: 'Thêm cột',
                    onPressed: _showAddColumnDialog),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: matrixRows.length, 
              itemBuilder: (context, index) => _buildMatrixCard(index, cellWidth)
            ),
            const SizedBox(height: 20),
            Center(child: ElevatedButton(onPressed: _addNewRow, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2), child: const Text('+ THÊM THẺ MỚI', style: TextStyle(fontWeight: FontWeight.bold)))),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixCard(int index, double cellWidth) {
    final row = matrixRows[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), InkWell(onTap: () => _removeRow(index), child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent))]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
              children: headers.map((header) {
            final cell = row[header['id']]!;

            return Padding(
              padding: EdgeInsets.only(
                  right: header == headers.last ? 0 : 12),
              child: Container(
                width: cellWidth,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: cell.controller, 
                    style: const TextStyle(fontSize: 15), 
                    decoration: InputDecoration(isDense: true, hintText: header['label'], contentPadding: const EdgeInsets.symmetric(vertical: 8), border: InputBorder.none)
                  ),
                  const Divider(height: 8, thickness: 0.5),
                  Row(children: [
                    InkWell(
                      onTap: () => _pickImage(cell),
                      child: cell.imageUrl == 'uploading'
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (cell.localPreviewPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(cell.localPreviewPath!),
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  cell.imageUrl == null
                                      ? Icons.image_outlined
                                      : Icons.image,
                                  size: 20,
                                  color: cell.imageUrl == null
                                      ? Colors.grey
                                      : AppColors.primary,
                                )),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _startRecording(cell),
                      child: cell.audioUrl == 'uploading'
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(cell.audioUrl == null ? Icons.mic_none_rounded : Icons.mic, size: 18, color: cell.audioUrl == null ? Colors.grey : AppColors.success),
                    ),
                    if (cell.audioUrl != null &&
                        cell.audioUrl != 'uploading') ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _playAudio(cell.audioUrl!),
                        child: Icon(
                          _playingUrl == cell.audioUrl
                              ? Icons.stop_circle_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 20,
                          color: _playingUrl == cell.audioUrl
                              ? Colors.redAccent
                              : AppColors.primary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(header['label'] ?? '', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ]),
                ]),
              ),
            );
          }).toList()),
        ),
      ]),
    );
  }

  Widget _buildDeckInfo() {
    final decks = context.watch<DeckProvider>().decks;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('1. Cấu hình Bộ đề',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 16),
      TextField(
          controller: dbContext['title'],
          decoration: const InputDecoration(
              labelText: 'Tiêu đề bộ đề', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _publicStatus,
        isExpanded: true,
        decoration: const InputDecoration(
            labelText: 'Trạng thái chia sẻ', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'public', child: Text('Public')),
          DropdownMenuItem(value: 'private', child: Text('Private')),
          DropdownMenuItem(value: 'hidden', child: Text('Hidden'))
        ],
        onChanged: (val) => setState(() => _publicStatus = val!),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        value: _parentId,
        isExpanded: true,
        decoration: const InputDecoration(
            labelText: 'Vị trí phân cấp (Cha)', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem(value: null, child: Text('Không có')),
          ...decks.map((d) => DropdownMenuItem(
                value: d.id,
                child: Text(d.title,
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ))
        ],
        onChanged: (val) => setState(() => _parentId = val),
      ),
      const SizedBox(height: 12),
      TextField(
          controller: dbContext['description'],
          decoration: const InputDecoration(
              hintText: 'Thêm mô tả...', border: InputBorder.none)),
    ]);
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return InkWell(
        onTap: onPressed,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))
            ])));
  }

  void _showAddColumnDialog() {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Thêm thuộc tính mới'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Ví dụ: Hán Việt, Ví dụ...')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')), ElevatedButton(onPressed: () { _addNewColumn(controller.text); Navigator.pop(ctx); }, child: const Text('Thêm'))]));
  }
}
