class MembershipPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final bool isActive;

  MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.isActive,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] ?? 0,
      name: json['membershipRank'] ?? '',
      description: 'Mở rộng tối đa ${json['maxFlashcardSet'] ?? 0} bộ thẻ học',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: _parseDuration(json['Duration']),
      isActive: json['isActive'] ?? true,
    );
  }

  static int _parseDuration(dynamic duration) {
    if (duration == null) return 0;
    String d = duration.toString().toLowerCase();
    // Ví dụ: "30 days" -> 30, "1 year" -> 365
    final match = RegExp(r'(\d+)').firstMatch(d);
    if (match != null) {
      int value = int.parse(match.group(1)!);
      if (d.contains('year')) return value * 365;
      if (d.contains('month')) return value * 30;
      return value;
    }
    return 0;
  }
}
