import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class PromoBanner extends StatelessWidget {
  final List<BannerModel> banners;
  final VoidCallback onShopNow;

  const PromoBanner({
    super.key,
    required this.banners,
    required this.onShopNow,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 160.h(context),
      child: PageView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w(context)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7A1C33), Color(0xFF5A1224)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.w(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: Offset(0, 8.h(context)),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (banner.imageUrl.isNotEmpty && !banner.imageUrl.contains('placehold.co'))
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.w(context)),
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                  ),
                Positioned(
                  right: -30.w(context),
                  top: -30.h(context),
                  child: Container(
                    width: 130.w(context),
                    height: 130.h(context),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(22.w(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22.sp(context),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      SizedBox(height: 4.h(context)),
                      Text(
                        banner.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp(context),
                              color: Colors.white70,
                            ),
                      ),
                      SizedBox(height: 14.h(context)),
                      GestureDetector(
                        onTap: onShopNow,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w(context), vertical: 8.h(context)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.w(context)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Shop now',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 13.sp(context),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lightTextPrimary,
                                    ),
                              ),
                              SizedBox(width: 4.w(context)),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp(context),
                                color: AppColors.lightTextPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
