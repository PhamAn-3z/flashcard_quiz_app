import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../utils/constants.dart';

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  bool _isLoading = false;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  List<Deck> get decks => _decks;
  bool get isLoading => _isLoading;

  DeckProvider() {
    fetchDecks();
  }

  void _loadMockDecks() {
    _decks = [
      Deck(id: 1, name: 'Flashcard Kanji N5', description: 'Cơ bản', totalCards: 20),
      Deck(id: 2, name: 'Flashcard Từ vựng N4', description: 'Trung cấp', totalCards: 50),
      Deck(id: 3, name: 'Bộ thẻ N3', description: 'Nâng cao', totalCards: 15),
    ];
  }

  List<Flashcard> getMockCardsForDeck(int deckId) {
    return [
      Flashcard(
        id: '1',
        kanji: '記憶',
        hiragana: 'きおく',
        hanViet: 'Ký ức',
        meaning: 'Trí nhớ, ký ức',
      ),
      Flashcard(
        id: '2',
        kanji: '勉強',
        hiragana: 'べんきょう',
        hanViet: 'Miễn cưỡng',
        meaning: 'Học tập',
      ),
      Flashcard(
        id: '3',
        kanji: '学校',
        hiragana: 'がっこう',
        hanViet: 'Học hiệu',
        meaning: 'Trường học',
      ),
    ];
  }

  Future<void> fetchDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/decks');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
        _decks = data.map((item) => Deck.fromJson(item)).toList();

        // Nếu API thành công nhưng mảng rỗng, vẫn load mock để giao diện đẹp (cho mục đích demo)
        if (_decks.isEmpty) {
          _loadMockDecks();
        }
      }
    } catch (e) {
      debugPrint('Error fetching decks: $e');
      if (_decks.isEmpty) {
        _loadMockDecks();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
