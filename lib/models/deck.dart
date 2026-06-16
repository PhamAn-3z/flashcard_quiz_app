class Deck {
  final int id;
  final String title;
  final int? parentId;
  final String publicStatus;
  final bool isFavorite;
  final DateTime? lastStudiedAt;
  final DeckAuthor? author;
  final AnkiStats ankiStats;
  final List<Deck> subDecks;

  Deck({
    required this.id,
    required this.title,
    this.parentId,
    this.publicStatus = 'private',
    this.isFavorite = false,
    this.lastStudiedAt,
    this.author,
    required this.ankiStats,
    this.subDecks = const [],
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    var subDecksList = (json['subDecks'] ?? json['sub_decks']) as List? ?? [];
    List<Deck> subDecks = subDecksList.map((i) => Deck.fromJson(i)).toList();

    return Deck(
      id: json['deckId'] ?? json['deck_id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      parentId: json['parentId'] ?? json['parent_id'],
      publicStatus: json['publicStatus'] ?? json['public_status'] ?? 'private',
      isFavorite: json['isFavorite'] ?? json['is_favorite'] ?? false,
      lastStudiedAt: json['lastStudiedAt'] != null 
          ? DateTime.tryParse(json['lastStudiedAt']) 
          : (json['last_studied_at'] != null ? DateTime.tryParse(json['last_studied_at']) : null),
      author: json['author'] != null ? DeckAuthor.fromJson(json['author']) : null,
      ankiStats: AnkiStats.fromJson(json['ankiStats'] ?? json['anki_stats'] ?? {}),
      subDecks: subDecks,
    );
  }

  String get name => title;

  // Tính tổng số thẻ từ ankiStats
  int get totalCards {
    return ankiStats.newCount + ankiStats.learningCount + ankiStats.dueCount;
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
      newCount: (json['newCount'] ?? json['new_count'] ?? 0) as int,
      learningCount: (json['learningCount'] ?? json['learning_count'] ?? 0) as int,
      dueCount: (json['dueCount'] ?? json['due_count'] ?? 0) as int,
    );
  }
}
