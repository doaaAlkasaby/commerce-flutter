class UserDto {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final bool isEmailVerified;

  String get fullName => '$firstName $lastName'.trim();

  const UserDto({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'CUSTOMER',
    this.isActive = true,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    required this.isEmailVerified,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final verifiedAt = json['emailVerifiedAt']?.toString();
    final verified = (verifiedAt != null && verifiedAt.isNotEmpty);

    return UserDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      isActive: json['isActive'] ?? true,
      emailVerifiedAt: verifiedAt,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isEmailVerified: verified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'isActive': isActive,
      'emailVerifiedAt': emailVerifiedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isEmailVerified': isEmailVerified,
    };
  }
}

class AuthDataDto {
  final String accessToken;
  final String refreshToken;
  final UserDto user;

  const AuthDataDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthDataDto.fromJson(Map<String, dynamic> json) {
    return AuthDataDto(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      user: UserDto.fromJson(json['user'] ?? {}),
    );
  }
}
