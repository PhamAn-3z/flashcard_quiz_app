class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? gender;
  final String? birthDate;
  final String? phoneNumber;
  final String roleId;
  final bool isPremium;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.gender,
    this.birthDate,
    this.phoneNumber,
    required this.roleId,
    this.isPremium = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['user_id'] ?? json['id'] ?? '0').toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      gender: json['gender'],
      birthDate: json['birth_date'],
      phoneNumber: json['phone_number'],
      roleId: (json['role_id'] ?? json['role'] ?? '2').toString(),
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
      'role_id': roleId,
      'is_premium': isPremium,
    };
  }
}
