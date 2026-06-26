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
  bool _isFetchingPublic = false;
  bool _isFetchingMy = false;
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
    if (_token == token && (_publicDecks.isNotEmpty || _isFetchingPublic)) return;

    bool tokenChanged = _token != token;
    _token = token;

    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    } else {
      _dio.options.headers.remove('Authorization');
    }

    Future.microtask(() {
      if (tokenChanged) {
        if (_token == null) {
          _myDecks = [];
          notifyListeners();
          fetchPublicDecks();
        } else {
          fetchMyDecks();
          fetchPublicDecks();
        }
      } else if (_publicDecks.isEmpty && !_isFetchingPublic) {
        fetchPublicDecks();
      }
    });
  }

  Future<void> fetchPublicDecks() async {
    if (_isFetchingPublic) return;
    _isFetchingPublic = true;
    try {
      final response = await _dio.get('/decks');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        _publicDecks = data.map((item) => Deck.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching public decks: $e');
    } finally {
      _isFetchingPublic = false;
    }
  }

  Future<void> fetchMyDecks() async {
    if (_isFetchingMy) return;
    _isFetchingMy = true;
    _isLoading = true;
    
    // Thông báo trạng thái loading sau khi kết thúc build hiện tại
    Future.delayed(Duration.zero, () => notifyListeners());

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
      _isFetchingMy = false;
      notifyListeners();
    }
  }

  Future<void> fetchDecks() async => fetchMyDecks();

  Future<bool> toggleFavorite(int deckId, bool isFavorite) async {
    try {
      final response = await _dio.patch('/decks/$deckId/toggle-favorite', data: {
        'isFavorite': !isFavorite,
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

  Future<void> likeComment(int commentId) async {
    try {
      await _dio.post('/comments/$commentId/like');
    } catch (e) {
      debugPrint('Error liking comment: $e');
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
    debugPrint('Study progress locally updated for position: $positionId with rating: $rating');
  }

  /// Tải file audio lên Cloudflare R2 thông qua Pre-signed URL từ Backend
  Future<String?> uploadAudio(String fileName, List<int> fileBytes) async {
    try {
      // 1. Lấy Pre-signed URL từ Backend
      final urlResponse = await _dio.post('/audio/generate-upload-url', data: {
        'fileName': fileName,
      });

      if (urlResponse.statusCode == 200 && urlResponse.data['success'] == true) {
        final String uploadUrl = urlResponse.data['data']['uploadUrl'];
        final String fileUrl = urlResponse.data['data']['fileUrl'];

        // 2. Tải bytes lên Cloudflare R2 bằng phương thức PUT
        final uploadDio = Dio();
        final response = await uploadDio.put(
          uploadUrl,
          data: fileBytes, // Truyền trực tiếp list bytes
          options: Options(
            headers: {
              Headers.contentLengthHeader: fileBytes.length,
              'Content-Type': 'application/octet-stream', // Xác định kiểu dữ liệu
            },
          ),
        );

        if (response.statusCode == 200) {
          return fileUrl;
        }
      }
    } catch (e) {
      debugPrint('Error uploading audio: $e');
    }
    return null;
  }
}
