import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/api_logging_interceptor.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/storefront/data/storefront_repository.dart';
import 'package:ecommerce/features/tenant_selection/presentation/providers/tenant_selection_provider.dart';
import '../widgets/tenant_card_tile.dart';
import '../widgets/tenant_selection_header.dart';
import '../widgets/tenant_validation_error_banner.dart';

class TenantSelectionScreen extends ConsumerStatefulWidget {
  final bool isChangeStore;

  const TenantSelectionScreen({super.key, this.isChangeStore = false});

  @override
  ConsumerState<TenantSelectionScreen> createState() =>
      _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends ConsumerState<TenantSelectionScreen> {
  late String _selectedSlug;
  bool _isValidating = false;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final activeSlug = ref.read(selectedTenantSlugProvider);
    _selectedSlug = (activeSlug.isNotEmpty)
        ? activeSlug
        : AppEnvironment.defaultTenantSlug;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _validateAndConfirmTenant() async {
    final localizationAsync = ref.read(appLocalizationLoaderProvider);
    final currentLang = ref.read(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final activeSlug = ref.read(selectedTenantSlugProvider);
      final isChangingStore =
          activeSlug.isNotEmpty && activeSlug != _selectedSlug;

      if (isChangingStore) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          final coordinator = ref.read(sessionCoordinatorProvider);
          final currentRefresh = await coordinator.storage.readRefreshToken();
          if (currentRefresh != null && currentRefresh.isNotEmpty) {
            try {
              final authRepo = AuthRepository(ref.read(dioClientProvider));
              await authRepo
                  .logout(currentRefresh)
                  .timeout(const Duration(seconds: 2));
            } catch (_) {}
          }
          await ref.read(authTokenProvider.notifier).setToken(null);
        }
      }

      final token = ref.read(authTokenProvider);

      final candidateDio = Dio(
        BaseOptions(
          baseUrl: AppEnvironment.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Tenant-Slug': _selectedSlug,
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      final activeDio = ref.read(dioClientProvider);
      candidateDio.httpClientAdapter = activeDio.httpClientAdapter;
      candidateDio.interceptors.add(ApiLoggingInterceptor());

      final repo = StorefrontRepository(candidateDio);
      final storefront = await repo.getStorefront();

      if (storefront.slug.isNotEmpty && storefront.slug != _selectedSlug) {
        throw StateError(
          'Storefront response slug does not match candidate tenant',
        );
      }

      if (!mounted) return;

      await ref
          .read(tenantConfirmationProvider.notifier)
          .confirmTenant(_selectedSlug);

      ref
          .read(tenantProvider.notifier)
          .updateFromStorefront(
            id: storefront.id,
            name: storefront.name,
            currency: storefront.currencySymbol,
            logoUrl: storefront.logoUrl,
          );

      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (widget.isChangeStore && navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      if (!mounted) return;
      String errStr = strings.failedToValidateStore;
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errStr = data['message'].toString();
        }
      }
      setState(() {
        _errorMessage = errStr;
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final publicStoresAsync = ref.watch(publicStoresProvider);

    return AppScaffold(
      appBar: widget.isChangeStore
          ? AppBar(title: Text(strings.selectStore), centerTitle: true)
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              TenantSelectionHeader(strings: strings),

              SizedBox(height: 12.h(context)),

              // 2. Search Filter
              AppTextField(
                controller: _searchController,
                labelText: strings.searchStore,
                hintText: strings.searchStoreHint,
                prefixIcon: Icons.search,
                onChanged: (query) {
                  setState(() => _searchQuery = query.trim().toLowerCase());
                },
              ),
              SizedBox(height: 14.h(context)),

              // 3. Validation Error Banner
              if (_errorMessage != null)
                TenantValidationErrorBanner(
                  errorMessage: _errorMessage!,
                  isValidating: _isValidating,
                  strings: strings,
                  onRetry: _validateAndConfirmTenant,
                ),

              // 4. Stores Grid
              Expanded(
                child: publicStoresAsync.when(
                  data: (stores) {
                    final filteredStores = stores.where((s) {
                      if (_searchQuery.isEmpty) return true;
                      return s.name.toLowerCase().contains(_searchQuery) ||
                          s.slug.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredStores.isEmpty) {
                      return AppEmptyWidget(
                        title: strings.noStoresFound,
                        icon: Icons.storefront_outlined,
                      );
                    }

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                            ? 3
                            : 2,
                        crossAxisSpacing: 12.w(context),
                        mainAxisSpacing: 12.h(context),
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredStores.length,
                      itemBuilder: (context, index) {
                        final store = filteredStores[index];
                        final isSelected = store.slug == _selectedSlug;

                        return TenantCardTile(
                          store: store,
                          isSelected: isSelected,
                          isValidating: _isValidating,
                          strings: strings,
                          onTap: () {
                            setState(() {
                              _selectedSlug = store.slug;
                              _errorMessage = null;
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorWidget(
                    message: strings.failedToLoadPublicStores,
                    onRetry: () =>
                        ref.read(publicStoresProvider.notifier).refresh(),
                  ),
                ),
              ),

              SizedBox(height: 10.h(context)),

              // 5. Continue / Confirm Button
              AppButton(
                text: strings.continueBtn,
                isLoading: _isValidating,
                onPressed: _isValidating ? null : _validateAndConfirmTenant,
              ),
              SizedBox(height: 8.h(context)),
            ],
          ),
        ),
      ),
    );
  }
}
