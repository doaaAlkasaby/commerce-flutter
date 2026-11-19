import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/address/models/address_model.dart';
import 'package:ecommerce/features/address/presentation/providers/address_provider.dart';
import 'package:ecommerce/features/address/presentation/screens/add_edit_address_screen.dart';

class AddressMoreMenuBottomSheet extends ConsumerWidget {
  final AddressModel address;
  final AppStrings strings;

  const AddressMoreMenuBottomSheet({
    super.key,
    required this.address,
    required this.strings,
  });

  static void show(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
    AppStrings strings,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.w(context)),
        ),
      ),
      builder: (ctx) =>
          AddressMoreMenuBottomSheet(address: address, strings: strings),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: Text(strings.edit, style: context.textTheme.titleSmall),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddEditAddressScreen(addressToEdit: address),
                  ),
                );
              },
            ),
            if (!address.isDefaultBilling)
              ListTile(
                leading: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  strings.setDefaultBillingAddress,
                  style: context.textTheme.titleSmall,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(addressProvider.notifier)
                      .setDefaultBilling(address.id);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.badgeRed,
              ),
              title: Text(
                strings.deleteAddress,
                style: context.textTheme.redTitleSmall,
              ),
              onTap: () async {
                final notifier = ref.read(addressProvider.notifier);
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(strings.deleteAddress),
                    content: Text(strings.confirmDeleteAddressMsg),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                        child: Text(strings.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        child: Text(
                          strings.delete,
                          style: context.textTheme.redLabelMedium,
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  notifier.deleteAddress(address.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
