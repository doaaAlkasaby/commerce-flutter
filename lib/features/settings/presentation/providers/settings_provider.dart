import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/app_settings_repository.dart';
import '../../models/app_settings_model.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
AppSettingsRepository appSettingsRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return AppSettingsRepository(dio);
}

@riverpod
Future<AppSettingsModel?> appSettings(Ref ref) async {
  final repository = ref.watch(appSettingsRepositoryProvider);
  final response = await repository.getAppSettings();
  return response.data;
}
