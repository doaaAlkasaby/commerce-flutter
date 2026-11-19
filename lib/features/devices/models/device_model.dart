class RegisterDeviceRequest {
  final String token;
  final String platform;
  final String? appVersion;

  const RegisterDeviceRequest({
    required this.token,
    required this.platform,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'platform': platform,
    if (appVersion != null) 'appVersion': appVersion,
  };
}

class DeviceDto {
  final String id;
  final String token;
  final String platform;
  final String? appVersion;
  final bool isActive;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceDto({
    required this.id,
    required this.token,
    required this.platform,
    this.appVersion,
    required this.isActive,
    required this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      appVersion: json['appVersion']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
