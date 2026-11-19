import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/address/models/address_model.dart';
import 'package:ecommerce/features/address/presentation/screens/addresses_screen.dart';
import 'package:ecommerce/features/checkout/utils/country_helper.dart';

class CheckoutAddressSection extends StatelessWidget {
  final AddressModel selectedAddressModel;
  final AddressModel selectedBillingAddressModel;
  final List<AddressModel> addresses;
  final bool billingSameAsDelivery;
  final bool isUncertainSubmission;
  final bool isDark;
  final AppStrings strings;
  final ValueChanged<AddressModel?> onChangeShippingAddress;
  final ValueChanged<AddressModel?> onChangeBillingAddress;
  final ValueChanged<bool> onBillingSameAsDeliveryChanged;

  const CheckoutAddressSection({
    super.key,
    required this.selectedAddressModel,
    required this.selectedBillingAddressModel,
    required this.addresses,
    required this.billingSameAsDelivery,
    required this.isUncertainSubmission,
    required this.isDark,
    required this.strings,
    required this.onChangeShippingAddress,
    required this.onChangeBillingAddress,
    required this.onBillingSameAsDeliveryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shipping Address Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(strings.deliveryAddress, style: context.textTheme.titleMedium),
            TextButton(
              onPressed: isUncertainSubmission
                  ? null
                  : () async {
                      final chosen = await Navigator.of(context)
                          .push<AddressModel>(
                            MaterialPageRoute(
                              builder: (_) => AddressesScreen(
                                isSelectMode: true,
                                selectedAddressId: selectedAddressModel.id,
                              ),
                            ),
                          );
                      onChangeShippingAddress(chosen);
                    },
              child: Text(
                addresses.isEmpty ? strings.addBtn : strings.changeBtn,
                style: context.textTheme.primaryTitleSmall,
              ),
            ),
          ],
        ),

        // Shipping Address Card
        Container(
          padding: EdgeInsets.all(18.w(context)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                          CountryHelper.getCountryFlag(
                            selectedAddressModel.country,
                          ),
                          style: TextStyle(fontSize: 9.sp(context)),
                        ),
                        SizedBox(width: 4.w(context)),
                        Text(
                          CountryHelper.getCountryDisplayName(
                            selectedAddressModel.country,
                            strings.isArabic,
                          ),
                          style: context.textTheme.primaryTitleMini,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w(context)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w(context),
                      vertical: 2.h(context),
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.mintTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.w(context)),
                      border: Border.all(
                        color: AppColors.mintTeal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      selectedAddressModel.title,
                      style: context.textTheme.mintTitleMini,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h(context)),
              Text(
                selectedAddressModel.addressLine1.isNotEmpty
                    ? selectedAddressModel.addressLine1
                    : strings.developmentDeliveryAddress,
                style: context.textTheme.titleSmall,
              ),
              SizedBox(height: 4.h(context)),
              Text(
                '${selectedAddressModel.city}, ${CountryHelper.getCountryDisplayName(selectedAddressModel.country, strings.isArabic)}${selectedAddressModel.postalCode != null && selectedAddressModel.postalCode!.isNotEmpty ? " · " + selectedAddressModel.postalCode! : ""}',
                style: context.textTheme.grayBodySmall,
              ),
              SizedBox(height: 2.h(context)),
              Text(
                '${selectedAddressModel.phone ?? "+965 9000 0000"} · ${strings.leaveAtReception}',
                style: context.textTheme.grayBodySmall,
              ),
              SizedBox(height: 12.h(context)),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 8.h(context)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24.w(context),
                    height: 24.w(context),
                    child: Checkbox(
                      value: billingSameAsDelivery,
                      activeColor: AppColors.primary,
                      onChanged: isUncertainSubmission
                          ? null
                          : (val) =>
                                onBillingSameAsDeliveryChanged(val ?? true),
                    ),
                  ),
                  SizedBox(width: 8.w(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.billingSameAsShipping,
                          style: context.textTheme.bodySmall,
                        ),
                        Text(
                          strings.invoiceSameAddress,
                          style: context.textTheme.grayBodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Separate Billing Address Section
        if (!billingSameAsDelivery) ...[
          SizedBox(height: 10.h(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.billingAddress,
                style: context.textTheme.titleMedium,
              ),
              TextButton(
                onPressed: isUncertainSubmission
                    ? null
                    : () async {
                        final chosen = await Navigator.of(context)
                            .push<AddressModel>(
                              MaterialPageRoute(
                                builder: (_) => AddressesScreen(
                                  isSelectMode: true,
                                  selectedAddressId:
                                      selectedBillingAddressModel.id,
                                ),
                              ),
                            );
                        onChangeBillingAddress(chosen);
                      },
                child: Text(
                  strings.changeBtn,
                  style: context.textTheme.primaryTitleSmall,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(18.w(context)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                            CountryHelper.getCountryFlag(
                              selectedBillingAddressModel.country,
                            ),
                            style: TextStyle(fontSize: 9.sp(context)),
                          ),
                          SizedBox(width: 4.w(context)),
                          Text(
                            CountryHelper.getCountryDisplayName(
                              selectedBillingAddressModel.country,
                              strings.isArabic,
                            ),
                            style: context.textTheme.primaryTitleMini,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w(context)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w(context),
                        vertical: 2.h(context),
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.mintTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.w(context)),
                        border: Border.all(
                          color: AppColors.mintTeal.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        selectedBillingAddressModel.title,
                        style: context.textTheme.mintTitleMini,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h(context)),
                Text(
                  selectedBillingAddressModel.addressLine1.isNotEmpty
                      ? selectedBillingAddressModel.addressLine1
                      : strings.developmentDeliveryAddress,
                  style: context.textTheme.titleSmall,
                ),
                SizedBox(height: 4.h(context)),
                Text(
                  '${selectedBillingAddressModel.city}, ${CountryHelper.getCountryDisplayName(selectedBillingAddressModel.country, strings.isArabic)}${selectedBillingAddressModel.postalCode != null && selectedBillingAddressModel.postalCode!.isNotEmpty ? " · " + selectedBillingAddressModel.postalCode! : ""}',
                  style: context.textTheme.grayBodySmall,
                ),
                if (selectedBillingAddressModel.phone != null &&
                    selectedBillingAddressModel.phone!.isNotEmpty) ...[
                  SizedBox(height: 2.h(context)),
                  Text(
                    selectedBillingAddressModel.phone!,
                    style: context.textTheme.grayBodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
