import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductVariantsWidget extends ConsumerWidget {
  final ProductModel product;
  final ProductVariantModel? selectedVariant;
  final bool isDark;

  const ProductVariantsWidget({
    super.key,
    required this.product,
    required this.selectedVariant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (product.variants.isEmpty) return const SizedBox.shrink();

    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h(context)),
      padding: EdgeInsets.all(16.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20.w(context)),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.availableVariantSku,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w(context),
                  vertical: 3.h(context),
                ),
                decoration: BoxDecoration(
                  color: (selectedVariant?.isActive ?? true)
                      ? AppColors.mintTeal.withValues(alpha: 0.15)
                      : AppColors.badgeRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.w(context)),
                ),
                child: Text(
                  (selectedVariant?.isActive ?? true)
                      ? strings.inStock
                      : strings.outOfStockLabel,
                  style: (selectedVariant?.isActive ?? true)
                      ? context.textTheme.mintLabelSmall
                      : context.textTheme.redTitleSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h(context)),
          Text(
            selectedVariant?.sku ?? product.slug.toUpperCase(),
            style: context.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
