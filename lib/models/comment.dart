class Comment {
  final int id;
  String content; // Bỏ final để có thể chèn mention
  final DateTime createdAt;
  final String username;
  final String? avatarUrl;
  final int totalLikes;
  final bool isLikedByMe;
  final int? parentId;
  List<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatarUrl,
    this.totalLikes = 0,
    this.isLikedByMe = false,
    this.parentId,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      parentId: json['parentId'], // Khớp với camelCase từ người dùng
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      username: json['username'] ?? 'Ẩn danh',
      avatarUrl: json['avatarUrl'],
      totalLikes: json['totalLikes'] ?? 0,
      isLikedByMe: json['isLikedByMe'] ?? false,
      replies: [], // Sẽ được đổ dữ liệu sau khi chạy thuật toán cây
    );
  }

  Comment copyWith({
    String? content,
    int? totalLikes,
    bool? isLikedByMe,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt,
      username: username,
      avatarUrl: avatarUrl,
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      parentId: parentId,
      replies: replies ?? this.replies,
    );
  }
}
