import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/checkout_repository.dart';

part 'checkout_provider.g.dart';

@Riverpod(keepAlive: true)
CheckoutRepository checkoutRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return CheckoutRepository(dio);
}
