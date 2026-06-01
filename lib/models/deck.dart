class Deck {
  final int id;
  final String name;
  final String? description;
  final int totalCards;

  Deck({
    required this.id,
    required this.name,
    this.description,
    this.totalCards = 0,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      name: json['name'] ?? '',
      description: json['description'],
      totalCards: json['total_cards'] is String ? int.tryParse(json['total_cards']) ?? 0 : (json['total_cards'] ?? 0),
    );
  }
}
