import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/comment.dart';
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
  List<Deck> _publicDecks = [];
  List<Deck> _myDecks = [];
  bool _isLoading = false;
  String? _token;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  List<Deck> get publicDecks => _publicDecks;
  List<Deck> get myDecks => _myDecks;
  List<Deck> get decks => _token != null ? _myDecks : _publicDecks;
  bool get isLoading => _isLoading;

  void updateToken(String? token) {
    bool tokenChanged = _token != token;
    _token = token;
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      if (tokenChanged) {
        Future.microtask(() {
          fetchPublicDecks();
          fetchMyDecks();
        });
      }
    } else {
      _dio.options.headers.remove('Authorization');
      if (tokenChanged) {
        _myDecks = [];
        Future.microtask(() {
          fetchPublicDecks();
          notifyListeners();
        });
      }
    }
    
    if (_publicDecks.isEmpty) {
      Future.microtask(() => fetchPublicDecks());
    }
  }

  Future<void> fetchPublicDecks() async {
    try {
      final response = await _dio.get('/decks');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        _publicDecks = data.map((item) => Deck.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching public decks: $e');
    }
  }

  Future<void> fetchMyDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/decks/my-decks');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        _myDecks = data.map((item) => Deck.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching my decks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Giữ lại để tương thích ngược
  Future<void> fetchDecks() async => fetchMyDecks();

  Future<bool> toggleFavorite(int deckId, bool isFavorite) async {
    try {
      final response = await _dio.patch('/decks/$deckId/toggle-favorite', data: {
        'isFavorite': isFavorite,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchMyDecks();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  Future<List<Comment>> fetchComments(int deckId) async {
    try {
      final response = await _dio.get('/decks/$deckId/comments');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => Comment.fromJson(item)).toList();
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
      return response.statusCode == 201 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await _dio.delete('/comments/$commentId');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  Future<DeckStudyData?> fetchDeckStudyData(int deckId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/decks/$deckId/study');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        // Tự động làm mới danh sách "Của tôi" để cập nhật thời gian học cuối cùng (last_studied_at)
        fetchMyDecks();

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

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchMyDecks();
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
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchMyDecks();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting deck: $e');
      return false;
    }
  }

  Future<void> updateStudyProgress(int positionId, String rating) async {
    // BE hiện tại chưa có API /decks/study-progress trong deck_routes.dart
    debugPrint('Study progress locally updated for position: $positionId with rating: $rating');
  }
}
