import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/network/api_logging_interceptor.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/storefront/data/storefront_repository.dart';
import 'package:ecommerce/features/tenant_selection/models/public_store_model.dart';

part 'tenant_selection_provider.g.dart';

@Riverpod(keepAlive: true)
StorefrontRepository discoveryStorefrontRepository(Ref ref) {
  final activeDio = ref.watch(dioClientProvider);
  final discoveryDio = Dio(
    BaseOptions(
      baseUrl: AppEnvironment.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  discoveryDio.httpClientAdapter = activeDio.httpClientAdapter;
  discoveryDio.interceptors.add(ApiLoggingInterceptor());

  return StorefrontRepository(discoveryDio);
}

@riverpod
class PublicStoresNotifier extends _$PublicStoresNotifier {
  @override
  Future<List<PublicStoreModel>> build() async {
    final repository = ref.watch(discoveryStorefrontRepositoryProvider);
    return repository.getPublicStores();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(discoveryStorefrontRepositoryProvider);
      return repository.getPublicStores();
    });
  }
}
