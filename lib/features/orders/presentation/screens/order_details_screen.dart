import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.w(context)),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2.h(context)),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                size: 16.sp(context),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'تفاصيل الطلب' : 'Order details',
              style: context.textTheme.boldTitleLarge?.copyWith(
                fontSize: 18.sp(context),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Order #IVY-2431 · placed 15 Sep 2026',
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 11.sp(context),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8.w(context)),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2.h(context)),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.download,
                  size: 18.sp(context),
                  color: AppColors.lightTextPrimary,
                ),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20.w(context),
              10.h(context),
              20.w(context),
              110.h(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w(context)),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(28.w(context)),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36.w(context),
                                height: 36.h(context),
                                decoration: BoxDecoration(
                                  color: AppColors.mintTeal.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color: AppColors.mintTeal,
                                  size: 18.sp(context),
                                ),
                              ),
                              SizedBox(width: 10.w(context)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic
                                        ? 'قيد التوصيل'
                                        : 'Out for delivery',
                                    style: context.textTheme.boldTitleMedium
                                        ?.copyWith(
                                          fontSize: 15.sp(context),
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                  ),
                                  Text(
                                    'Expected today · arriving 21 Sep',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(fontSize: 11.sp(context)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w(context),
                              vertical: 4.h(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                12.w(context),
                              ),
                            ),
                            child: Text(
                              'ON TIME',
                              style: context.textTheme.labelSmall?.copyWith(
                                fontSize: 10.sp(context),
                                color: AppColors.mintTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h(context)),
                      Text(
                        'Standard delivery · PL-8842019-SG',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12.sp(context),
                        ),
                      ),
                      SizedBox(height: 16.h(context)),
                      _buildTimelineItem(
                        context,
                        title: 'Order placed',
                        subtitle: '15 Sep 2026, 10:42',
                        isCompleted: true,
                        isLast: false,
                      ),
                      _buildTimelineItem(
                        context,
                        title: 'Packed at the studio',
                        subtitle: '15 Sep 2026, 16:05',
                        isCompleted: true,
                        isLast: false,
                      ),
                      _buildTimelineItem(
                        context,
                        title: 'Shipped',
                        subtitle: '17 Sep 2026, 08:20',
                        isCompleted: true,
                        isLast: false,
                      ),
                      _buildTimelineItem(
                        context,
                        title: 'Out for delivery',
                        subtitle: 'Today, 08:05',
                        isCompleted: true,
                        isCurrent: true,
                        isLast: false,
                      ),
                      _buildTimelineItem(
                        context,
                        title: 'Delivered',
                        subtitle: 'Expected 21 Sep 2026',
                        isCompleted: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),
                Text(
                  isArabic ? 'عنوان التوصيل' : 'Delivery address',
                  style: context.textTheme.boldTitleLarge?.copyWith(
                    fontSize: 16.sp(context),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h(context)),
                Container(
                  padding: EdgeInsets.all(16.w(context)),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(24.w(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w(context),
                        height: 40.h(context),
                        decoration: BoxDecoration(
                          color: AppColors.peach.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 20.sp(context),
                        ),
                      ),
                      SizedBox(width: 14.w(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amelia Wood',
                              style: context.textTheme.boldTitleMedium
                                  ?.copyWith(
                                    fontSize: 14.sp(context),
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                            ),
                            SizedBox(height: 2.h(context)),
                            Text(
                              '12 Rosewood Lane, Apt 4B\nSingapore 238461\n+65 8123 4567',
                              style: context.textTheme.addressBody?.copyWith(
                                fontSize: 12.sp(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),
                Text(
                  isArabic ? 'العناصر (4)' : 'Items (4)',
                  style: context.textTheme.boldTitleLarge?.copyWith(
                    fontSize: 16.sp(context),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h(context)),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(24.w(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildOrderItem(
                        context,
                        imageUrl:
                            'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?q=80&w=600&auto=format&fit=crop',
                        name: 'Cuddle Bear Soft Toy',
                        details: 'Cream · Medium 35cm · Qty 1',
                        price: '\$24.00',
                        isLast: false,
                        isDark: isDark,
                      ),
                      _buildOrderItem(
                        context,
                        imageUrl:
                            'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?q=80&w=600&auto=format&fit=crop',
                        name: 'Daisy Summer Dress',
                        details: 'Mustard · 3–4 years · Qty 2',
                        price: '\$37.00',
                        isLast: false,
                        isDark: isDark,
                      ),
                      _buildOrderItem(
                        context,
                        imageUrl:
                            'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=600&auto=format&fit=crop',
                        name: 'Rainbow Arch Stacker',
                        details: 'Natural · 7 arches · Qty 1',
                        price: '\$29.90',
                        isLast: true,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),
                Text(
                  isArabic ? 'الدفع' : 'Payment',
                  style: context.textTheme.boldTitleLarge?.copyWith(
                    fontSize: 16.sp(context),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h(context)),
                Container(
                  padding: EdgeInsets.all(16.w(context)),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(20.w(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w(context),
                        height: 40.h(context),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.w(context)),
                        ),
                        child: Icon(
                          Icons.credit_card,
                          color: AppColors.primary,
                          size: 20.sp(context),
                        ),
                      ),
                      SizedBox(width: 14.w(context)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card ending 4242',
                            style: context.textTheme.boldTitleMedium?.copyWith(
                              fontSize: 14.sp(context),
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Paid 15 Sep 2026, 10:43',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 11.sp(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),
                Text(
                  isArabic ? 'ملخص السعر' : 'Price summary',
                  style: context.textTheme.boldTitleLarge?.copyWith(
                    fontSize: 16.sp(context),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h(context)),
                Container(
                  padding: EdgeInsets.all(20.w(context)),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(24.w(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        context,
                        'Subtotal (4 items)',
                        '\$90.90',
                        isDark,
                      ),
                      SizedBox(height: 12.h(context)),
                      _buildPriceRow(
                        context,
                        'Discount (IVY10)',
                        '-\$9.09',
                        isDark,
                        valueColor: AppColors.mintTeal,
                      ),
                      SizedBox(height: 12.h(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp(context),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '\$4.90',
                                style: context.textTheme.strikeThroughBodySmall
                                    ?.copyWith(fontSize: 13.sp(context)),
                              ),
                              SizedBox(width: 6.w(context)),
                              Text(
                                'Free',
                                style: context.textTheme.boldTitleMedium
                                    ?.copyWith(
                                      fontSize: 14.sp(context),
                                      color: AppColors.mintTeal,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h(context)),
                        child: const Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total',
                                style: context.textTheme.boldTitleLarge
                                    ?.copyWith(
                                      fontSize: 18.sp(context),
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                              ),
                              SizedBox(height: 2.h(context)),
                              Text(
                                'Including tax',
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontSize: 11.sp(context),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$81.81',
                            style: context.textTheme.displayMedium?.copyWith(
                              fontSize: 22.sp(context),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24.w(context),
                16.h(context),
                24.w(context),
                28.h(context),
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, -6.h(context)),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL',
                            style: context.textTheme.labelLarge?.copyWith(
                              fontSize: 11.sp(context),
                              color: AppColors.lightTextSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h(context)),
                          Text(
                            '\$81.81',
                            style: context.textTheme.boldTitleLarge?.copyWith(
                              fontSize: 22.sp(context),
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20.w(context)),
                      Expanded(
                        child: SizedBox(
                          height: 54.h(context),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  27.w(context),
                                ),
                              ),
                              elevation: 4,
                            ),
                            icon: Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 18.sp(context),
                            ),
                            label: Text(
                              'BUY AGAIN',
                              style: context.textTheme.whiteLabelLarge
                                  ?.copyWith(
                                    fontSize: 15.sp(context),
                                    letterSpacing: 1.0,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h(context)),
                  Text(
                    'Secure checkout · You can review before paying',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 11.sp(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20.w(context),
              height: 20.h(context),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.mintTeal : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 12.sp(context), color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2.w(context),
                height: 36.h(context),
                color: isCompleted ? AppColors.mintTeal : Colors.grey.shade300,
              ),
          ],
        ),
        SizedBox(width: 14.w(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.boldTitleMedium?.copyWith(
                  fontSize: 14.sp(context),
                  color: isCompleted
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                      : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(height: 2.h(context)),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 11.sp(context),
                ),
              ),
              SizedBox(height: 16.h(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required String details,
    required String price,
    required bool isLast,
    required bool isDark,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w(context)),
          child: Row(
            children: [
              Container(
                width: 60.w(context),
                height: 60.h(context),
                decoration: BoxDecoration(
                  color: AppColors.lightCategoryBg,
                  borderRadius: BorderRadius.circular(16.w(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.w(context)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              SizedBox(width: 14.w(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.textTheme.boldTitleMedium?.copyWith(
                        fontSize: 14.sp(context),
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h(context)),
                    Text(
                      details,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.sp(context),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: context.textTheme.boldTitleMedium?.copyWith(
                  fontSize: 15.sp(context),
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
      ],
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp(context),
          ),
        ),
        Text(
          value,
          style: context.textTheme.boldTitleMedium?.copyWith(
            fontSize: 14.sp(context),
            color:
                valueColor ??
                (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }
}
