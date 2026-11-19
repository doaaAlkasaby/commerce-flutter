import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/presentation/screens/product_list_screen.dart';

class PromoBanner extends StatefulWidget {
  final List<BannerModel> banners;
  final VoidCallback? onShopNow;

  const PromoBanner({super.key, required this.banners, this.onShopNow});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.banners.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBannerTap(BuildContext context, BannerModel banner) {
    if (banner.targetType == 'CATEGORY' && banner.targetId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            title: banner.title.isNotEmpty ? banner.title : 'Products',
            endpoint: '/products?categoryId=${banner.targetId}',
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            title: banner.title.isNotEmpty
                ? banner.title
                : 'Promotional Offers',
            endpoint: ApiEndpoints.productsOffers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 130.h(context),
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final hasGraphicText = banner.imageUrl.contains('everyday-edit');

              return GestureDetector(
                onTap: () => _handleBannerTap(context, banner),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w(context)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A1C33), Color(0xFF5A1224)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.w(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (banner.imageUrl.isNotEmpty &&
                          !banner.imageUrl.contains('placehold.co'))
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.w(context)),
                            child: CachedNetworkImage(
                              imageUrl: AppEnvironment.resolveImageUrl(
                                banner.imageUrl,
                              ),
                              fit: BoxFit.cover,
                              httpHeaders: const {
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                              },
                              color: Colors.black.withValues(
                                alpha: hasGraphicText ? 0.0 : 0.35,
                              ),
                              colorBlendMode: hasGraphicText
                                  ? null
                                  : BlendMode.darken,
                            ),
                          ),
                        ),
                      if (!hasGraphicText &&
                          (banner.title.isNotEmpty ||
                              banner.subtitle.isNotEmpty))
                        Padding(
                          padding: EdgeInsets.all(14.w(context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (banner.title.isNotEmpty)
                                Text(
                                  banner.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.whiteTitleLarge,
                                ),
                              if (banner.subtitle.isNotEmpty) ...[
                                SizedBox(height: 2.h(context)),
                                Text(
                                  banner.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodyMedium,
                                ),
                              ],
                              SizedBox(height: 8.h(context)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w(context),
                                  vertical: 4.h(context),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    16.w(context),
                                  ),
                                ),
                                child: Text(
                                  'Shop now',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 10.sp(context),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextPrimary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          SizedBox(height: 8.h(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 3.w(context)),
                width: _currentPage == i ? 18.w(context) : 6.w(context),
                height: 6.h(context),
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3.w(context)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
