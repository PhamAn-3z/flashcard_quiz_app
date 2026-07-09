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
  List<Deck> _exploreDecks = [];
  List<Deck> _myDecks = [];
  List<dynamic> _recentDecks = []; // Lưu lịch sử học tập
  bool _isLoading = false;
  bool _isFetchingPublic = false;
  bool _isFetchingExplore = false;
  bool _isFetchingMy = false;
  bool _isFetchingRecent = false;
  String? _token;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Getters
  List<Deck> get publicDecks => _publicDecks;
  List<Deck> get exploreDecks => _exploreDecks;
  List<Deck> get myDecks => _myDecks;
  List<dynamic> get recentDecks => _recentDecks;
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

    Future.delayed(Duration.zero, () {
      if (tokenChanged) {
        if (_token == null) {
          _myDecks = [];
          notifyListeners();
          fetchPublicDecks();
          fetchExploreDecks(filter: 'not_in_library');
        } else {
          fetchMyDecks();
          fetchPublicDecks();
          fetchExploreDecks(filter: 'not_in_library');
        }
      } else if (_publicDecks.isEmpty && !_isFetchingPublic) {
        fetchPublicDecks();
        fetchExploreDecks(filter: 'not_in_library');
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

  Future<int> fetchExploreDecks({
    String sortBy = 'views_today',
    int limit = 10,
    int page = 1,
    String filter = 'not_in_library',
    String? searchTerm,
    bool append = false,
  }) async {
    if (_isFetchingExplore) return 0;
    _isFetchingExplore = true;
    
    // Nếu không phải nối thêm dữ liệu thì hiện loading
    if (!append) {
      _isLoading = true;
      notifyListeners();
    }

    int fetchedCount = 0;
    try {
      final response = await _dio.get('/decks/explore', queryParameters: {
        'sortBy': sortBy,
        'limit': limit,
        'page': page,
        'order': 'desc',
        'filter': filter,
        if (searchTerm != null && searchTerm.isNotEmpty) 'q': searchTerm,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final newDecks = data.map((item) => Deck.fromJson(item)).toList();
        fetchedCount = newDecks.length;
        
        if (append) {
          _exploreDecks.addAll(newDecks);
        } else {
          _exploreDecks = newDecks;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching explore decks: $e');
    } finally {
      _isFetchingExplore = false;
      _isLoading = false;
      notifyListeners();
    }
    return fetchedCount;
  }

  Future<void> fetchRecentDecks() async {
    if (_isFetchingRecent) return;
    _isFetchingRecent = true;
    try {
      final response = await _dio.get('/decks/recent', queryParameters: {'limit': 10});
      if (response.statusCode == 200 && response.data['success'] == true) {
        _recentDecks = response.data['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching recent decks: $e');
    } finally {
      _isFetchingRecent = false;
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
      if (e is DioException) {
        debugPrint('Error fetching my decks: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        debugPrint('Error fetching my decks: $e');
      }
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
    Future.delayed(Duration.zero, () => notifyListeners());
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
    Future.delayed(Duration.zero, () => notifyListeners());
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

  Future<bool> saveDeck(int deckId) async {
    // Cập nhật local ngay lập tức (Optimistic Update)
    _updateLocalDeckLibraryStatus(deckId, true);
    
    try {
      final response = await _dio.post('/decks/$deckId/save');
      if (response.statusCode == 200 && response.data['success'] == true) {
        fetchMyDecks(); // Chỉ tải lại thư viện cá nhân trong background
        return true;
      }
      _updateLocalDeckLibraryStatus(deckId, false); // Rollback nếu lỗi
      return false;
    } catch (e) {
      _updateLocalDeckLibraryStatus(deckId, false); // Rollback nếu lỗi
      debugPrint('Error saving deck: $e');
      return false;
    }
  }

  Future<bool> unsaveDeck(int deckId) async {
    _updateLocalDeckLibraryStatus(deckId, false);
    
    try {
      final response = await _dio.delete('/decks/$deckId/unsave');
      if (response.statusCode == 200 && response.data['success'] == true) {
        fetchMyDecks();
        return true;
      }
      _updateLocalDeckLibraryStatus(deckId, true);
      return false;
    } catch (e) {
      _updateLocalDeckLibraryStatus(deckId, true);
      debugPrint('Error unsaving deck: $e');
      return false;
    }
  }

  void _updateLocalDeckLibraryStatus(int deckId, bool isInLibrary) {
    // Cập nhật trong Explore list
    final exploreIndex = _exploreDecks.indexWhere((d) => d.id == deckId);
    if (exploreIndex != -1) {
      _exploreDecks[exploreIndex] = _exploreDecks[exploreIndex].copyWith(isInLibrary: isInLibrary);
    }
    
    // Cập nhật trong Public list (nếu có)
    final publicIndex = _publicDecks.indexWhere((d) => d.id == deckId);
    if (publicIndex != -1) {
      _publicDecks[publicIndex] = _publicDecks[publicIndex].copyWith(isInLibrary: isInLibrary);
    }
    
    notifyListeners();
  }

  Future<void> updateStudyProgress(int positionId, String rating) async {
    // Không gọi API ở đây nữa để tránh quá tải mạng và lag
    debugPrint('Card $positionId rated $rating - stored in local session');
  }

  Future<Map<String, dynamic>?> endStudySession({
    required int deckId,
    required int cardsLearned,
    required int cardsReviewed,
    required int durationSeconds,
    required List<Map<String, dynamic>> cardRatings,
  }) async {
    try {
      final response = await _dio.post(
        '/study-logs/session-end',
        data: {
          "deck_id": deckId,
          "cards_learned": cardsLearned,
          "cards_reviewed": cardsReviewed,
          "duration_seconds": durationSeconds,
          "card_ratings": cardRatings,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Tải lại cả danh sách cá nhân và khám phá để đồng bộ thông số
        await Future.wait([
          fetchMyDecks(),
          fetchExploreDecks(),
        ]);
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error ending study session: $e');
      return null;
    }
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
