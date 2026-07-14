import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'comments_screen.dart';
import '../providers/auth_provider.dart';

class FlashcardLearningScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const FlashcardLearningScreen({super.key, required this.deckId, required this.deckName});

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
  String? _currentlyPlayingUrl;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadStudyData();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          if (state == PlayerState.playing) {
            // Đã có logic trong _playAudio
          } else {
            _currentlyPlayingUrl = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_currentlyPlayingUrl == url) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingUrl = null);
      } else {
        setState(() => _currentlyPlayingUrl = url);
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() => _currentlyPlayingUrl = null);
    }
  }

  Future<void> _loadStudyData() async {
    final data = await context.read<DeckProvider>().fetchDeckStudyData(widget.deckId);
    if (mounted) {
      setState(() {
        _studyData = data;
        _isLoading = false;
      });
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
                  label: 'Chỉnh sửa thẻ',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.refresh_rounded,
                  label: 'Đặt lại tiến độ',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.info_outline_rounded,
                  label: 'Thông tin SRS',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    _showCardInfo(card);
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

  void _showCardInfo(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thông tin thẻ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trạng thái: ${card.studyState.status}'),
            Text('Độ dễ (Ease): ${card.studyState.easeFactor}'),
            Text('Số lần ôn tập: ${card.studyState.reviewCount}'),
            Text('Khoảng cách (Interval): ${card.studyState.interval} ngày'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
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
    
    // Tìm Rank A và B. Nếu không có (với bộ đề mới), lấy nhóm thứ 1 và thứ 2 làm mặc định.
    final headerFront = headers.any((h) => h.personalizedRank == 'A')
        ? headers.firstWhere((h) => h.personalizedRank == 'A')
        : headers[0];

    final headerBack = headers.any((h) => h.personalizedRank == 'B')
        ? headers.firstWhere((h) => h.personalizedRank == 'B')
        : (headers.length > 1 ? headers[1] : headers[0]);
    
    // Các nhóm còn lại dùng làm bong bóng phụ (bubbles)
    final bubbleHeaders = headers
        .where((h) => h.groupId != headerFront.groupId && h.groupId != headerBack.groupId)
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
            IconButton(
              icon: const Icon(Icons.comment_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommentsScreen(
                      deckId: widget.deckId,
                      deckTitle: _studyData!.title,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 40),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Tầng Nền chính (Main Flashcard Canvas)
                  GestureDetector(
                    onTap: _flipCard,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.80,
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
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: _currentlyPlayingUrl == activeCell.audioUrl
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      )
                                    : const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
                                onPressed: () => _playAudio(activeCell.audioUrl!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 3. Tầng Pop-up Thẻ Phụ (Mini-Flashcard Pop-up Note)
                  if (_activeGroupIdForPopup != null)
                    Positioned(
                      top: 20,
                      right: MediaQuery.of(context).size.width * 0.15,
                      child: _buildMiniFlashcard(currentCard, bubbleHeaders),
                    ),

                  // 2. Tầng Cột Bong Bóng Mép Phải (Edge Bubbles Sidebar)
                  Positioned(
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: bubbleHeaders.map((header) => _buildEdgeBubble(header)).toList(),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
              fontSize: 11,
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
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(5, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activeHeader.groupName,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (content.imageUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: NetworkImage(content.imageUrl!), fit: BoxFit.contain),
              ),
            ),
          Text(
            content.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (content.audioUrl != null) ...[
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 24),
              onPressed: () => _playAudio(content.audioUrl!),
            ),
          ]
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
