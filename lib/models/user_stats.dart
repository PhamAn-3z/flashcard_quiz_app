class UserStats {
  final int currentStreak;
  final int maxStreak;
  final int totalExp;
  final int level;
  final String? lastStudyDate;

  UserStats({
    required this.currentStreak,
    required this.maxStreak,
    required this.totalExp,
    required this.level,
    this.lastStudyDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentStreak: json['current_streak'] ?? 0,
      maxStreak: json['max_streak'] ?? 0,
      totalExp: json['total_exp'] ?? 0,
      level: json['level'] ?? 1,
      lastStudyDate: json['last_study_date'],
    );
  }

  UserStats copyWith({
    int? currentStreak,
    int? maxStreak,
    int? totalExp,
    int? level,
    String? lastStudyDate,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      totalExp: totalExp ?? this.totalExp,
      level: level ?? this.level,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    );
  }
}
