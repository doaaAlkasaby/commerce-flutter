import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import '../../data/storefront_repository.dart';
import '../../models/storefront_model.dart';

part 'storefront_provider.g.dart';

@Riverpod(keepAlive: true)
StorefrontRepository storefrontRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return StorefrontRepository(dio);
}

@Riverpod(keepAlive: true)
Future<StorefrontModel> storefront(Ref ref) async {
  final activeSlug = ref.watch(selectedTenantSlugProvider);
  final repository = ref.watch(storefrontRepositoryProvider);
  final model = await repository.getStorefront();

  // Guard against stale in-flight response after a tenant switch
  final currentSlug = ref.read(selectedTenantSlugProvider);
  if (currentSlug != activeSlug || (model.slug.isNotEmpty && model.slug != currentSlug)) {
    throw StateError('Stale storefront response discarded for tenant $activeSlug');
  }

  // Update dynamic tenant branding / currency in tenantProvider
  ref.read(tenantProvider.notifier).updateFromStorefront(
    id: model.id,
    name: model.name,
    currency: model.currencySymbol,
    logoUrl: model.logoUrl,
  );

  return model;
}
