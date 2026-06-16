import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../utils/constants.dart';

class DeckStudyData {
  final int deckId;
  final String title;
  final List<PersonalizedHeader> headers;
  final List<Flashcard> flashcards;

  DeckStudyData({
    required this.deckId,
    required this.title,
    required this.headers,
    required this.flashcards,
  });
}

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  bool _isLoading = false;
  String? _token;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  List<Deck> get decks => _decks;
  bool get isLoading => _isLoading;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<void> fetchDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Use /my-decks if logged in, otherwise /decks
      final endpoint = _token != null ? '/decks/my-decks' : '/decks';
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _decks = data.map((item) => Deck.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching decks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/decks/my-decks');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _decks = data.map((item) => Deck.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching my decks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(int deckId, bool isFavorite) async {
    try {
      final response = await _dio.patch('/decks/$deckId/toggle-favorite', data: {
        'isFavorite': isFavorite,
      });
      if (response.statusCode == 200) {
        // Refresh local data
        await fetchDecks();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchComments(int deckId) async {
    try {
      final response = await _dio.get('/decks/$deckId/comments');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }
    return [];
  }

  Future<bool> addComment(int deckId, String content, {int? parentCommentId}) async {
    try {
      final response = await _dio.post('/decks/$deckId/comments', data: {
        'content': content,
        'parentCommentId': parentCommentId,
      });
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  Future<DeckStudyData?> fetchDeckStudyData(int deckId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Khớp với route backend: /api/v1/decks/<id>/study
      final response = await _dio.get('/decks/$deckId/study');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return DeckStudyData(
          deckId: data['deckId'],
          title: data['title'],
          headers: (data['personalizedHeaders'] as List)
              .map((h) => PersonalizedHeader.fromJson(h))
              .toList(),
          flashcards: (data['flashcards'] as List)
              .map((f) => Flashcard.fromJson(f))
              .toList(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching study data: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Deprecated helper to avoid immediate breakage in other files
  Future<List<Flashcard>> fetchDeckDetails(int deckId) async {
    final studyData = await fetchDeckStudyData(deckId);
    return studyData?.flashcards ?? [];
  }

  Future<bool> bulkImport({
    required String deckTitle,
    required String publicStatus,
    required int? parentId,
    required List<Map<String, dynamic>> headers,
    required List<Map<String, dynamic>> rows,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post(
        '/decks/bulk-import',
        data: {
          "deckTitle": deckTitle,
          "publicStatus": publicStatus,
          "parentId": parentId,
          "headers": headers,
          "rows": rows,
        },
      );

      if (response.statusCode == 200) {
        await fetchDecks();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during bulk import: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDeck(int deckId) async {
    try {
      final response = await _dio.delete('/decks/$deckId');
      if (response.statusCode == 200) {
        await fetchDecks();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting deck: $e');
      return false;
    }
  }

  // New: Update SM-2 progress
  Future<void> updateStudyProgress(int positionId, String rating) async {
    try {
      // rating can be 'HARD', 'NORMAL', 'EASY'
      await _dio.post('/decks/study-progress', data: {
        'positionId': positionId,
        'rating': rating,
      });
    } catch (e) {
      debugPrint('Error updating study progress: $e');
    }
  }
}
