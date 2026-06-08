import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'flashcard_learning_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bộ Flashcard N5', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: deckProvider.isLoading && deckProvider.decks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : deckProvider.decks.isEmpty
              ? const Center(child: Text('Không có bộ thẻ nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: deckProvider.decks.length,
                  itemBuilder: (context, index) {
                    final deck = deckProvider.decks[index];
                    return _buildDeckCard(context, deck);
                  },
                ),
    );
  }

  Widget _buildDeckCard(BuildContext context, dynamic deck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  deck.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Mới: 7', Colors.blue),
              _buildMiniStat('Đang học: 5', Colors.orange),
              _buildMiniStat('Thuộc: 2', Colors.green),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardLearningScreen(deckId: deck.id, deckName: deck.name),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('HỌC', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }
}
