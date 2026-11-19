import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/address/models/address_model.dart';
import 'package:ecommerce/features/address/presentation/providers/address_provider.dart';
import 'package:ecommerce/features/address/presentation/screens/add_edit_address_screen.dart';
import 'package:ecommerce/features/checkout/utils/country_helper.dart';
import 'address_more_menu_bottom_sheet.dart';

class AddressCardTile extends ConsumerWidget {
  final AddressModel address;
  final bool isSelectMode;
  final String? selectedAddressId;
  final bool isDark;
  final AppStrings strings;

  const AddressCardTile({
    super.key,
    required this.address,
    required this.isSelectMode,
    this.selectedAddressId,
    required this.isDark,
    required this.strings,
  });

  String _getSvgAssetForTitle(String title) {
    final upper = title.toUpperCase();
    if (upper == 'HOME') {
      return AppAssets.house;
    } else if (upper == 'WORK') {
      return AppAssets.work;
    }
    return AppAssets.marker;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = isSelectMode && selectedAddressId == address.id;

    return GestureDetector(
      onTap: isSelectMode
          ? () => Navigator.of(context).pop<AddressModel>(address)
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h(context)),
        padding: EdgeInsets.all(18.w(context)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(24.w(context)),
          border: Border.all(
            color: isSelected || address.isDefaultShipping
                ? AppColors.peach
                : Colors.transparent,
            width: isSelected || address.isDefaultShipping ? 1.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: Offset(0, 4.h(context)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Info Row: Icon + Full Name + Title Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42.w(context),
                  height: 42.w(context),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.w(context)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10.w(context)),
                    child: SvgPicture.asset(
                      _getSvgAssetForTitle(address.title),
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              address.fullName,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w(context),
                              vertical: 4.h(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6.w(context)),
                            ),
                            child: Text(
                              address.title,
                              style: context.textTheme.primaryTitleMini,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h(context)),
                      Text(
                        address.addressLine1,
                        style: context.textTheme.grayBodySmall,
                      ),
                      SizedBox(height: 2.h(context)),
                      Text(
                        '${address.city}, ${CountryHelper.getCountryDisplayName(address.country, strings.isArabic)}${address.postalCode != null && address.postalCode!.isNotEmpty ? " · " + address.postalCode! : ""}',
                        style: context.textTheme.grayBodySmall,
                      ),
                      if (address.phone != null &&
                          address.phone!.isNotEmpty) ...[
                        SizedBox(height: 4.h(context)),
                        Text(
                          address.phone!,
                          style: context.textTheme.grayBodySmall,
                        ),
                      ],
                      SizedBox(height: 6.w(context)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w(context),
                          vertical: 2.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.w(context)),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CountryHelper.getCountryFlag(address.country),
                              style: TextStyle(fontSize: 11.sp(context)),
                            ),
                            SizedBox(width: 6.w(context)),
                            Text(
                              CountryHelper.getCountryDisplayName(
                                address.country,
                                strings.isArabic,
                              ),
                              style: context.textTheme.primaryTitleMini,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h(context)),
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 12.h(context)),

            // Action Bar: Badges / Set Default (Left) + Edit & ... (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (address.isDefaultShipping) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w(context),
                          vertical: 4.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6.w(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 12,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 4.w(context)),
                            Text(
                              strings.defaultUppercase,
                              style: context.textTheme.badgeTextGreen,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w(context)),
                    ],
                    if (address.isDefaultBilling) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w(context),
                          vertical: 4.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.w(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 11,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4.w(context)),
                            Text(
                              strings.billingUppercase,
                              style: context.textTheme.badgeTextOrange,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!address.isDefaultShipping && !isSelectMode)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(addressProvider.notifier)
                              .setDefault(address.id);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 14.sp(context),
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w(context)),
                            Text(
                              strings.setAsDefault,
                              style: context.textTheme.primaryActionText,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Right Buttons: Edit + ... Menu
                Row(
                  children: [
                    if (isSelectMode)
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop<AddressModel>(address),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w(context),
                            vertical: 0.h(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.w(context)),
                          ),
                        ),
                        child: Text(
                          strings.apply,
                          style: context.textTheme.whiteTitleSmall,
                        ),
                      )
                    else ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditAddressScreen(addressToEdit: address),
                            ),
                          );
                        },
                        child: Text(
                          strings.edit,
                          style: context.textTheme.primaryActionText,
                        ),
                      ),
                      SizedBox(width: 12.w(context)),
                      GestureDetector(
                        onTap: () => AddressMoreMenuBottomSheet.show(
                          context,
                          ref,
                          address,
                          strings,
                        ),
                        child: Container(
                          width: 32.w(context),
                          height: 32.w(context),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.more_horiz,
                            size: 18.sp(context),
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
