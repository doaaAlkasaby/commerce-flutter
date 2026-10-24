import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_config.g.dart';

class TenantConfig {
  final String tenantId;
  final String appName;
  final String apiBaseUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String currencySymbol;
  final String? logoUrl;

  const TenantConfig({
    required this.tenantId,
    required this.appName,
    required this.apiBaseUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.currencySymbol,
    this.logoUrl,
  });

  factory TenantConfig.defaultTenant() {
    return const TenantConfig(
      tenantId: 'little_ones_store',
      appName: 'Little Ones',
      apiBaseUrl: 'https://api.ecommerce-saas.com/v1',
      primaryColor: Color(0xFF8B263E), // Terracotta/burgundy accent
      secondaryColor: Color(0xFFF9F6F0), // Warm off-white background
      currencySymbol: '\$',
    );
  }
}

@Riverpod(keepAlive: true)
class TenantNotifier extends _$TenantNotifier {
  @override
  TenantConfig build() {
    return TenantConfig.defaultTenant();
  }

  void setTenant(TenantConfig config) {
    state = config;
  }
}
