class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? gender;
  final String? birthDate;
  final String? phoneNumber;
  final String role;
  final bool isPremium;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.gender,
    this.birthDate,
    this.phoneNumber,
    required this.role,
    this.isPremium = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] ?? '',
      gender: json['gender'],
      birthDate: json['birth_date'],
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'user',
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'gender': gender,
      'birth_date': birthDate,
      'phone_number': phoneNumber,
      'role': role,
      'is_premium': isPremium,
    };
  }
}
