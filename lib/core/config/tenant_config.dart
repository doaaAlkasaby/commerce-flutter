import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/categories/presentation/providers/categories_provider.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/orders/presentation/providers/orders_provider.dart';

part 'tenant_config.g.dart';

@Riverpod(keepAlive: true)
class SelectedTenantSlugNotifier extends _$SelectedTenantSlugNotifier {
  @override
  String build() {
    try {
      final savedSlug = sharedPreferences.getString('selected_tenant_slug');
      if (savedSlug != null && savedSlug.isNotEmpty) {
        return savedSlug;
      }
    } catch (_) {}
    return AppEnvironment.defaultTenantSlug;
  }

  Future<void> setTenantSlug(String newSlug) async {
    if (newSlug.isEmpty || state == newSlug) return;

    try {
      await sharedPreferences.setString('selected_tenant_slug', newSlug);
    } catch (_) {}

    state = newSlug;

    // Asynchronously invalidate tenant-scoped providers that do not directly watch selectedTenantSlugProvider
    Future.microtask(() {
      ref.invalidate(homeDataProvider);
      ref.invalidate(mainCategoriesProvider);
      ref.invalidate(activeCategoriesListProvider);
      ref.invalidate(activeBrandsListProvider);
      ref.invalidate(cartProvider);
      ref.invalidate(myOrdersProvider);
    });
  }
}

class TenantConfig {
  final String tenantSlug;
  final String? tenantId;
  final String appName;
  final String apiBaseUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String currencySymbol;
  final String? logoUrl;

  const TenantConfig({
    required this.tenantSlug,
    this.tenantId,
    required this.appName,
    required this.apiBaseUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.currencySymbol,
    this.logoUrl,
  });

  factory TenantConfig.defaultTenant(String slug) {
    return TenantConfig(
      tenantSlug: slug,
      tenantId: null, // Tenant ID populated only from backend storefront
      appName: 'Store',
      apiBaseUrl: AppEnvironment.baseUrl,
      primaryColor: const Color(0xFF8B263E),
      secondaryColor: const Color(0xFFF9F6F0),
      currencySymbol: '', // Not hardcoding KWD for all merchants
    );
  }

  TenantConfig copyWith({
    String? tenantSlug,
    String? tenantId,
    String? appName,
    String? apiBaseUrl,
    Color? primaryColor,
    Color? secondaryColor,
    String? currencySymbol,
    String? logoUrl,
  }) {
    return TenantConfig(
      tenantSlug: tenantSlug ?? this.tenantSlug,
      tenantId: tenantId ?? this.tenantId,
      appName: appName ?? this.appName,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}

@Riverpod(keepAlive: true)
class TenantNotifier extends _$TenantNotifier {
  @override
  TenantConfig build() {
    final slug = ref.watch(selectedTenantSlugProvider);
    return TenantConfig.defaultTenant(slug);
  }

  void updateFromStorefront({
    required String id,
    required String name,
    required String currency,
    String? logoUrl,
  }) {
    state = state.copyWith(
      tenantId: id,
      appName: name,
      currencySymbol: currency,
      logoUrl: logoUrl,
    );
  }
}
