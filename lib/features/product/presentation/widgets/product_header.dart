import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductHeaderWidget extends ConsumerStatefulWidget {
  final ProductModel product;
  final List<ProductImageModel>? overrideImages;
  final bool isArabic;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;

  const ProductHeaderWidget({
    super.key,
    required this.product,
    this.overrideImages,
    required this.isArabic,
    required this.isDark,
    required this.isFavorite,
    required this.onBackPressed,
    required this.onFavoritePressed,
  });

  @override
  ConsumerState<ProductHeaderWidget> createState() =>
      _ProductHeaderWidgetState();
}

class _ProductHeaderWidgetState extends ConsumerState<ProductHeaderWidget> {
  int _selectedImageIndex = 0;

  @override
  void didUpdateWidget(covariant ProductHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overrideImages != widget.overrideImages) {
      setState(() {
        _selectedImageIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    final images =
        (widget.overrideImages != null && widget.overrideImages!.isNotEmpty)
        ? widget.overrideImages!
        : (widget.product.images.isNotEmpty
              ? widget.product.images
              : [
                  ProductImageModel(
                    id: '1',
                    url: widget.product.image,
                    altText: widget.product.name,
                    isPrimary: true,
                  ),
                ]);

    final activeImageUrl =
        images[_selectedImageIndex.clamp(0, images.length - 1)].url;

    return SliverAppBar(
      expandedHeight: 380.h(context),
      pinned: true,
      backgroundColor: widget.isDark
          ? AppColors.darkSurface
          : const Color(0xFFF2ECE4),
      leading: Padding(
        padding: EdgeInsets.all(8.w(context)),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 2.h(context)),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 16.sp(context),
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            onPressed: widget.onBackPressed,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.all(8.w(context)),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2.h(context)),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.share_outlined,
                size: 18.sp(context),
                color: widget.isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            right: 12.w(context),
            top: 8.h(context),
            bottom: 8.h(context),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2.h(context)),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 18.sp(context),
                color: widget.isFavorite
                    ? AppColors.badgeRed
                    : (widget.isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
              ),
              onPressed: widget.onFavoritePressed,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: activeImageUrl,
              fit: BoxFit.cover,
              httpHeaders: const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Positioned(
              bottom: 70.h(context),
              left: 20.w(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w(context),
                  vertical: 6.h(context),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(16.w(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2.h(context)),
                    ),
                  ],
                ),
                child: Text(
                  strings.bestsellerLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 16.h(context),
                left: 20.w(context),
                right: 20.w(context),
                child: Row(
                  children: List.generate(images.length, (index) {
                    final isSelected = _selectedImageIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Padding(
                        padding: EdgeInsets.only(right: 10.w(context)),
                        child: Container(
                          width: 50.w(context),
                          height: 50.h(context),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.w(context)),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(images[index].url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
