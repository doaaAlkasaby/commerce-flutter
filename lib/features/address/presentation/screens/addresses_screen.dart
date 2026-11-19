import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import '../../models/address_model.dart';
import '../providers/address_provider.dart';
import '../widgets/address_card_tile.dart';
import 'add_edit_address_screen.dart';

class AddressesScreen extends ConsumerWidget {
  final bool isSelectMode;
  final String? selectedAddressId;

  const AddressesScreen({
    super.key,
    this.isSelectMode = false,
    this.selectedAddressId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
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
                Icons.arrow_back_ios_new,
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
          isSelectMode ? strings.selectDeliveryAddressReq : strings.myAddresses,
          style: context.textTheme.titleLarge,
        ),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(addressProvider.notifier).refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: 100.h(context)),
                  AppEmptyWidget(
                    title: strings.noAddressesFound,
                    pngAsset: AppAssets.map,
                    size: 80.w(context),
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(
                      horizontal: 50.w(context),
                    ),
                    child: _addBtnWidget(context, strings),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(addressProvider.notifier).refresh();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    12.w(context),
                    10.h(context),
                    12.w(context),
                    110.h(context),
                  ),
                  children: [
                    // Sub-header Row (e.g. 3 SAVED, DEFAULT FIRST)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h(context)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${addresses.length} ${strings.savedUppercase}',
                            style: context.textTheme.subheaderLabel,
                          ),
                          Text(
                            strings.defaultFirst,
                            style: context.textTheme.subheaderLabel,
                          ),
                        ],
                      ),
                    ),

                    // Addresses Cards
                    ...addresses.map((address) {
                      return AddressCardTile(
                        address: address,
                        isSelectMode: isSelectMode,
                        selectedAddressId: selectedAddressId,
                        isDark: isDark,
                        strings: strings,
                      );
                    }),

                    SizedBox(height: 12.h(context)),
                    Text(
                      strings.addressTaxNotice,
                      textAlign: TextAlign.center,
                      style: context.textTheme.secondaryNoticeText,
                    ),
                  ],
                ),
              ),

              // Fixed Bottom Action Button: + Add address
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20.w(context),
                    12.h(context),
                    20.w(context),
                    24.h(context),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: Offset(0, -4.h(context)),
                      ),
                    ],
                  ),
                  child: _addBtnWidget(context, strings),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: strings.failedToLoadAddresses,
          onRetry: () => ref.invalidate(addressProvider),
        ),
      ),
    );
  }

  Widget _addBtnWidget(context, strings) {
    return AppButton(
      text: '+ ${strings.addAddress}',
      onPressed: () async {
        final newAddress = await Navigator.of(context).push<AddressModel>(
          MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
        );
        if (newAddress != null && context.mounted && isSelectMode) {
          Navigator.of(context).pop<AddressModel>(newAddress);
        }
      },
    );
  }
}
