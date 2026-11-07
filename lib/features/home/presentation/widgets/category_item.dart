import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 8.w(context)),
        child: SizedBox(
          width: 54.w(context),
          height: 80.h(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppImageContainer(
                width: 32.w(context),
                height: 32.w(context),
                borderRadius: BorderRadius.circular(16.w(context)),
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: category.imageUrl ?? "",
                    fit: BoxFit.cover,
                    width: 32.w(context),
                    height: 32.w(context),
                    errorWidget: (context, url, error) => const Icon(Icons.category_outlined, size: 16),
                  ),
                ),
              ),
              SizedBox(height: 2.h(context)),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9.sp(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
