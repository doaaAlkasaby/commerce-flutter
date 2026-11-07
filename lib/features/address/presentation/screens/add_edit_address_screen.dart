import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import '../../models/address_model.dart';
import '../providers/address_provider.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? addressToEdit;

  const AddEditAddressScreen({super.key, this.addressToEdit});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late final TextEditingController _phoneController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.addressToEdit;
    _titleController = TextEditingController(text: addr?.title ?? 'HOME');
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _streetController = TextEditingController(text: addr?.streetAddress ?? '');
    _cityController = TextEditingController(text: addr?.city ?? 'Singapore');
    _postalController = TextEditingController(text: addr?.postalCode ?? '');
    _phoneController = TextEditingController(text: addr?.phoneNumber ?? '');
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveAddress(AppStrings strings) {
    if (_nameController.text.isEmpty || _streetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.fillRequired)),
      );
      return;
    }

    final newAddress = AddressModel(
      id: widget.addressToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.toUpperCase(),
      fullName: _nameController.text,
      streetAddress: _streetController.text,
      city: _cityController.text,
      postalCode: _postalController.text,
      phoneNumber: _phoneController.text,
      isDefault: _isDefault,
    );

    if (widget.addressToEdit == null) {
      ref.read(addressProvider.notifier).addAddress(newAddress);
    } else {
      ref.read(addressProvider.notifier).updateAddress(newAddress);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          widget.addressToEdit == null ? strings.addAddress : strings.editAddress,
          style: context.textTheme.titleLarge?.copyWith(
                fontSize: 20.sp(context),
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _titleController,
              labelText: 'Address Label (e.g. HOME, WORK)',
            ),
            SizedBox(height: 16.h(context)),
            AppTextField(
              controller: _nameController,
              labelText: strings.fullName,
            ),
            SizedBox(height: 16.h(context)),
            AppTextField(
              controller: _streetController,
              labelText: strings.streetAddress,
            ),
            SizedBox(height: 16.h(context)),
            Row(
              children: [
                Expanded(child: AppTextField(controller: _cityController, labelText: strings.city)),
                SizedBox(width: 12.w(context)),
                Expanded(child: AppTextField(controller: _postalController, labelText: strings.postalCode)),
              ],
            ),
            SizedBox(height: 16.h(context)),
            AppTextField(
              controller: _phoneController,
              labelText: strings.phoneNumber,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20.h(context)),
            SwitchListTile.adaptive(
              title: Text(strings.setDefaultAddress, style: context.textTheme.boldTitleMedium?.copyWith(fontSize: 14.sp(context))),
              value: _isDefault,
              activeTrackColor: AppColors.primary,
              onChanged: (val) => setState(() => _isDefault = val),
            ),
            SizedBox(height: 32.h(context)),
            AppButton(
              text: widget.addressToEdit == null ? strings.saveAddress : strings.updateAddress,
              onPressed: () => _saveAddress(strings),
            ),
          ],
        ),
      ),
    );
  }
}
