import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';

class FlashcardLearningScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const FlashcardLearningScreen({super.key, required this.deckId, required this.deckName});

  @override
  State<FlashcardLearningScreen> createState() => _FlashcardLearningScreenState();
}

class _FlashcardLearningScreenState extends State<FlashcardLearningScreen> {
  late List<Flashcard> _cards;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _showReading = false;

  @override
  void initState() {
    super.initState();
    _cards = context.read<DeckProvider>().getMockCardsForDeck(widget.deckId);
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _showReading = false;
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
    final card = _cards[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.deckName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          const Icon(Icons.stars_rounded, color: AppColors.accent),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Flashcard Main Area
                GestureDetector(
                  onTap: _flipCard,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
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
                    child: Center(
                      child: Text(
                        _isFlipped ? card.meaning : card.kanji,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _isFlipped ? 32 : 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Reading Overlay (Small popup hint in Mockup 4)
                if (!_isFlipped && _showReading)
                  Positioned(
                    top: 40,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Text(card.hiragana, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Side Tabs (Mockup 2, 3)
                Positioned(
                  right: 0,
                  child: Column(
                    children: [
                      _sideTab('Hiragana', () => setState(() => _showReading = !_showReading)),
                      const SizedBox(height: 12),
                      _sideTab('Hán Việt', () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Progress and Rating (Mockup 2 bottom)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Text('${_currentIndex + 1} / ${_cards.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ratingButton('HARD', Colors.red, _nextCard),
                    _ratingButton('NORMAL', Colors.orange, _nextCard),
                    _ratingButton('EASY', Colors.green, _nextCard),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideTab(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ),
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
