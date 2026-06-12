class Deck {
  final int id;
  final String title;
  final int? parentId;
  final String publicStatus;
  final bool isFavorite;
  final DateTime? lastStudiedAt;
  final List<Deck> subDecks;

  Deck({
    required this.id,
    required this.title,
    this.parentId,
    required this.publicStatus,
    required this.isFavorite,
    this.lastStudiedAt,
    required this.subDecks,
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
    );
  }

  // Support for existing UI that uses .name
  String get name => title;
  // Support for existing UI that uses .totalCards
  int get totalCards => 0; // Backend stats could be added here if needed
}
