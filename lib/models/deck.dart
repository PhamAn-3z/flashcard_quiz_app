class Deck {
  final int id;
  final String title;
  final int? parentId;
  final String publicStatus;
  final bool isFavorite;
  final bool isInLibrary;
  final DateTime? lastStudiedAt;
  final DateTime? createdAt;
  final int totalCards;
  final DeckAuthor? author;
  final AnkiStats ankiStats;
  final DeckStats? stats;
  final List<Deck> subDecks;

  Deck({
    required this.id,
    required this.title,
    this.parentId,
    this.publicStatus = 'private',
    this.isFavorite = false,
    this.isInLibrary = false,
    this.lastStudiedAt,
    this.createdAt,
    this.totalCards = 0,
    this.author,
    required this.ankiStats,
    this.stats,
    this.subDecks = const [],
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    var subDecksList = (json['subDecks'] ?? json['sub_decks']) as List? ?? [];
    List<Deck> subDecks = subDecksList.map((i) => Deck.fromJson(i)).toList();

    // 1. Lấy Anki Stats (Cá nhân hóa)
    Map<String, dynamic> ankiData = {};
    if (json['ankiStats'] != null) {
      ankiData = Map<String, dynamic>.from(json['ankiStats']);
    } else if (json['anki_stats'] != null) {
      ankiData = Map<String, dynamic>.from(json['anki_stats']);
    }

    // 2. Nếu là dữ liệu Explore và chưa có dữ liệu học tập (AnkiData rỗng)
    // thì lấy totalCards làm newCount
    if (ankiData.isEmpty) {
      final totalCards = json['totalCards'] ?? json['total_cards'] ?? 0;
      ankiData = {
        'newCount': totalCards,
        'learningCount': 0,
        'dueCount': 0,
      };
    }

    return Deck(
      id: json['deckId'] ?? json['deck_id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      parentId: json['parentId'] ?? json['parent_id'],
      publicStatus: json['publicStatus'] ?? json['public_status'] ?? 'private',
      isFavorite: json['isFavorite'] ?? json['is_favorite'] ?? false,
      isInLibrary: json['isInLibrary'] ?? json['is_in_library'] ?? false,
      lastStudiedAt: json['lastStudiedAt'] != null 
          ? DateTime.tryParse(json['lastStudiedAt']) 
          : (json['last_studied_at'] != null ? DateTime.tryParse(json['last_studied_at']) : null),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null),
      totalCards: (json['totalCards'] ?? json['total_cards'] ?? 0) as int,
      author: json['author'] != null ? DeckAuthor.fromJson(json['author']) : null,
      ankiStats: AnkiStats.fromJson(ankiData),
      stats: json['stats'] != null ? DeckStats.fromJson(json['stats']) : null,
      subDecks: subDecks,
    );
  }

  String get name => title;

  // Thẻ đã học thuộc = Tổng - (Mới + Đang học + Đến hạn)
  int get masteredCount {
    int unmastered = ankiStats.newCount + ankiStats.learningCount + ankiStats.dueCount;
    // Nếu totalCards từ API lỗi hoặc bằng 0, ta tạm coi tổng = số thẻ chưa thuộc
    int total = totalCards > 0 ? totalCards : unmastered;
    return total > unmastered ? total - unmastered : 0;
  }

  // Cập nhật getter totalCards để luôn có giá trị hợp lệ
  int get effectiveTotalCards {
    int unmastered = ankiStats.newCount + ankiStats.learningCount + ankiStats.dueCount;
    return totalCards > 0 ? totalCards : unmastered;
  }

  Deck copyWith({
    bool? isFavorite,
    bool? isInLibrary,
    DateTime? createdAt,
    List<Deck>? subDecks,
  }) {
    return Deck(
      id: id,
      title: title,
      parentId: parentId,
      publicStatus: publicStatus,
      isFavorite: isFavorite ?? this.isFavorite,
      isInLibrary: isInLibrary ?? this.isInLibrary,
      lastStudiedAt: lastStudiedAt,
      createdAt: createdAt ?? this.createdAt,
      author: author,
      ankiStats: ankiStats,
      stats: stats,
      subDecks: subDecks ?? this.subDecks,
    );
  }
}

class DeckAuthor {
  final String username;
  final String? avatarUrl;

  DeckAuthor({required this.username, this.avatarUrl});

  factory DeckAuthor.fromJson(Map<String, dynamic> json) {
    return DeckAuthor(
      username: json['username'] ?? 'Ẩn danh',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }
}

class AnkiStats {
  final int newCount;
  final int learningCount;
  final int dueCount;

  AnkiStats({this.newCount = 0, this.learningCount = 0, this.dueCount = 0});

  factory AnkiStats.fromJson(Map<String, dynamic> json) {
    return AnkiStats(
      newCount: (json['newCount'] ?? json['new_count'] ?? (json['totalCards'] ?? 0)) as int,
      learningCount: (json['learningCount'] ?? json['learning_count'] ?? 0) as int,
      dueCount: (json['dueCount'] ?? json['due_count'] ?? 0) as int,
    );
  }
}

class DeckStats {
  final int favoritesCount;
  final int totalViews;
  final int viewsToday;

  DeckStats({
    this.favoritesCount = 0,
    this.totalViews = 0,
    this.viewsToday = 0,
  });

  factory DeckStats.fromJson(Map<String, dynamic> json) {
    return DeckStats(
      favoritesCount: json['favoritesCount'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      viewsToday: json['viewsToday'] ?? 0,
    );
  }
}
