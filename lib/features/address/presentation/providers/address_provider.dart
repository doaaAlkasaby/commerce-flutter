import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/address_repository.dart';
import '../../models/address_model.dart';

part 'address_provider.g.dart';

@Riverpod(keepAlive: true)
AddressRepository addressRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return AddressRepository(dio);
}

@Riverpod(keepAlive: true)
class AddressNotifier extends _$AddressNotifier {
  @override
  Future<List<AddressModel>> build() async {
    final repository = ref.watch(addressRepositoryProvider);
    return repository.getAddresses();
  }

  Future<void> addAddress(AddressModel address) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.addAddress(address);
    ref.invalidateSelf();
  }

  Future<void> updateAddress(AddressModel address) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.updateAddress(address);
    ref.invalidateSelf();
  }

  Future<void> deleteAddress(String id) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.deleteAddress(id);
    ref.invalidateSelf();
  }

  Future<void> setDefault(String id) async {
    final repository = ref.read(addressRepositoryProvider);
    await repository.setDefaultShipping(id);
    ref.invalidateSelf();
  }
}
