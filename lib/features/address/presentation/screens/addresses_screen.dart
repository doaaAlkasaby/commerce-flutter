import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import '../providers/address_provider.dart';
import 'add_edit_address_screen.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
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
        title: Text(
          strings.myAddresses,
          style: context.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp(context),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: addressesAsync.when(
        data: (addresses) => addresses.isEmpty
            ? Center(
                child: Text(
                  strings.noProductsFound,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp(context),
                  ),
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(20.w(context)),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h(context)),
                    padding: EdgeInsets.all(18.w(context)),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address.fullName,
                                  style: context.textTheme.boldTitleMedium
                                      ?.copyWith(
                                        fontSize: 16.sp(context),
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                ),
                                SizedBox(width: 8.w(context)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w(context),
                                    vertical: 2.h(context),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(
                                      6.w(context),
                                    ),
                                  ),
                                  child: Text(
                                    address.title,
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(fontSize: 10.sp(context)),
                                  ),
                                ),
                              ],
                            ),
                            if (address.isDefault)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w(context),
                                  vertical: 4.h(context),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10.w(context),
                                  ),
                                ),
                                child: Text(
                                  strings.defaultLabel,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontSize: 10.sp(context),
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h(context)),
                        Text(
                          '${address.streetAddress}\n${address.city} ${address.postalCode}\n${address.phoneNumber}',
                          style: context.textTheme.addressBody?.copyWith(
                            fontSize: 13.sp(context),
                          ),
                        ),
                        SizedBox(height: 14.h(context)),
                        const Divider(height: 1),
                        SizedBox(height: 10.h(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!address.isDefault)
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(addressProvider.notifier)
                                      .setDefault(address.id);
                                },
                                child: Text(
                                  strings.setAsDefault,
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        fontSize: 12.sp(context),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mintTeal,
                                      ),
                                ),
                              ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditAddressScreen(
                                      addressToEdit: address,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 16.sp(context),
                                color: AppColors.primary,
                              ),
                              label: Text(
                                strings.edit,
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontSize: 12.sp(context),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ref
                                    .read(addressProvider.notifier)
                                    .deleteAddress(address.id);
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                size: 16.sp(context),
                                color: AppColors.badgeRed,
                              ),
                              label: Text(
                                strings.delete,
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontSize: 12.sp(context),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.badgeRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          strings.addAddress,
          style: context.textTheme.whiteLabelLarge?.copyWith(
            fontSize: 14.sp(context),
          ),
        ),
      ),
    );
  }
}
