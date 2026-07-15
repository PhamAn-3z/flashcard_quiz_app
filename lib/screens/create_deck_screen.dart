import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'image_crop_screen.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:async';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'bulk_import_screen.dart';
import '../data/services/cloudinary_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// Class định nghĩa cấu trúc dữ liệu cho từng ô trong ma trận
/// Giúp kiểm soát kiểu dữ liệu chặt chẽ, tránh lỗi subtype
class CellData {
  final TextEditingController controller;
  final FocusNode focusNode; // Theo dõi việc nhấn vào ô
  String? imageUrl;
  String? imagePublicId; // ID để xóa ảnh trên Cloudinary
  String? localPreviewPath; 
  String? audioUrl;
  String? audioObjectKey; // Key để xóa audio trên R2
  Duration? duration; // Thêm biến lưu độ dài âm thanh

  CellData({
    required this.controller,
    required this.focusNode,
    this.imageUrl,
    this.imagePublicId,
    this.localPreviewPath,
    this.audioUrl,
    this.audioObjectKey,
    this.duration,
  });

  void dispose() {
    controller.dispose();
    focusNode.dispose();
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
  };

  // 2. CẤU HÌNH CỘT (HEADERS)
  List<Map<String, String>> headers = [
    {'id': 'col_1', 'label': 'NHÓM 1'},
    {'id': 'col_2', 'label': 'NHÓM 2'},
  ];

  // 3. DỮ LIỆU MA TRẬN 2 CHIỀU: Sử dụng Class CellData để đảm bảo an toàn
  List<Map<String, CellData>> matrixRows = [];

  String _publicStatus = 'public';
  int? _parentId;
  bool _isSaving = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController(viewportFraction: 0.94);
  final ScrollController _paginationScrollController = ScrollController(); // Controller cho thanh số trang
  int _currentPage = 0;
  String? _playingUrl;
  
  // Thêm trạng thái theo dõi thời gian audio
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    // Thêm 2 thẻ mặc định mà không kích hoạt hiệu ứng cuộn
    _addNewRow(animate: false);
    _addNewRow(animate: false);

    // Cấu hình để âm thanh luôn phát ra loa ngoài và chuẩn media
    _audioPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: const AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.allowBluetooth,
        ],
      ),
    ));

    // Lắng nghe trạng thái cụ thể của Player để cập nhật UI thanh tiến trình
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _audioDuration = d);
        // Lưu độ dài vào cell đang phát nếu có
        if (_playingUrl != null) {
          for (var row in matrixRows) {
            for (var cell in row.values) {
              if (cell.audioUrl == _playingUrl) {
                cell.duration = d;
              }
            }
          }
        }
      }
    });

    // Lắng nghe sự kiện kết thúc âm thanh để cập nhật UI
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingUrl = null;
          _audioPosition = Duration.zero;
        });
      }
    });

    // Lắng nghe lỗi trình phát
    _audioPlayer.onLog.listen((msg) {
      debugPrint('🎵 AudioPlayer Log: $msg');
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    _paginationScrollController.dispose();
    (dbContext['title'] as TextEditingController).dispose();
    for (var row in matrixRows) {
      for (var cell in row.values) {
        cell.dispose();
      }
    }
    super.dispose();
  }

  // --- LOGIC XỬ LÝ MA TRẬN ---

  CellData _createCellData({String text = ''}) {
    final controller = TextEditingController(text: text);
    final focusNode = FocusNode();
    
    // Lắng nghe sự kiện focus để cập nhật màu sắc ô
    focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    return CellData(controller: controller, focusNode: focusNode);
  }

  void _addNewColumn(String label) {
    if (label.isEmpty) return;
    setState(() {
      // Sử dụng microseconds và cộng thêm độ dài danh sách để đảm bảo duy nhất tuyệt đối
      final String newId = 'col_${DateTime.now().microsecondsSinceEpoch}_${headers.length}';
      headers.add({'id': newId, 'label': label.toUpperCase()});
      for (var row in matrixRows) {
        row[newId] = _createCellData();
      }
    });
  }

  void _addNewRow({bool animate = true}) {
    setState(() {
      Map<String, CellData> newRow = {};
      for (var header in headers) {
        newRow[header['id']!] = _createCellData();
      }
      matrixRows.add(newRow);
    });
    
    if (animate) {
      // Tự động chuyển đến card mới tạo sau khi UI update
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            matrixRows.length - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// Hàm giúp thanh Pagination tự động cuộn đến vị trí trang hiện tại
  void _scrollToCurrentPage(int index) {
    if (!_paginationScrollController.hasClients) return;
    
    // Giả định mỗi ô số trang rộng 46px (36 width + 10 margin)
    double targetOffset = (index * 46.0) - (MediaQuery.of(context).size.width / 2) + 23.0;
    
    if (targetOffset < 0) targetOffset = 0;
    double maxScroll = _paginationScrollController.position.maxScrollExtent;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    _paginationScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Tính toán danh sách các mục hiển thị trên thanh Pagination (có rút gọn ...)
  List<dynamic> _getPaginationItems() {
    int total = matrixRows.length;
    int current = _currentPage;
    if (total <= 7) return List.generate(total, (i) => i);

    List<dynamic> items = [];
    items.add(0); // Luôn hiện trang đầu

    if (current > 3) items.add('...');

    int start = (current - 1).clamp(1, total - 2);
    int end = (current + 1).clamp(1, total - 2);

    if (current <= 3) {
      start = 1;
      end = 4;
    } else if (current >= total - 4) {
      start = total - 5;
      end = total - 2;
    }

    for (int i = start; i <= end; i++) {
      items.add(i);
    }

    if (current < total - 4) items.add('...');
    items.add(total - 1); // Luôn hiện trang cuối

    return items;
  }

  void _showJumpToPageDialog() {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nhảy đến thẻ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nhập số thẻ (1 - ${matrixRows.length})',
              errorText: errorText,
              suffixIcon: const Icon(Icons.tag),
            ),
            onChanged: (val) {
              if (errorText != null) setState(() => errorText = null);
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val == null) {
                  setState(() => errorText = 'Vui lòng nhập số');
                  return;
                }
                if (val < 1 || val > matrixRows.length) {
                  setState(() =>
                      errorText = 'Số thẻ phải từ 1 đến ${matrixRows.length}');
                  return;
                }

                _pageController.animateToPage(
                  val - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Đi'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeRow(int index) {
    if (matrixRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phải có ít nhất một thẻ'))
      );
      return;
    }
    setState(() {
      for (var cell in matrixRows[index].values) {
        cell.dispose();
      }
      matrixRows.removeAt(index);
      // Đảm bảo trang hiện tại không vượt quá số lượng thẻ
      if (_currentPage >= matrixRows.length) {
        _currentPage = matrixRows.length - 1;
      }
    });
  }

  // --- LOGIC MEDIA ---

  Future<void> _pickImage(CellData cell) async {
    final ImagePicker picker = ImagePicker();

    try {
      // 1. Chọn ảnh từ Gallery
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final Uint8List imageBytes = await pickedFile.readAsBytes();

        // 2. Chuyển sang màn hình cắt ảnh (Dart pure)
        if (!mounted) return;
        final Uint8List? croppedImage = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCropScreen(image: imageBytes),
          ),
        );

        if (croppedImage != null) {
          // Lưu vào file tạm để hiển thị preview cục bộ (nếu cần) và upload
          final tempDir = await getTemporaryDirectory();
          final String localPath =
              '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File file = File(localPath);
          await file.writeAsBytes(croppedImage);

          setState(() {
            cell.localPreviewPath = localPath;
            cell.imageUrl = 'uploading';
          });

          // 3. Tải ảnh đã cắt lên Cloudinary (Signed Upload)
          final signatureData = await context.read<DeckProvider>().getCloudinarySignature(
            oldPublicId: cell.imagePublicId,
          );

          if (signatureData != null) {
            final uploadResult = await _cloudinaryService.uploadFile(
              file: file,
              signatureData: signatureData,
              resourceType: 'image',
            );

            if (mounted && uploadResult != null) {
              setState(() {
                cell.imageUrl = uploadResult.secureUrl;
                cell.imagePublicId = uploadResult.publicId;
              });
            } else if (mounted) {
              setState(() {
                cell.imageUrl = null;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi xử lý hình ảnh')),
        );
      }
    }
  }

  void _removeImage(CellData cell) {
    if (cell.imagePublicId != null) {
      context.read<DeckProvider>().deleteImage(cell.imagePublicId!);
    }
    setState(() {
      cell.imageUrl = null;
      cell.imagePublicId = null;
      cell.localPreviewPath = null;
    });
  }

  void _removeAudio(CellData cell) {
    if (cell.audioObjectKey != null) {
      context.read<DeckProvider>().deleteAudioFromR2(cell.audioObjectKey!);
    }
    setState(() {
      cell.audioUrl = null;
      cell.audioObjectKey = null;
      if (_playingUrl == cell.audioUrl) {
        _audioPlayer.stop();
        _playingUrl = null;
      }
    });
  }

  Future<void> _startRecording(CellData cell) async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ứng dụng cần quyền Microphone để thu âm. Vui lòng cấp quyền trong Cài đặt máy.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            )
          );
        }
        return;
      }

      String? path;
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        path = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      // Cấu hình ghi âm
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      debugPrint('🎙️ Đang khởi động Microphone: $path');

      // Bắt đầu ghi âm trước khi hiện Dialog
      await _audioRecorder.start(config, path: path ?? '');

      // Chờ một chút để hardware sẵn sàng
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;
      _showRecordingDialog(cell, path);
    } catch (e) {
      debugPrint('❌ Lỗi khởi động ghi âm: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi Microphone: $e')));
    }
  }

  void _showRecordingDialog(CellData cell, String? path) {
    int seconds = 0;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) async {
            if (seconds >= 10) {
              t.cancel();
              final pathResult = await _audioRecorder.stop();
              if (ctx.mounted) Navigator.pop(ctx);
              if (pathResult != null) {
                _processRecordedFile(cell, pathResult);
              }
            } else {
              if (ctx.mounted) setDialogState(() => seconds++);
            }
          });

          return AlertDialog(
            title: const Text('Đang thu âm...', style: TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: seconds / 10,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                    ),
                    const Icon(Icons.mic, size: 40, color: Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '00:${seconds.toString().padLeft(2, '0')} / 00:10',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text('Hãy phát âm rõ ràng', style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  timer?.cancel();
                  await _audioRecorder.stop();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  timer?.cancel();
                  final pathResult = await _audioRecorder.stop();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (pathResult != null) {
                    _processRecordedFile(cell, pathResult);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                child: const Text('Dừng & Tải lên'),
              ),
            ],
          );
        },
      ),
    ).then((_) => timer?.cancel());
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
        final file = File(path);
        if (!await file.exists()) {
          throw Exception('File ghi âm không tồn tại tại đường dẫn: $path');
        }

        bytes = await file.readAsBytes();
        fileName = path.split('/').last;

        // Log thông tin quan trọng
        debugPrint('📦 Chuẩn bị upload: $fileName');
        debugPrint('📊 Kích thước dữ liệu: ${bytes.length} bytes');

        // Xóa file tạm sau khi đã đọc xong bytes
        await file.delete();
      }
      
      if (bytes.length < 100) {
        throw Exception('Dữ liệu ghi âm quá nhỏ (${bytes.length} bytes). Có thể Microphone không thu được tiếng.');
      }

      setState(() => cell.audioUrl = 'uploading');

      if (!mounted) return;
      // Tải âm thanh lên Cloudflare R2
      final uploadResult = await context.read<DeckProvider>().uploadAudio(
        fileName, 
        bytes,
        oldObjectKey: cell.audioObjectKey,
      );
      
      if (mounted) {
        if (uploadResult != null) {
          setState(() {
            cell.audioUrl = uploadResult['url'];
            cell.audioObjectKey = uploadResult['objectKey'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tải âm thanh thành công!')));
        } else {
          setState(() => cell.audioUrl = null);
        }
      }
    } catch (e) {
      debugPrint('Process audio error: $e');
      setState(() => cell.audioUrl = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tải âm thanh: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty || url == 'uploading') return;

    try {
      if (_playingUrl == url) {
        debugPrint('⏹️ Dừng phát âm thanh');
        await _audioPlayer.stop();
        setState(() => _playingUrl = null);
        return;
      }

      await _audioPlayer.stop();
      setState(() => _playingUrl = url);

      // 1. Kiểm tra URL có hợp lệ không
      if (!url.startsWith('http')) {
        throw Exception('URL âm thanh không hợp lệ: $url');
      }

      debugPrint('🎵 Đang tải nguồn âm thanh: $url');

      await _audioPlayer.stop();
      setState(() {
        _playingUrl = url;
        _audioPosition = Duration.zero;
        _audioDuration = Duration.zero;
      });

      // 3. Thiết lập nguồn và phát
      await _audioPlayer.setSource(UrlSource(url));
      await _audioPlayer.setVolume(1.0);

      // Bắt đầu phát
      await _audioPlayer.resume();

      debugPrint('▶️ Lệnh phát đã được gửi');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang phát âm thanh...'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint('❌ Lỗi Playback: $e');
      setState(() => _playingUrl = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
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
            final String text = cell.controller.text;
            final String? imageUrl = cell.imageUrl == 'uploading' ? null : cell.imageUrl;
            final String? audioUrl = cell.audioUrl == 'uploading' ? null : cell.audioUrl;

            // Nếu không có media, gửi dạng String đơn giản để tiết kiệm dung lượng
            if (imageUrl == null && audioUrl == null) {
              rowMap[header['id']!] = text;
            } else {
              // Nếu có media, gửi object đầy đủ thông tin để quản lý file (Cloudinary ID, R2 Key)
              Map<String, dynamic> cellContent = {'text': text};
              
              if (imageUrl != null) {
                cellContent['image'] = {
                  'url': imageUrl,
                  'public_id': cell.imagePublicId,
                };
              }
              
              if (audioUrl != null) {
                cellContent['audio'] = {
                  'url': audioUrl,
                  'key': cell.audioObjectKey,
                };
              }
              
              rowMap[header['id']!] = cellContent;
            }
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
    final double cellWidth = headers.length <= 2
        ? (screenWidth * 0.85 - (headers.length - 1) * 12) / headers.length
        : 160.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo bộ đề Ma trận',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  onPressed: _handleCreateDeck,
                  icon: const Icon(Icons.done, color: AppColors.primary, size: 28)),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDeckInfo(),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildActionButton(
                            icon: Icons.add_rounded,
                            label: 'Nhập',
                            onPressed: () async {
                              final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const BulkImportScreen(returnDataOnly: true)));
                              
                              if (result != null && result is Map<String, dynamic>) {
                                final List<String> importedHeaders = List<String>.from(result['headers']);
                                final List<List<String>> importedRows = List<List<String>>.from(result['rows']);

                                setState(() {
                                  // 1. Đồng bộ số lượng và tên headers (Nhóm)
                                  for (int i = 0; i < importedHeaders.length; i++) {
                                    if (i < headers.length) {
                                      if (!importedHeaders[i].startsWith('Nhóm')) {
                                        headers[i]['label'] = importedHeaders[i].toUpperCase();
                                      }
                                    } else {
                                      _addNewColumn(importedHeaders[i]);
                                    }
                                  }

                                  // 2. Thêm dữ liệu (Cơ chế chống tràn: Điền vào thẻ trống ở cuối trước)
                                  int lastNotEmptyIdx = -1;
                                  for (int i = matrixRows.length - 1; i >= 0; i--) {
                                    bool isRowEmpty = true;
                                    for (var cell in matrixRows[i].values) {
                                      if (cell.controller.text.trim().isNotEmpty || 
                                          cell.imageUrl != null || 
                                          cell.audioUrl != null) {
                                        isRowEmpty = false;
                                        break;
                                      }
                                    }
                                    if (!isRowEmpty) {
                                      lastNotEmptyIdx = i;
                                      break;
                                    }
                                  }

                                  int targetIdx = lastNotEmptyIdx + 1;
                                  for (var rowData in importedRows) {
                                    if (targetIdx < matrixRows.length) {
                                      // Ghi đè vào thẻ trống hiện có
                                      for (int i = 0; i < headers.length; i++) {
                                        String val = (i < rowData.length) ? rowData[i] : "";
                                        matrixRows[targetIdx][headers[i]['id']!]?.controller.text = val;
                                      }
                                      targetIdx++;
                                    } else {
                                      // Thêm thẻ mới
                                      Map<String, CellData> newRow = {};
                                      for (int i = 0; i < headers.length; i++) {
                                        String val = (i < rowData.length) ? rowData[i] : "";
                                        newRow[headers[i]['id']!] = _createCellData(text: val);
                                      }
                                      matrixRows.add(newRow);
                                    }
                                  }
                                });
                              }
                            }),
                        const SizedBox(width: 12),
                        _buildActionButton(
                            icon: Icons.view_column_rounded,
                            label: 'Thêm nhóm',
                            onPressed: _showAddColumnDialog),
                        const SizedBox(width: 12),
                        _buildActionButton(
                            icon: Icons.add_box_rounded,
                            label: 'Thêm thẻ',
                            onPressed: _addNewRow),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: matrixRows.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _scrollToCurrentPage(index); // Cuộn thanh số trang theo
                },
                itemBuilder: (context, index) {
                  return _buildMatrixCard(index, cellWidth);
                },
              ),
            ),
            // 3. Pagination Bar (Cố định ở dưới cùng của body)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Nút Jump to Page (Nhảy đến trang)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: InkWell(
                      onTap: _showJumpToPageDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.ads_click_rounded, size: 18, color: AppColors.primary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Builder(builder: (context) {
                      final items = _getPaginationItems();
                      return ListView.builder(
                        controller: _paginationScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          if (item == '...') {
                            return Container(
                              width: 30,
                              alignment: Alignment.center,
                              child: const Text('...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            );
                          }
                          
                          int pageIdx = item as int;
                          bool isSelected = _currentPage == pageIdx;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                pageIdx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 10),
                              width: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 4, offset: const Offset(0, 2))
                                ] : null,
                              ),
                              child: Text(
                                '${pageIdx + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

    );
  }

  Widget _buildMatrixCard(int index, double cellWidth) {
    final row = matrixRows[index];
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Khối thẻ trắng chính
          Container(
            margin: const EdgeInsets.fromLTRB(8, 16, 8, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header của Card (Số thứ tự + Nút xóa)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'THẺ ${index + 1} / ${matrixRows.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                    ),
                    InkWell(
                        onTap: () => _removeRow(index),
                        child: const Icon(Icons.delete_outline,
                            size: 22, color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                
                // Danh sách các Term
                Column(
                  children: headers.map((header) {
                    final cell = row[header['id']]!;
                    final bool isDataEmpty = cell.controller.text.isEmpty && 
                                           cell.imageUrl == null && 
                                           cell.audioUrl == null;
                    final bool isFaint = isDataEmpty && !cell.focusNode.hasFocus;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isFaint ? Colors.grey.shade100.withAlpha(50) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cell.focusNode.hasFocus 
                            ? AppColors.primary.withAlpha(120) 
                            : (isFaint ? Colors.grey.shade200 : Colors.grey.shade300),
                          width: cell.focusNode.hasFocus ? 1.5 : 1,
                        ),
                      ),
                      child: Opacity(
                        opacity: isFaint ? 0.4 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _showRenameColumnDialog(header['id']!, header['label']!),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    header['label'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isFaint ? Colors.grey : AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Icon(Icons.edit_note_rounded, size: 18, color: isFaint ? Colors.grey.shade300 : Colors.grey.shade400),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: cell.controller,
                              focusNode: cell.focusNode,
                              maxLines: null,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black87),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Nhập nội dung...',
                                hintStyle: TextStyle(fontSize: 16, color: Colors.black26, fontWeight: FontWeight.normal),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                            const Divider(height: 16, thickness: 0.5),
                            if (cell.imageUrl != null || cell.localPreviewPath != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: cell.imageUrl == 'uploading'
                                            ? const Center(child: CircularProgressIndicator())
                                            : (cell.localPreviewPath != null
                                                ? Image.file(File(cell.localPreviewPath!), fit: BoxFit.cover)
                                                : Image.network(cell.imageUrl!, fit: BoxFit.cover)),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: InkWell(
                                          onTap: () => _pickImage(cell),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withAlpha(150),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.sync, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: InkWell(
                                          onTap: () => _removeImage(cell),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                            child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                if (cell.imageUrl == null && cell.localPreviewPath == null) ...[
                                  _buildMiniActionButton(
                                    icon: Icons.add_photo_alternate_outlined,
                                    onTap: () => _pickImage(cell),
                                    isActive: false,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                if (cell.audioUrl == null || cell.audioUrl == 'uploading') ...[
                                  _buildMiniActionButton(
                                    icon: Icons.mic_none_rounded,
                                    onTap: () => _startRecording(cell),
                                    isActive: cell.audioUrl != null,
                                    isLoading: cell.audioUrl == 'uploading',
                                    onLongPress: cell.audioUrl != null ? () => _removeAudio(cell) : null,
                                  ),
                                ],
                                if (cell.audioUrl != null && cell.audioUrl != 'uploading') ...[
                                  Expanded(child: _buildAudioPlayerBar(cell)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Tạo khoảng trống dưới cùng để cuộn thoải mái
        ],
      ),
    );
  }

  Widget _buildAudioPlayerBar(CellData cell) {
    final bool isPlaying = _playingUrl == cell.audioUrl;
    final Duration totalDuration = isPlaying ? _audioDuration : (cell.duration ?? Duration.zero);
    final double progress = (isPlaying && totalDuration.inMilliseconds > 0)
        ? (_audioPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Nút Play/Pause
          InkWell(
            onTap: () => _playAudio(cell.audioUrl!),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          // Thời gian
          Text(
            isPlaying
                ? "${_formatDuration(_audioPosition)} / ${_formatDuration(totalDuration)}"
                : "0:00 / ${_formatDuration(totalDuration)}",
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          // Thanh tiến trình (Line)
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(1),
              ),
              child: isPlaying
                  ? FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(color: AppColors.primary),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          // Nút Thay đổi (Ghi âm lại)
          InkWell(
            onTap: () => _startRecording(cell),
            child: Icon(Icons.sync_rounded, size: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),
          // Nút Xóa
          InkWell(
            onTap: () => _removeAudio(cell),
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool isActive = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? (icon == Icons.mic_none_rounded
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1))
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? (icon == Icons.mic_none_rounded
                    ? AppColors.success
                    : AppColors.primary)
                : Colors.grey.shade200,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                icon,
                size: 16,
                color: isActive
                    ? (icon == Icons.mic_none_rounded
                        ? AppColors.success
                        : AppColors.primary)
                    : Colors.grey,
              ),
      ),
    );
  }

  // Thay thế _buildCellMediaItem cũ (nếu không dùng nữa) bằng logic mới gọn hơn ở trên
  // hoặc xóa nếu nó không còn được gọi ở đâu.
  // ... rest of the code ...

  Widget _buildDeckInfo() {
    final decks = context.watch<DeckProvider>().decks;

    // Helper: Lấy thông tin hiển thị cho Quyền riêng tư
    Map<String, dynamic> getPrivacyInfo(String status) {
      switch (status) {
        case 'private':
          return {
            'label': 'Riêng tư',
            'icon': Icons.lock_outline_rounded,
            'color': Colors.orange
          };
        case 'hidden':
          return {
            'label': 'Bị ẩn',
            'icon': Icons.visibility_off_rounded,
            'color': Colors.grey
          };
        default:
          return {
            'label': 'Công khai',
            'icon': Icons.public_rounded,
            'color': Colors.blue
          };
      }
    }

    final privacy = getPrivacyInfo(_publicStatus);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 1. Tiêu đề bộ đề (Đã thêm viền bo tròn để dễ nhận diện)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: dbContext['title'],
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          decoration: InputDecoration(
            hintText: 'Tiêu đề bộ đề',
            hintStyle: TextStyle(
                color: Colors.grey.shade300, fontWeight: FontWeight.bold),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // 2. Các ô điều chỉnh trạng thái và thư mục (Xếp theo chiều dọc)
      LayoutBuilder(
        builder: (context, constraints) => _buildModernField(
          label: 'QUYỀN RIÊNG TƯ',
          child: PopupMenuButton<String>(
            initialValue: _publicStatus,
            offset: const Offset(0, 40),
            constraints: BoxConstraints(minWidth: constraints.maxWidth), // Đồng bộ chiều rộng
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            onSelected: (val) => setState(() => _publicStatus = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'public',
                  child: Row(children: [
                    Icon(Icons.public_rounded, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Công khai')
                  ])),
              const PopupMenuItem(
                  value: 'private',
                  child: Row(children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Riêng tư')
                  ])),
            ],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(privacy['icon'], size: 16, color: privacy['color']),
                  const SizedBox(width: 8),
                  Text(privacy['label'],
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) => _buildModernField(
          label: 'THƯ MỤC CHA',
          child: PopupMenuButton<int?>(
            initialValue: _parentId,
            offset: const Offset(0, 40),
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxHeight: 350, // Giới hạn chiều cao khoảng 7-8 item
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            onSelected: (val) => setState(() => _parentId = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: null,
                  child: Row(children: [
                    Icon(Icons.folder_open_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Mặc định')
                  ])),
              ...decks.map((d) => PopupMenuItem(
                  value: d.id,
                  child: Row(children: [
                    const Icon(Icons.folder_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d.title, overflow: TextOverflow.ellipsis))
                  ]))),
            ],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                      _parentId == null
                          ? Icons.folder_open_rounded
                          : Icons.folder_rounded,
                      size: 16,
                      color: _parentId == null
                          ? AppColors.primary
                          : Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          _parentId == null
                              ? 'Mặc định'
                              : (decks.any((d) => d.id == _parentId)
                                  ? decks
                                      .firstWhere((d) => d.id == _parentId)
                                      .title
                                  : 'Mặc định'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Helper tạo các ô nhập liệu hiện đại với label nhỏ phía trên
  Widget _buildModernField({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, 
            style: TextStyle(
              fontSize: 9, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey.shade500,
              letterSpacing: 0.5
            )
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
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

  void _showRenameColumnDialog(String id, String currentLabel) {
    final controller = TextEditingController(text: currentLabel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên thuộc tính'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ví dụ: Hán Việt, Ví dụ...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  for (var h in headers) {
                    if (h['id'] == id) {
                      h['label'] = controller.text.trim().toUpperCase();
                      break;
                    }
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
