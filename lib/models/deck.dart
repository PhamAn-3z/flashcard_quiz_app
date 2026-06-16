class Deck {
  final int id;
  final String title;
  final int? parentId;
  final String publicStatus;
  final bool isFavorite;
  final DateTime? lastStudiedAt;
  final List<Deck> subDecks;
  final Map<String, int>? ankiStats; // Thêm trường này

  Deck({
    required this.id,
    required this.title,
    this.parentId,
    required this.publicStatus,
    required this.isFavorite,
    this.lastStudiedAt,
    required this.subDecks,
    this.ankiStats,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    var subDecksList = json['subDecks'] as List? ?? json['sub_decks'] as List? ?? [];
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
      subDecks: subDecks,
      ankiStats: json['ankiStats'] != null ? Map<String, dynamic>.from(json['ankiStats']).map((k, v) => MapEntry(k, (v as num).toInt())) : null,
    );
  }

  // Support for existing UI that uses .name
  String get name => title;

  // Tính tổng số thẻ.
  int get totalCards {
    // Ưu tiên tính từ ankiStats (cho bộ thẻ cá nhân)
    if (ankiStats != null) {
      return (ankiStats!['newCount'] ?? 0) + 
             (ankiStats!['learningCount'] ?? 0) + 
             (ankiStats!['dueCount'] ?? 0);
    }
    // Nếu không có stats (cho bộ thẻ công khai), có thể BE trả về trường khác hoặc mặc định
    return 0;
  }
}
