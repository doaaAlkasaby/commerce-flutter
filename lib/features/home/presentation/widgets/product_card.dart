import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/widgets/app_image_container.dart';
import 'package:ecommerce/core/widgets/app_image_placeholder.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';
import '../../models/home_response_model.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onFavoriteTap,
    required this.onAddTap,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.isFavorite != widget.product.isFavorite) {
      _isFavorite = widget.product.isFavorite;
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.w(context))),
        title: Text('Login Required', style: context.textTheme.boldTitleLarge?.copyWith(fontSize: 18.sp(context))),
        content: Text('You must log in first to add items to your cart or favorites.', style: context.textTheme.bodyMedium?.copyWith(fontSize: 14.sp(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: context.textTheme.description?.copyWith(fontSize: 14.sp(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Login', style: context.textTheme.whiteLabelLarge?.copyWith(fontSize: 14.sp(context))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final token = ref.read(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      _showLoginRequiredDialog(context);
      return;
    }

    if (widget.product.hasVariants) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: widget.product),
        ),
      );
      return;
    }

    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      final variantId = widget.product.defaultVariantId ?? widget.product.id;
      await repo.addToCart(variantId, 1);
      widget.onAddTap();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to cart: ${widget.product.name}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error adding to cart';
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _handleFavoriteToggle(BuildContext context) async {
    final token = ref.read(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      _showLoginRequiredDialog(context);
      return;
    }

    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      await repo.toggleFavorite(widget.product.id, _isFavorite);
      widget.onFavoriteTap();
      if (context.mounted && _isFavorite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added to wishlist successfully'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error updating favorite';
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }

      if (e is DioException && e.response?.statusCode == 409) {
        setState(() {
          _isFavorite = true;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() {
        _isFavorite = previousState;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: widget.product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(24.w(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4.h(context)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  AppImageContainer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.w(context))),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.image,
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                      },
                      placeholder: (context, url) => const AppImagePlaceholder(),
                      errorWidget: (context, url, error) => const AppImagePlaceholder(icon: Icons.broken_image_outlined),
                    ),
                  ),
                  Positioned(
                    top: 12.h(context),
                    right: 12.w(context),
                    child: GestureDetector(
                      onTap: () => _handleFavoriteToggle(context),
                      child: Container(
                        width: 34.w(context),
                        height: 34.w(context),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppColors.badgeRed : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          size: 18.sp(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(14.w(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15.sp(context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 10.h(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${widget.product.priceInfo.finalPrice.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 16.sp(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (widget.product.priceInfo.discountPercentage != null) ...[
                              SizedBox(height: 2.h(context)),
                              Text(
                                '\$${widget.product.priceInfo.originalPrice.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12.sp(context),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w(context)),
                      GestureDetector(
                        onTap: () => _handleAddToCart(context),
                        child: Container(
                          width: 36.w(context),
                          height: 36.w(context),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: Offset(0, 3.h(context)),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20.sp(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
