import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import '../widgets/product_grid.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String title;
  final String endpoint;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ProductModel> _products = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  bool _paginationError = false;
  int _requestRevision = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint != widget.endpoint ||
        oldWidget.title != widget.title) {
      _fetchProducts(refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore &&
        !_paginationError) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts({bool refresh = false}) async {
    final localizationAsync = ref.read(appLocalizationLoaderProvider);
    final currentLang = ref.read(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    if (_isLoading) return;

    if (refresh) {
      _requestRevision++;
    }
    final currentRev = _requestRevision;
    final requestTenantSlug = ref.read(selectedTenantSlugProvider);

    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _products.clear();
        _hasMore = true;
        _errorMessage = null;
        _paginationError = false;
      } else {
        _paginationError = false;
      }
    });

    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      final newProducts = await repo.getProductsByEndpoint(
        widget.endpoint,
        page: _page,
        limit: 10,
      );

      if (!mounted ||
          _requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug) {
        return;
      }

      setState(() {
        if (newProducts.isEmpty || newProducts.length < 10) {
          _hasMore = false;
        }

        if (newProducts.isNotEmpty) {
          final existingIds = _products.map((p) => p.id).toSet();
          final uniqueNewProducts = newProducts
              .where((p) => !existingIds.contains(p.id))
              .toList();
          _products.addAll(uniqueNewProducts);
          _page++;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted ||
          _requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug) {
        return;
      }

      setState(() {
        _isLoading = false;
        if (_products.isEmpty) {
          _errorMessage = strings.failedToLoadProductsNet;
        } else {
          _paginationError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    ref.listen<String>(selectedTenantSlugProvider, (previous, next) {
      if (previous != null && previous != next) {
        _fetchProducts(refresh: true);
      }
    });

    Widget content;
    if (_products.isEmpty && _isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_products.isEmpty && _errorMessage != null) {
      content = AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _fetchProducts(refresh: true),
      );
    } else if (_products.isEmpty) {
      content = AppEmptyWidget(
        title: strings.noProductsFound,
        icon: Icons.shopping_bag_outlined,
      );
    } else {
      content = ProductGrid(
        scrollController: _scrollController,
        products: _products,
        hasMore: _hasMore,
        paginationError: _paginationError,
        strings: strings,
        onFetchMore: _fetchProducts,
        onAddToCart: (product) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                strings
                    .get('added_to_cart_item')
                    .replaceAll('{productName}', product.name),
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.title, style: context.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _fetchProducts(refresh: true),
          child: content,
        ),
      ),
    );
  }
}
