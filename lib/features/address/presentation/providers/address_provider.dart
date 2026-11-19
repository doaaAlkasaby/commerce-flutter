import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import '../../data/address_repository.dart';
import '../../models/address_model.dart';
import '../../models/country_model.dart';

part 'address_provider.g.dart';

@Riverpod(keepAlive: true)
AddressRepository addressRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return AddressRepository(dio);
}

@riverpod
Future<List<CountryModel>> supportedCountries(Ref ref) async {
  final repository = ref.watch(addressRepositoryProvider);
  return repository.getCountries();
}

@Riverpod(keepAlive: true)
class AddressNotifier extends _$AddressNotifier {
  @override
  Future<List<AddressModel>> build() async {
    final userAsync = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final user = userAsync.value;

    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const [];
    }

    final requestUserId = user.id;
    final repository = ref.watch(addressRepositoryProvider);
    final addresses = await repository.getAddresses();

    if (!ref.mounted) return const [];

    final currentUserId = ref.read(currentUserProvider).value?.id;
    if (ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const [];
    }

    return addresses;
  }

  Future<void> addAddress(AddressModel address) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.addAddress(address);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateAddress(AddressModel address) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.updateAddress(address);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteAddress(String id) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.deleteAddress(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setDefault(String id) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.setDefaultShipping(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setDefaultBilling(String id) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.setDefaultBilling(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
