import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/home_repository.dart';
import '../../models/home_response_model.dart';

part 'home_provider.g.dart';

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return HomeRepository(dio);
}

@riverpod
Future<HomeResponseModel> homeData(Ref ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getHomeData();
}
