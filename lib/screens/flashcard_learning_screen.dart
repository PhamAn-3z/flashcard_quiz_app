import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'comments_screen.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadStudyData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error playing audio: $e');
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
    context.read<DeckProvider>().updateStudyProgress(currentCard.positionId, rating);

    // 2. Local state reset for next card
    if (_currentIndex < _studyData!.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isCardFlipped = false;
        _activeGroupIdForPopup = null;
      });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chúc mừng! Bạn đã hoàn thành bộ thẻ.')),
      );
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_studyData!.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                        // Nút phát âm thanh ở góc nếu có
                        if (activeCell.audioUrl != null)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
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
                Text('${_currentIndex + 1} / ${_studyData!.flashcards.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
}
