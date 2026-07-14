import 'dart:io';
import 'dart:async'; // Bổ sung import này
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'image_crop_screen.dart';
import '../data/services/cloudinary_service.dart';
import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'comments_screen.dart';
import '../providers/auth_provider.dart';

class FlashcardLearningScreen extends StatefulWidget {
  final int deckId;
  final String deckName;
  final int? initialIndex;

  const FlashcardLearningScreen({super.key, required this.deckId, required this.deckName, this.initialIndex});

  @override
  State<FlashcardLearningScreen> createState() => _FlashcardLearningScreenState();
}

class _FlashcardLearningScreenState extends State<FlashcardLearningScreen> {
  DeckStudyData? _studyData;
  int _currentIndex = 0;
  int? _activeGroupIdForPopup;
  bool _isCardFlipped = false;
  bool _isLoading = true;
  bool _isFinished = false;
  bool _isSaving = false; // Biến cờ ngăn chặn gọi API 2 lần
  Map<String, dynamic>? _summaryData;
  final Set<int> _answeredCardIds = {};
  int _cardsLearnedCount = 0;
  int _cardsReviewedCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  String? _currentlyPlayingUrl;
  late DateTime _startTime;
  final Map<String, String> _localAudioPaths = {}; // Lưu trữ đường dẫn file âm thanh đã tải về
  
  // Sử dụng Notifier để cập nhật tiến trình âm thanh chuyên nghiệp và an toàn
  final ValueNotifier<Duration> _audioPositionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _audioDurationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<String?> _playingUrlNotifier = ValueNotifier(null);

  // Lưu trữ các subscription để hủy khi dispose
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadStudyData();
    _initAudioListeners();
    _initAudioContext();
  }

  void _initAudioContext() {
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
  }

  void _initAudioListeners() {
    _subscriptions.add(_audioPlayer.onPositionChanged.listen((p) {
      _audioPositionNotifier.value = p;
    }));

    _subscriptions.add(_audioPlayer.onDurationChanged.listen((d) {
      _audioDurationNotifier.value = d;
    }));

    _subscriptions.add(_audioPlayer.onPlayerComplete.listen((event) {
      _currentlyPlayingUrl = null;
      _playingUrlNotifier.value = null;
      _audioPositionNotifier.value = Duration.zero;
    }));
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _audioPositionNotifier.dispose();
    _audioDurationNotifier.dispose();
    _playingUrlNotifier.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty) return;
    try {
      if (_currentlyPlayingUrl == url) {
        await _audioPlayer.stop();
        _currentlyPlayingUrl = null;
        _playingUrlNotifier.value = null;
        _audioPositionNotifier.value = Duration.zero;
      } else {
        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        
        _currentlyPlayingUrl = url;
        _playingUrlNotifier.value = url;
        _audioPositionNotifier.value = Duration.zero;
        _audioDurationNotifier.value = Duration.zero;

        // Xác định nguồn phát
        String? localPath = _localAudioPaths[url];
        if (localPath == null || !File(localPath).existsSync() || File(localPath).lengthSync() == 0) {
          final dio = Dio();
          final tempDir = await getTemporaryDirectory();
          final String extension = url.split('.').last.split('?').first.toLowerCase();
          final String filePath = '${tempDir.path}/audio_${url.hashCode.abs()}.$extension';
          try {
            await dio.download(url, filePath).timeout(const Duration(seconds: 15));
            if (File(filePath).existsSync() && File(filePath).lengthSync() > 0) {
              localPath = filePath;
              _localAudioPaths[url] = filePath;
            }
          } catch (_) {}
        }

        Source source = (localPath != null && File(localPath).existsSync()) 
            ? DeviceFileSource(localPath) 
            : UrlSource(url);

        await _audioPlayer.play(source).timeout(const Duration(seconds: 15));
      }
      if (mounted) setState(() {}); // Chỉ cập nhật UI màn hình chính (nếu cần)
    } catch (e) {
      debugPrint('❌ Lỗi phát âm thanh: $e');
      _currentlyPlayingUrl = null;
      _playingUrlNotifier.value = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadStudyData() async {
    final data = await context.read<DeckProvider>().fetchDeckStudyData(widget.deckId);
    if (mounted) {
      setState(() {
        _studyData = data;
        _isLoading = false;
        
        // Ưu tiên giữ nguyên vị trí hiện tại nếu đang học, nếu không thì dùng initialIndex từ widget
        int targetIndex = _currentIndex;
        if (_currentIndex == 0 && widget.initialIndex != null) {
          targetIndex = widget.initialIndex!;
        }

        if (data != null && data.flashcards.isNotEmpty) {
          _currentIndex = targetIndex.clamp(0, data.flashcards.length - 1);
        }
      });
      if (data != null) {
        _preloadAssets(data);
      }
    }
  }

  /// Khởi động lại màn hình học tập để làm mới dữ liệu một cách sạch sẽ nhất
  void _restartScreen() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => FlashcardLearningScreen(
          deckId: widget.deckId,
          deckName: widget.deckName,
          initialIndex: _currentIndex,
        ),
        transitionDuration: Duration.zero,
      ),
    );
  }

  /// Tải trước ảnh và âm thanh cho 20 thẻ đầu tiên để xóa bỏ độ trễ mà không gây quá tải
  Future<void> _preloadAssets(DeckStudyData data) async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();

    // Chỉ lấy tối đa 20 thẻ đầu tiên để preload
    final preloadCards = data.flashcards.take(20).toList();

    for (var card in preloadCards) {
      // Dừng vòng lặp ngay lập tức nếu người dùng đã thoát màn hình
      if (!mounted) return;

      for (var cell in card.cardData) {
        if (!mounted) return;

        // 1. Pre-cache Hình ảnh
        if (cell.imageUrl != null) {
          precacheImage(NetworkImage(cell.imageUrl!), context);
        }

        // 2. Pre-download Âm thanh
        if (cell.audioUrl != null && !_localAudioPaths.containsKey(cell.audioUrl)) {
          _downloadAudioInBackground(dio, cell.audioUrl!, tempDir);
        }
      }
    }
  }

  Future<void> _downloadAudioInBackground(Dio dio, String url, Directory tempDir) async {
    try {
      // Lấy phần mở rộng gốc của file từ URL (m4a, mp3, aac...)
      final String extension = url.split('.').last.split('?').first.toLowerCase();
      final String fileName = 'audio_${url.hashCode.abs()}.$extension';
      final String filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      if (!await file.exists()) {
        await dio.download(url, filePath);
      }
      
      // Chỉ lưu đường dẫn nếu file tải về có dữ liệu
      if (mounted && await file.exists() && await file.length() > 0) {
        _localAudioPaths[url] = filePath;
      }
    } catch (e) {
      debugPrint('⚠️ Không thể tải trước âm thanh: $url - $e');
    }
  }

  void _flipCard() {
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });
  }

  Future<void> _submitRating(String rating) async {
    if (_studyData == null) return;

    final currentCard = _studyData!.flashcards[_currentIndex];

    // 1. Call API in background
    context
        .read<DeckProvider>()
        .updateStudyProgress(currentCard.positionId, rating);

    // 2. Phân loại Thẻ mới vs Ôn tập (Dựa trên trạng thái TRƯỚC khi học)
    if (!_answeredCardIds.contains(currentCard.positionId)) {
      final status = currentCard.studyState.status.toUpperCase();
      if (status == 'NEW') {
        _cardsLearnedCount++;
      } else if (status == 'LEARNING' || status == 'REVIEW') {
        _cardsReviewedCount++;
      }
      _answeredCardIds.add(currentCard.positionId);
    }

    if (_currentIndex < _studyData!.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isCardFlipped = false;
        _activeGroupIdForPopup = null;
      });
    } else {
      if (_isSaving) return;
      setState(() => _isSaving = true);

      final int duration = DateTime.now().difference(_startTime).inSeconds;
      
      // 4. Gọi API session-end với các thông số đã phân loại
      final result = await context.read<DeckProvider>().endStudySession(
            deckId: widget.deckId,
            cardsLearned: _cardsLearnedCount,
            cardsReviewed: _cardsReviewedCount,
            durationSeconds: duration,
          );

      if (result != null && mounted) {
        // Cập nhật lại AuthProvider để trang chủ hiện EXP/Streak mới ngay lập tức
        context.read<AuthProvider>().refreshProfile();
      }

      setState(() {
        _summaryData = result;
        _isFinished = true;
      });
    }
  }

  Future<void> _handleEarlyExit() async {
    // Kiểm tra xem đã có câu trả lời nào chưa bằng cách check Set answeredCardIds
    if (_answeredCardIds.isEmpty || _isSaving) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    final int duration = DateTime.now().difference(_startTime).inSeconds;
    // Gửi log những gì đã học được
    await context.read<DeckProvider>().endStudySession(
          deckId: widget.deckId,
          cardsLearned: _cardsLearnedCount,
          cardsReviewed: _cardsReviewedCount,
          durationSeconds: duration,
        );
    if (mounted) {
      context.read<AuthProvider>().refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu tiến độ học tập!'), duration: Duration(seconds: 1)),
      );
      Navigator.pop(context);
    }
  }

  Future<bool> _showExitConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Dừng phiên học?'),
        content: const Text(
            'Bạn có muốn lưu lại tiến độ của những thẻ đã học và kết thúc phiên học này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('TIẾP TỤC HỌC'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('DỪNG VÀ LƯU'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isCardFlipped = false;
        _activeGroupIdForPopup = null;
      });
    }
  }

  Future<void> _showCardSettings(Flashcard card) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest_rounded,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Cài đặt thẻ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildSettingsOption(
                  icon: Icons.edit_note_rounded,
                  label: 'Chi tiết & Chỉnh sửa',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showCardEditor(card);
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.swap_vert_rounded,
                  label: 'Cấu hình mặt thẻ',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _showRankSettings();
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.refresh_rounded,
                  label: 'Đặt lại tiến độ',
                  color: Colors.orange,
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context.read<DeckProvider>().resetCardProgress(card.positionId);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đặt lại tiến độ thẻ!')));
                      _loadStudyData(); // Tải lại để cập nhật status
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ĐÓNG',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRankSettings() {
    if (_studyData == null) return;
    
    final headers = _studyData!.headers;
    int? frontGroupId = headers.any((h) => h.personalizedRank == 'A')
        ? headers.firstWhere((h) => h.personalizedRank == 'A').groupId
        : headers[0].groupId;
        
    int? backGroupId = headers.any((h) => h.personalizedRank == 'B')
        ? headers.firstWhere((h) => h.personalizedRank == 'B').groupId
        : (headers.length > 1 ? headers[1].groupId : headers[0].groupId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDialogSaving = false;
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Cấu hình mặt thẻ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chọn thông tin hiển thị ở các mặt:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  _buildRankDropdown(
                    label: 'MẶT TRƯỚC (QUAN TRỌNG NHẤT)',
                    value: frontGroupId,
                    headers: headers,
                    onChanged: (val) => setDialogState(() {
                      if (val == backGroupId) {
                        backGroupId = null; // Xóa mặt sau nếu chọn trùng vào mặt trước
                      }
                      frontGroupId = val;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildRankDropdown(
                    label: 'MẶT SAU',
                    value: backGroupId,
                    headers: headers,
                    onChanged: (val) => setDialogState(() {
                      if (val == frontGroupId) {
                        frontGroupId = null; // Xóa mặt trước nếu chọn trùng vào mặt sau
                      }
                      backGroupId = val;
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('HỦY')),
                ElevatedButton(
                  onPressed: (isDialogSaving || frontGroupId == null || backGroupId == null) ? null : () async {
                    setDialogState(() => isDialogSaving = true);
                    
                    List<Map<String, dynamic>> ranks = [];
                    for (var h in headers) {
                      String rank = 'NONE';
                      if (h.groupId == frontGroupId) rank = 'A';
                      else if (h.groupId == backGroupId) rank = 'B';
                      ranks.add({'groupId': h.groupId, 'personalizedRank': rank});
                    }
                    
                    final success = await context.read<DeckProvider>().updatePersonalizedRanks(widget.deckId, ranks);
                    if (mounted && success) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật cấu hình mặt thẻ!')));
                      setState(() => _isLoading = true);
                      _loadStudyData();
                    } else if (mounted) {
                      setDialogState(() => isDialogSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi cập nhật!')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isDialogSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('LƯU'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildRankDropdown({required String label, required int? value, required List<PersonalizedHeader> headers, required ValueChanged<int?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              hint: const Text("Chọn nhóm...", style: TextStyle(fontSize: 14, color: Colors.grey)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: headers.map((h) => DropdownMenuItem(value: h.groupId, child: Text(h.groupName, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black12, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCardEditor(Flashcard card) {
    final headers = _studyData!.headers;
    final outerContext = context;
    bool saveSuccess = false; // Cờ đánh dấu lưu thành công để refresh sau
    
    final Map<int, TextEditingController> textControllers = {};
    final Map<int, TextEditingController> headerControllers = {};
    final Map<int, Map<String, dynamic>> mediaState = {};

    for (var cell in card.cardData) {
      textControllers[cell.groupId] = TextEditingController(text: cell.text);
      mediaState[cell.groupId] = {
        'imageUrl': cell.imageUrl,
        'imagePublicId': cell.imagePublicId,
        'audioUrl': cell.audioUrl,
        'audioObjectKey': cell.audioObjectKey,
        'localPreviewPath': null,
      };
    }
    
    for (var h in headers) {
      headerControllers[h.groupId] = TextEditingController(text: h.groupName);
      if (!textControllers.containsKey(h.groupId)) {
        textControllers[h.groupId] = TextEditingController(text: "");
      }
      if (!mediaState.containsKey(h.groupId)) {
        mediaState[h.groupId] = {
          'imageUrl': null,
          'imagePublicId': null,
          'audioUrl': null,
          'audioObjectKey': null,
          'localPreviewPath': null,
        };
      }
    }

    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        bool isDialogSaving = false; // Biến loading riêng cho Dialog

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: AppColors.background,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(builderContext).size.height * 0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Chi tiết & Chỉnh sửa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...headers.map((header) {
                                    return _buildEditorField(
                                      header, 
                                      textControllers[header.groupId]!, 
                                      headerControllers[header.groupId]!,
                                      mediaState[header.groupId]!,
                                      setDialogState,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isDialogSaving) return;
                            
                            // 0. Dừng nhạc và giải phóng focus ngay lập tức để ngắt các liên kết UI
                            await _audioPlayer.stop();
                            _currentlyPlayingUrl = null;
                            _playingUrlNotifier.value = null;
                            FocusManager.instance.primaryFocus?.unfocus();

                            if (builderContext.mounted) setDialogState(() => isDialogSaving = true);

                            try {
                              List<Map<String, dynamic>> headersToUpdate = [];
                              headerControllers.forEach((groupId, ctrl) {
                                headersToUpdate.add({'groupId': groupId, 'name': ctrl.text.trim()});
                              });

                              List<Map<String, dynamic>> termsToUpdate = [];
                              textControllers.forEach((groupId, ctrl) {
                                final mState = mediaState[groupId]!;
                                Map<String, dynamic> content = {'text': ctrl.text.trim()};
                                if (mState['imageUrl'] != null && mState['imageUrl'] != 'uploading') {
                                  content['image'] = {'url': mState['imageUrl'], 'public_id': mState['imagePublicId']};
                                }
                                if (mState['audioUrl'] != null && mState['audioUrl'] != 'uploading') {
                                  content['audio'] = {'url': mState['audioUrl'], 'key': mState['audioObjectKey']};
                                }
                                termsToUpdate.add({'groupId': groupId, 'content': content});
                              });

                              final success = await outerContext.read<DeckProvider>().updateCardContent(
                                deckId: widget.deckId,
                                positionId: card.positionId,
                                headers: headersToUpdate,
                                terms: termsToUpdate,
                              );

                              if (outerContext.mounted && success) {
                                saveSuccess = true;
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              } else if (outerContext.mounted) {
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  const SnackBar(content: Text('Không thể lưu. Thử lại sau!'), backgroundColor: Colors.redAccent)
                                );
                                if (builderContext.mounted) setDialogState(() => isDialogSaving = false);
                              }
                            } catch (e) {
                              if (outerContext.mounted) {
                                ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent));
                              }
                              if (builderContext.mounted) setDialogState(() => isDialogSaving = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: isDialogSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('LƯU THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    ).then((_) {
      // 1. Chỉ dọn dẹp controller sau khi Dialog đã đóng hẳn
      Future.delayed(const Duration(milliseconds: 100), () {
        for (var c in textControllers.values) c.dispose();
        for (var h in headerControllers.values) h.dispose();
      });
      
      // 2. LÀM MỚI DỮ LIỆU (Đợi animation đóng Dialog kết thúc hoàn toàn)
      if (saveSuccess && mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lưu thay đổi thành công!'), duration: Duration(seconds: 1))
            );
            setState(() => _isLoading = true);
            _loadStudyData();
          }
        });
      }
    });
  }

  Widget _buildEditorField(
    PersonalizedHeader header, 
    TextEditingController controller, 
    TextEditingController headerController,
    Map<String, dynamic> mState,
    StateSetter setDialogState,
  ) {
    final String? imageUrl = mState['imageUrl'];
    final String? localPath = mState['localPreviewPath'];
    final String? audioUrl = mState['audioUrl'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editable Group Name
          TextField(
            controller: headerController,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.0),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              suffixIcon: Icon(Icons.edit_rounded, size: 12, color: AppColors.primary.withOpacity(0.5)),
              suffixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 0),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Nhập nội dung...',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          
          // Image Preview and Editing
          if (imageUrl != null || localPath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imageUrl == 'uploading'
                        ? const Center(child: CircularProgressIndicator())
                        : (localPath != null
                            ? Image.file(File(localPath), fit: BoxFit.cover)
                            : Image.network(imageUrl!, fit: BoxFit.cover)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildMediaCircleButton(
                      icon: Icons.sync,
                      onTap: () => _pickImageForEditor(mState, setDialogState),
                      color: Colors.black.withAlpha(150),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildMediaCircleButton(
                      icon: Icons.delete_outline,
                      onTap: () => _removeImageFromEditor(mState, setDialogState),
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              if (imageUrl == null && localPath == null) ...[
                _buildMiniActionButton(
                  icon: Icons.add_photo_alternate_outlined,
                  onTap: () => _pickImageForEditor(mState, setDialogState),
                ),
                const SizedBox(width: 10),
              ],
              
              if (audioUrl == null || audioUrl == 'uploading') ...[
                _buildMiniActionButton(
                  icon: Icons.mic_none_rounded,
                  onTap: () => _startRecordingForEditor(mState, setDialogState),
                  isActive: audioUrl != null,
                  isLoading: audioUrl == 'uploading',
                ),
              ] else ...[
                _buildAudioPlayerBarInEditor(audioUrl, mState, setDialogState),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCircleButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildMiniActionButton({required IconData icon, required VoidCallback onTap, bool isActive = false, bool isLoading = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade200),
        ),
        child: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 18, color: isActive ? AppColors.primary : Colors.grey),
      ),
    );
  }

  // Logic xử lý Media trong Editor
  Future<void> _pickImageForEditor(Map<String, dynamic> mState, StateSetter setDialogState) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        final Uint8List? croppedImage = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(builder: (context) => ImageCropScreen(image: imageBytes)),
        );

        if (croppedImage != null) {
          final tempDir = await getTemporaryDirectory();
          final String localPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File file = File(localPath);
          await file.writeAsBytes(croppedImage);

          setDialogState(() {
            mState['localPreviewPath'] = localPath;
            mState['imageUrl'] = 'uploading';
          });

          final signatureData = await context.read<DeckProvider>().getCloudinarySignature(oldPublicId: mState['imagePublicId']);
          if (signatureData != null) {
            final uploadResult = await _cloudinaryService.uploadFile(file: file, signatureData: signatureData, resourceType: 'image');
            if (mounted && uploadResult != null) {
              setDialogState(() {
                mState['imageUrl'] = uploadResult.secureUrl;
                mState['imagePublicId'] = uploadResult.publicId;
              });
            } else {
              setDialogState(() => mState['imageUrl'] = null);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImageFromEditor(Map<String, dynamic> mState, StateSetter setDialogState) {
    // Không gọi deleteImage ở đây nữa để tránh mất dữ liệu khi chưa nhấn LƯU
    setDialogState(() {
      mState['imageUrl'] = null;
      mState['imagePublicId'] = null;
      mState['localPreviewPath'] = null;
    });
  }

  Future<void> _startRecordingForEditor(Map<String, dynamic> mState, StateSetter setDialogState) async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) return;

      final tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Đang thu âm...', style: TextStyle(fontSize: 16)),
          content: const Icon(Icons.mic, size: 50, color: Colors.redAccent),
          actions: [
            TextButton(onPressed: () async { await _audioRecorder.stop(); Navigator.pop(ctx); }, child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final pathResult = await _audioRecorder.stop();
                Navigator.pop(ctx);
                if (pathResult != null) {
                  setDialogState(() => mState['audioUrl'] = 'uploading');
                  final File file = File(pathResult);
                  final bytes = await file.readAsBytes();
                  final uploadResult = await context.read<DeckProvider>().uploadAudio(pathResult.split('/').last, bytes, oldObjectKey: mState['audioObjectKey']);
                  if (uploadResult != null) {
                    setDialogState(() {
                      mState['audioUrl'] = uploadResult['url'];
                      mState['audioObjectKey'] = uploadResult['objectKey'];
                    });
                  } else {
                    setDialogState(() => mState['audioUrl'] = null);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Dừng & Tải lên'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error recording: $e');
    }
  }

  void _removeAudioFromEditor(Map<String, dynamic> mState, StateSetter setDialogState) {
    // Không gọi deleteAudio ở đây nữa để tránh mất dữ liệu khi chưa nhấn LƯU
    setDialogState(() {
      mState['audioUrl'] = null;
      mState['audioObjectKey'] = null;
    });
  }

  Widget _buildAudioPlayerBarInEditor(String audioUrl, Map<String, dynamic> mState, StateSetter setDialogState) {
    return ValueListenableBuilder<String?>(
      valueListenable: _playingUrlNotifier,
      builder: (context, currentPlayingUrl, _) {
        final bool isPlaying = currentPlayingUrl == audioUrl;
        
        return ValueListenableBuilder<Duration>(
          valueListenable: _audioDurationNotifier,
          builder: (context, totalDuration, _) {
            final Duration duration = isPlaying ? totalDuration : Duration.zero;
            
            return ValueListenableBuilder<Duration>(
              valueListenable: _audioPositionNotifier,
              builder: (context, position, _) {
                final double progress = (isPlaying && duration.inMilliseconds > 0)
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Nút Play/Stop
                        _buildMediaCircleButton(
                          icon: isPlaying ? Icons.stop : Icons.play_arrow,
                          onTap: () => _playAudio(audioUrl),
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        // Thông tin thời gian & Tiến trình
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPlaying
                                    ? "${_formatDurationShort(position)} / ${_formatDurationShort(duration)}"
                                    : "0:00 / 0:00",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nút Thay đổi
                        IconButton(
                          onPressed: () => _startRecordingForEditor(mState, setDialogState),
                          icon: const Icon(Icons.sync_rounded, size: 20, color: Colors.grey),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        // Nút Xóa
                        IconButton(
                          onPressed: () => _removeAudioFromEditor(mState, setDialogState),
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    );
  }

  String _formatDurationShort(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_studyData == null || _studyData!.flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deckName)),
        body: const Center(child: Text('Không có nội dung để học.')),
      );
    }

    final currentCard = _studyData!.flashcards[_currentIndex];
    final headers = _studyData!.headers;
    
    if (headers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_studyData!.title)),
        body: const Center(child: Text('Bộ thẻ này không có dữ liệu hiển thị.')),
      );
    }
    
    // Áp dụng Lexicographical Ordering:
    // Vì Backend đã sắp xếp headers theo Rank (A < B < ZZ), 
    // ta mặc định lấy phần tử đầu tiên làm Mặt trước, phần tử thứ hai làm Mặt sau.
    final headerFront = headers[0];
    final headerBack = headers.length > 1 ? headers[1] : headerFront;
    
    // Các nhóm còn lại (từ vị trí thứ 2 trở đi) dùng làm bong bóng phụ (bubbles)
    final bubbleHeaders = headers
        .skip(headers.length > 1 ? 2 : 1)
        .where((h) {
          final cell = currentCard.cardData.firstWhere(
            (c) => c.groupId == h.groupId,
            orElse: () => CardCell(termId: 0, groupId: 0, text: ""),
          );
          return cell.text.trim().isNotEmpty || cell.imageUrl != null || cell.audioUrl != null;
        })
        .take(6)
        .toList();

    // Lấy dữ liệu ô hiện tại (Mặt trước/sau)
    final activeHeader = _isCardFlipped ? headerBack : headerFront;
    final activeCell = currentCard.cardData.firstWhere(
      (c) => c.groupId == activeHeader.groupId,
      orElse: () => currentCard.cardData[0],
    );

    if (_isFinished) {
      return _buildSummaryScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _showExitConfirmation();
        if (shouldPop && mounted) {
          _handleEarlyExit();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              final bool shouldPop = await _showExitConfirmation();
              if (shouldPop && mounted) {
                _handleEarlyExit();
              }
            },
          ),
          title: Text(_studyData!.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [
            const SizedBox(width: 48), // Giữ khoảng trống để title vẫn ở giữa
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            _buildStatusBadge(currentCard.studyState.status),
            const SizedBox(height: 20),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Tầng Nền chính (Main Flashcard Canvas)
                    GestureDetector(
                      onTap: _flipCard,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.82,
                        height: MediaQuery.of(context).size.height * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Nội dung Text chính
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Hiển thị Ảnh nếu có
                                    if (activeCell.imageUrl != null)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 20),
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          image: DecorationImage(
                                            image: NetworkImage(activeCell.imageUrl!),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      activeCell.text,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: _isCardFlipped ? 32 : 50,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Nút cài đặt ở góc trái
                            Positioned(
                              top: 8,
                              left: 8,
                              child: IconButton(
                                icon: const Icon(Icons.settings_outlined,
                                    color: Colors.black26, size: 22),
                                onPressed: () => _showCardSettings(currentCard),
                              ),
                            ),
                            // Nút phát âm thanh ở góc nếu có
                            if (activeCell.audioUrl != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: ValueListenableBuilder<String?>(
                                  valueListenable: _playingUrlNotifier,
                                  builder: (context, playingUrl, _) {
                                    final bool isPlaying = playingUrl == activeCell.audioUrl;
                                    return IconButton(
                                      icon: isPlaying
                                          ? const Icon(Icons.stop_circle_rounded, color: AppColors.primary, size: 32)
                                          : const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
                                      onPressed: () => _playAudio(activeCell.audioUrl!),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 2. Tầng Cột Bong Bóng Mép Phải (Edge Bubbles Sidebar - Pinned to Screen Edge)
                    Positioned(
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: bubbleHeaders.map((header) => _buildEdgeBubble(header)).toList(),
                      ),
                    ),

                    // 3. Tầng Pop-up Thẻ Phụ (Mini-Flashcard Pop-up Note)
                    if (_activeGroupIdForPopup != null)
                      Positioned(
                        top: 20,
                        right: 65, // Ngay cạnh Sidebar đã được nới rộng
                        child: _buildMiniFlashcard(currentCard, bubbleHeaders),
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Rating Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo_rounded),
                        color: _currentIndex > 0 ? AppColors.textPrimary : Colors.grey.withValues(alpha: 0.3),
                        onPressed: _currentIndex > 0 ? _previousCard : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentIndex + 1} / ${_studyData!.flashcards.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 48), // Để cân bằng vị trí text ở giữa
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ratingButton('HARD', Colors.red, () => _submitRating('HARD')),
                      _ratingButton('NORMAL', Colors.orange, () => _submitRating('NORMAL')),
                      _ratingButton('EASY', Colors.green, () => _submitRating('EASY')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeBubble(PersonalizedHeader header) {
    bool isActive = _activeGroupIdForPopup == header.groupId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeGroupIdForPopup = isActive ? null : header.groupId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            header.groupName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniFlashcard(Flashcard card, List<PersonalizedHeader> headers) {
    final activeHeader = headers.firstWhere((h) => h.groupId == _activeGroupIdForPopup);
    final content = card.cardData.firstWhere((c) => c.groupId == activeHeader.groupId);

    return Container(
      width: 220, // Tăng chiều rộng từ 180
      padding: const EdgeInsets.all(20), // Tăng padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(5, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activeHeader.groupName,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (content.imageUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 110, // Tăng chiều cao ảnh từ 80
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(content.imageUrl!), fit: BoxFit.contain),
              ),
            ),
          Text(
            content.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Tăng font size từ 16
          ),
          if (content.audioUrl != null) ...[
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: _playingUrlNotifier,
              builder: (context, playingUrl, _) {
                final bool isPlaying = playingUrl == content.audioUrl;
                return IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  onPressed: () => _playAudio(content.audioUrl!),
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'NEW':
        color = Colors.blue;
        label = 'THẺ MỚI';
        break;
      case 'LEARNING':
        color = Colors.orange;
        label = 'ĐANG HỌC';
        break;
      case 'REVIEW':
        color = Colors.green;
        label = 'ÔN TẬP';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final data = _summaryData;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.stars_rounded, size: 80, color: AppColors.accent),
              const SizedBox(height: 16),
              const Text(
                'Tuyệt vời!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const Text(
                'Bạn đã hoàn thành phiên học hôm nay',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // EXP Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Kinh nghiệm', '+${data?['expGained'] ?? 0}', Icons.bolt_rounded, Colors.orange),
                        _buildStatItem('Chuỗi học', '${data?['currentStreak'] ?? 0} ngày', Icons.local_fire_department_rounded, Colors.red),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Thẻ mới', '${data?['cardsLearned'] ?? _cardsLearnedCount}', Icons.fiber_new_rounded, Colors.blue),
                        _buildStatItem('Ôn tập', '${data?['cardsReviewed'] ?? _cardsReviewedCount}', Icons.loop_rounded, Colors.purple),
                        _buildStatItem(
                          'Thời gian', 
                          _formatDuration(DateTime.now().difference(_startTime)), 
                          Icons.timer_rounded, 
                          Colors.teal
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Total EXP Progress
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'EXP nhận được: +${data?['expGained'] ?? 0}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('TIẾP TỤC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes ph $seconds s';
    }
    return '$seconds s';
  }
}
