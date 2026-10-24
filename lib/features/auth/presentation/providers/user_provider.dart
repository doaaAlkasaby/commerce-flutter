import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/user_repository.dart';
import '../../models/auth_response_models.dart';

part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return UserRepository(dio);
}

@riverpod
Future<UserDto?> currentUser(Ref ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null || token.isEmpty) return null;

  try {
    final repository = ref.watch(userRepositoryProvider);
    final response = await repository.getCurrentUser();
    return response.data;
  } catch (_) {
    return null;
  }
}
