class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? profileImageUrl;
  final String preferredLanguage;
  final bool emailConfirmed;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.profileImageUrl,
    required this.preferredLanguage,
    required this.emailConfirmed,
  });

  // Alias for phone
  String? get phoneNumber => phone;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      preferredLanguage: json['preferredLanguage'] ?? 'ar',
      emailConfirmed: json['emailConfirmed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'preferredLanguage': preferredLanguage,
      'emailConfirmed': emailConfirmed,
    };
  }
}

class AuthResponse {
  final int userId;
  final String email;
  final String fullName;
  final String token;
  final DateTime expiresAt;
  final String role;
  final String preferredLanguage;

  AuthResponse({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.token,
    required this.expiresAt,
    required this.role,
    required this.preferredLanguage,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'],
      email: json['email'],
      fullName: json['fullName'],
      token: json['token'],
      expiresAt: DateTime.parse(json['expiresAt']),
      role: json['role'],
      preferredLanguage: json['preferredLanguage'] ?? 'ar',
    );
  }
}
