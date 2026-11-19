import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../../models/help_support_model.dart';

part 'help_support_provider.g.dart';

@riverpod
Future<HelpSupportModel> helpSupport(Ref ref) async {
  final dio = ref.watch(dioClientProvider);
  final tenantSlug = ref.watch(selectedTenantSlugProvider);

  if (tenantSlug.isEmpty) {
    return const HelpSupportModel();
  }

  final response = await dio.get(ApiEndpoints.appSettings);
  final rawData = response.data['data'];

  return HelpSupportModel.fromSettingsData(rawData);
}
