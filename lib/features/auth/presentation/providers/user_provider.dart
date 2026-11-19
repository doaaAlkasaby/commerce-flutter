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
class CurrentUser extends _$CurrentUser {
  @override
  Future<UserDto?> build() async {
    final token = ref.watch(authTokenProvider);
    if (token == null || token.isEmpty) return null;

    try {
      final repository = ref.watch(userRepositoryProvider);
      final response = await repository.getCurrentUser();

      if (!ref.mounted) return null;
      if (ref.read(authTokenProvider) != token) return null;

      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({String? firstName, String? lastName}) async {
    final token = ref.read(authTokenProvider);
    final repository = ref.read(userRepositoryProvider);
    await repository.updateProfile(firstName: firstName, lastName: lastName);

    if (!ref.mounted) return;
    if (ref.read(authTokenProvider) != token) return;

    ref.invalidateSelf();
    await future;
  }
}
