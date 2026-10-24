import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/widgets/app_image_container.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import '../../models/home_response_model.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'toys':
        return Icons.toys_outlined;
      case 'clothing':
        return Icons.checkroom_outlined;
      case 'books':
        return Icons.menu_book_outlined;
      case 'learning':
        return Icons.edit_outlined;
      case 'shoes':
        return Icons.roller_skating_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 16.w(context)),
        child: Column(
          children: [
            AppImageContainer(
              width: 60.w(context),
              height: 60.w(context),
              borderRadius: BorderRadius.circular(32.w(context)),
              child: Center(
                child: Icon(
                  _getIconData(category.iconName),
                  color: AppColors.primary,
                  size: 26.sp(context),
                ),
              ),
            ),
            SizedBox(height: 8.h(context)),
            Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
