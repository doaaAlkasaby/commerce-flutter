class UserDto {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isEmailVerified;

  const UserDto({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isEmailVerified,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
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
