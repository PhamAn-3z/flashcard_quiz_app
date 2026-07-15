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

  Flashcard copyWith({
    int? positionId,
    int? colIndex,
    StudyState? studyState,
    List<CardCell>? cardData,
  }) {
    return Flashcard(
      positionId: positionId ?? this.positionId,
      colIndex: colIndex ?? this.colIndex,
      studyState: studyState ?? this.studyState,
      cardData: cardData ?? this.cardData,
    );
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawCardData = json['cardData'] ?? json['card_data'] ?? [];
    return Flashcard(
      positionId: json['positionId'] ?? json['position_id'] ?? 0,
      colIndex: json['colIndex'] ?? json['col_index'] ?? 0,
      studyState: StudyState.fromJson(json['studyState'] ?? json['study_state'] ?? {}),
      cardData: rawCardData.map((i) => CardCell.fromJson(i)).toList(),
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

  StudyState copyWith({
    String? status,
    double? easeFactor,
    int? interval,
    int? reviewCount,
    DateTime? nextReview,
  }) {
    return StudyState(
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      reviewCount: reviewCount ?? this.reviewCount,
      nextReview: nextReview ?? this.nextReview,
    );
  }

  factory StudyState.fromJson(Map<String, dynamic> json) {
    return StudyState(
      status: json['status'] ?? 'NEW',
      easeFactor: (json['easeFactor'] ?? json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      interval: json['interval'] ?? 0,
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
      nextReview: DateTime.tryParse(json['nextReview'] ?? json['next_review'] ?? '') ?? DateTime.now(),
    );
  }
}

class CardCell {
  final int termId;
  final int groupId;
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final String? imagePublicId;
  final String? audioObjectKey;

  CardCell({
    required this.termId,
    required this.groupId,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    this.imagePublicId,
    this.audioObjectKey,
  });

  factory CardCell.fromJson(Map<String, dynamic> json) {
    final dynamic content = json['content'];
    String cellText = "";
    String? img;
    String? audio;
    String? imgId;
    String? audioKey;

    if (content is Map) {
      cellText = content['text']?.toString() ?? "";

      // Hỗ trợ cấu trúc lồng nhau mới
      if (content.containsKey('image') && content['image'] is Map) {
        img = content['image']['url'];
        imgId = content['image']['public_id'];
      } else {
        // Tương thích ngược với cấu trúc phẳng cũ
        img = content['image_url'];
      }

      if (content.containsKey('audio') && content['audio'] is Map) {
        audio = content['audio']['url'];
        audioKey = content['audio']['key'];
      } else {
        // Tương thích ngược với cấu trúc phẳng cũ
        audio = content['audio_url'];
      }
    } else if (content is String) {
      cellText = content;
    }

    return CardCell(
      termId: json['termId'] ?? json['term_id'] ?? 0,
      groupId: json['groupId'] ?? json['group_id'] ?? 0,
      text: cellText,
      imageUrl: img,
      audioUrl: audio,
      imagePublicId: imgId,
      audioObjectKey: audioKey,
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
