class Flashcard {
  final String id;
  final String kanji;
  final String hiragana;
  final String hanViet;
  final String meaning;
  final int difficulty;

  Flashcard({
    required this.id,
    required this.kanji,
    required this.hiragana,
    required this.hanViet,
    required this.meaning,
    this.difficulty = 1,
  });
}
