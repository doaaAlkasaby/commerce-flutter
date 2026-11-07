import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductAttributesWidget extends StatelessWidget {
  final ProductModel product;
  final String selectedColor;
  final String selectedSize;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;
  final bool isDark;

  const ProductAttributesWidget({
    super.key,
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    required this.onColorSelected,
    required this.onSizeSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    List<ProductAttributeModel> attributes = product.attributes;
    if (attributes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attributes.map((attr) {
        final isColor = attr.name.toLowerCase() == 'color' || attr.name.toLowerCase() == 'colour';
        final selectedVal = isColor ? selectedColor : selectedSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 32.h(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  attr.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp(context),
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                ),
                Text(
                  selectedVal,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightTextSecondary,
                        fontSize: 14.sp(context),
                      ),
                ),
              ],
            ),
            SizedBox(height: 12.h(context)),
            Wrap(
              spacing: 12.w(context),
              runSpacing: 8.h(context),
              children: attr.values.map((val) {
                final isSelected = selectedVal == val.value;
                final hasImage = val.imageUrl != null && val.imageUrl!.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    if (isColor) {
                      onColorSelected(val.value);
                    } else {
                      onSizeSelected(val.value);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hasImage ? 10.w(context) : 16.w(context), vertical: 8.h(context)),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                      borderRadius: BorderRadius.circular(16.w(context)),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasImage) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.w(context)),
                            child: CachedNetworkImage(
                              imageUrl: val.imageUrl!,
                              width: 24.w(context),
                              height: 24.h(context),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(width: 6.w(context)),
                        ],
                        Text(
                          val.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.lightTextSecondary,
                                fontSize: 13.sp(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }
}
