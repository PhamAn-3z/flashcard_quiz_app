class Flashcard {
  final int positionId;
  final int colIndex;
  final StudyState studyState;
  final List<CardCell> cardData;

  Flashcard({
    required this.positionId,
    required this.colIndex,
    required this.studyState,
    required this.cardData,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      positionId: json['positionId'],
      colIndex: json['colIndex'],
      studyState: StudyState.fromJson(json['studyState']),
      cardData: (json['cardData'] as List)
          .map((i) => CardCell.fromJson(i))
          .toList(),
    );
  }

  // Helper for quick access to text by groupId
  String getCellText(int groupId) {
    try {
      return cardData.firstWhere((cell) => cell.groupId == groupId).text;
    } catch (_) {
      return '';
    }
  }
}

class StudyState {
  final String status;
  final double easeFactor;
  final int interval;
  final int reviewCount;
  final DateTime nextReview;

  StudyState({
    required this.status,
    required this.easeFactor,
    required this.interval,
    required this.reviewCount,
    required this.nextReview,
  });

  factory StudyState.fromJson(Map<String, dynamic> json) {
    return StudyState(
      status: json['status'],
      easeFactor: (json['easeFactor'] as num).toDouble(),
      interval: json['interval'],
      reviewCount: json['reviewCount'],
      nextReview: DateTime.parse(json['nextReview']),
    );
  }
}

class CardCell {
  final int termId;
  final int groupId;
  final String text;
  final String? imageUrl;
  final String? audioUrl;

  CardCell({
    required this.termId,
    required this.groupId,
    required this.text,
    this.imageUrl,
    this.audioUrl,
  });

  factory CardCell.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return CardCell(
      termId: json['termId'],
      groupId: json['groupId'],
      text: content['text'] ?? '',
      imageUrl: content['image_url'],
      audioUrl: content['audio_url'],
    );
  }
}

class PersonalizedHeader {
  final int groupId;
  final String groupName;
  final int physicalPosition;
  final String personalizedRank;

  PersonalizedHeader({
    required this.groupId,
    required this.groupName,
    required this.physicalPosition,
    required this.personalizedRank,
  });

  factory PersonalizedHeader.fromJson(Map<String, dynamic> json) {
    return PersonalizedHeader(
      groupId: json['groupId'],
      groupName: json['groupName'],
      physicalPosition: json['physicalPosition'],
      personalizedRank: json['personalizedRank'],
    );
  }
}
