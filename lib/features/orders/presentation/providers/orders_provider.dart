import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/orders_repository.dart';
import '../../models/order_model.dart';

part 'orders_provider.g.dart';

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return OrdersRepository(dio);
}

@riverpod
Future<List<OrderModel>> myOrders(Ref ref) async {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.getMyOrders();
}

@Riverpod(keepAlive: true)
class OrderFilterNotifier extends _$OrderFilterNotifier {
  @override
  String build() => 'All';

  void setFilter(String filter) {
    state = filter;
  }
}
