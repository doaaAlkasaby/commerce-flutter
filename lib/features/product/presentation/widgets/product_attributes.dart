import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/utils/variant_selection_helper.dart';

typedef OnAttributeSelectedCallback =
    void Function(String attributeId, String valueId);

class ProductAttributesWidget extends StatelessWidget {
  final ProductModel product;
  final Map<String, String> selectedAttributeValues;
  final OnAttributeSelectedCallback onAttributeSelected;
  final bool isDark;

  const ProductAttributesWidget({
    super.key,
    required this.product,
    required this.selectedAttributeValues,
    required this.onAttributeSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final List<ProductAttributeModel> attributes = product.attributes;
    if (attributes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attributes.map((attr) {
        final selectedValId = selectedAttributeValues[attr.id];
        final selectedValueModel = attr.values.firstWhere(
          (v) => v.id == selectedValId,
          orElse: () => attr.values.firstWhere(
            (v) => selectedAttributeValues.containsValue(v.value),
            orElse: () => const ProductAttributeValueModel(id: '', value: ''),
          ),
        );

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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (selectedValueModel.value.isNotEmpty)
                  Text(
                    selectedValueModel.value,
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
                final isSelected =
                    selectedValId == val.id ||
                    selectedAttributeValues[attr.id] == val.value ||
                    selectedAttributeValues.containsValue(val.value);

                final isAvailable = VariantSelectionHelper.isValueAvailable(
                  targetAttributeId: attr.id,
                  candidateValueId: val.id,
                  allAttributes: attributes,
                  variants: product.variants,
                  currentSelection: selectedAttributeValues,
                );

                final hasImage =
                    val.imageUrl != null && val.imageUrl!.isNotEmpty;

                return GestureDetector(
                  onTap: isAvailable
                      ? () => onAttributeSelected(attr.id, val.id)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: hasImage ? 10.w(context) : 16.w(context),
                      vertical: 8.h(context),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isAvailable
                                ? (isDark
                                      ? AppColors.darkBackground
                                      : AppColors.peach.withValues(alpha: 0.3))
                                : Colors.grey.shade400.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16.w(context)),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isAvailable
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade200),
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
                              errorWidget: (context, url, error) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(width: 6.w(context)),
                        ],
                        Text(
                          val.value,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isAvailable
                                          ? AppColors.lightTextSecondary
                                          : Colors.grey.shade800),
                                fontSize: 13.sp(context),
                                decoration: isAvailable
                                    ? TextDecoration.none
                                    : TextDecoration.lineThrough,
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
