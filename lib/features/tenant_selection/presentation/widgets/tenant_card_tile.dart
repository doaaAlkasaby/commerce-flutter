import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/tenant_selection/models/public_store_model.dart';

class TenantCardTile extends StatelessWidget {
  final PublicStoreModel store;
  final bool isSelected;
  final bool isValidating;
  final AppStrings strings;
  final VoidCallback onTap;

  const TenantCardTile({
    super.key,
    required this.store,
    required this.isSelected,
    required this.isValidating,
    required this.strings,
    required this.onTap,
  });

  Widget _buildLogoWidget(BuildContext context, String logoUrl) {
    final resolvedLogo = AppEnvironment.resolveImageUrl(logoUrl);

    if (resolvedLogo.endsWith('.svg')) {
      return SvgPicture.network(
        resolvedLogo,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Center(
          child: Icon(
            Icons.storefront_outlined,
            size: 16.sp(context),
            color: AppColors.primary,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolvedLogo,
      fit: BoxFit.cover,
      errorWidget: (_, __, _) => Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 16.sp(context),
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCoverImage(
    BuildContext context,
    String? rawCoverUrl,
    String? rawLogoUrl,
  ) {
    if (rawCoverUrl != null && rawCoverUrl.trim().isNotEmpty) {
      final resolvedCover = AppEnvironment.resolveImageUrl(rawCoverUrl);
      return Image.network(
        resolvedCover,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackLogo(context, rawLogoUrl),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackLogo(context, rawLogoUrl);
        },
      );
    }
    return _buildFallbackLogo(context, rawLogoUrl);
  }

  Widget _buildFallbackLogo(BuildContext context, String? rawLogoUrl) {
    if (rawLogoUrl == null || rawLogoUrl.trim().isEmpty) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(
            Icons.storefront_outlined,
            size: 32.sp(context),
            color: AppColors.primary,
          ),
        ),
      );
    }

    final resolvedLogo = AppEnvironment.resolveImageUrl(rawLogoUrl);

    if (resolvedLogo.endsWith('.svg')) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        padding: EdgeInsets.all(12.w(context)),
        child: SvgPicture.network(
          resolvedLogo,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => Center(
            child: Icon(
              Icons.storefront_outlined,
              size: 32.sp(context),
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: CachedNetworkImage(
        imageUrl: resolvedLogo,
        fit: BoxFit.contain,
        errorWidget: (_, __, _) => Center(
          child: Icon(
            Icons.storefront_outlined,
            size: 32.sp(context),
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isValidating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkBkg : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.w(context)),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 3.h(context)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.w(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photographic Cover Section
              Expanded(
                flex: 3,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildCoverImage(
                      context,
                      store.coverImageUrl,
                      store.logoUrl,
                    ),
                    // Floating Brand Logo Badge
                    if (store.logoUrl != null &&
                        store.logoUrl!.trim().isNotEmpty)
                      Positioned(
                        bottom: -14.h(context),
                        left: strings.isArabic ? null : 10.w(context),
                        right: strings.isArabic ? 10.w(context) : null,
                        child: Container(
                          width: 50.w(context),
                          height: 50.w(context),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: Offset(0, 2.h(context)),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: EdgeInsets.all(2.w(context)),
                              child: _buildLogoWidget(context, store.logoUrl!),
                            ),
                          ),
                        ),
                      ),
                    // Selection Checkmark Badge
                    Positioned(
                      top: 8.h(context),
                      right: strings.isArabic ? null : 8.w(context),
                      left: strings.isArabic ? 8.w(context) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(4.w(context)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.circle_outlined,
                          size: 12.sp(context),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Store Info Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    10.w(context),
                    10.h(context),
                    10.w(context),
                    6.h(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium,
                      ),
                      SizedBox(height: 4.h(context)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w(context),
                          vertical: 2.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.w(context)),
                        ),
                        child: Text(
                          store.currencySymbol,
                          style: context.textTheme.primaryLabelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
