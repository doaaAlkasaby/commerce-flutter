import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import '../../models/address_model.dart';
import '../../models/country_model.dart';
import '../providers/address_provider.dart';
import '../widgets/address_completion_progress_card.dart';
import '../widgets/address_country_selector_sheet.dart';
import '../widgets/address_label_selector.dart';

class PhoneUtils {
  static const Map<String, String> countryDialingCodes = {
    'KW': '+965',
    'SA': '+966',
    'AE': '+971',
    'EG': '+20',
    'US': '+1',
    'CA': '+1',
    'GB': '+44',
  };

  static String? getDialingPrefix(String countryCode) {
    return countryDialingCodes[countryCode.toUpperCase()];
  }

  static String? normalizeToE164(String input, String countryCode) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final digitsAndPlus = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsAndPlus.isEmpty) return null;

    if (digitsAndPlus.startsWith('+')) {
      final rawDigits = digitsAndPlus.substring(1);
      if (RegExp(r'^[1-9]\d{6,14}$').hasMatch(rawDigits)) {
        return '+$rawDigits';
      }
      return null;
    }

    final localDigits = digitsAndPlus.replaceFirst(RegExp(r'^0+'), '');
    if (localDigits.isEmpty) return null;

    final prefix = getDialingPrefix(countryCode);
    if (prefix == null) {
      return null;
    }

    final combined = '$prefix$localDigits';
    final rawCombinedDigits = combined.substring(1);

    if (RegExp(r'^[1-9]\d{6,14}$').hasMatch(rawCombinedDigits)) {
      return combined;
    }
    return null;
  }
}

String countryCodeToFlagEmoji(String countryCode) {
  if (countryCode.length != 2) return '🌐';
  final int firstLetter =
      countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
  final int secondLetter =
      countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
}

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? addressToEdit;

  const AddEditAddressScreen({super.key, this.addressToEdit});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  String _selectedLabelType = 'HOME'; // 'HOME', 'WORK', 'OTHER'
  late final TextEditingController _customLabelController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _companyController;
  late final TextEditingController _postalController;
  late final TextEditingController _phoneController;

  String? _selectedCountryCode;
  bool _isDefaultShipping = false;
  bool _isDefaultBilling = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.addressToEdit;

    final existingLabel = addr?.label?.toUpperCase() ?? 'HOME';
    if (existingLabel == 'HOME' || existingLabel == 'WORK') {
      _selectedLabelType = existingLabel;
      _customLabelController = TextEditingController();
    } else {
      _selectedLabelType = 'OTHER';
      _customLabelController = TextEditingController(text: addr?.label ?? '');
    }

    _firstNameController = TextEditingController(text: addr?.firstName ?? '');
    _lastNameController = TextEditingController(text: addr?.lastName ?? '');
    _addressLine1Controller = TextEditingController(
      text: addr?.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: addr?.addressLine2 ?? '',
    );
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _companyController = TextEditingController(text: addr?.company ?? '');
    _selectedCountryCode = addr?.country.isNotEmpty == true
        ? addr!.country.toUpperCase()
        : null;
    _postalController = TextEditingController(text: addr?.postalCode ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _isDefaultShipping = addr?.isDefaultShipping ?? false;
    _isDefaultBilling = addr?.isDefaultBilling ?? false;
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _companyController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double _getRequiredCompletionRatio() {
    int total = 5;
    int completed = 0;
    if (_firstNameController.text.trim().isNotEmpty) completed++;
    if (_lastNameController.text.trim().isNotEmpty) completed++;
    if (_addressLine1Controller.text.trim().isNotEmpty) completed++;
    if (_cityController.text.trim().isNotEmpty) completed++;
    if (_selectedCountryCode != null && _selectedCountryCode!.isNotEmpty)
      completed++;
    return completed / total;
  }

  Future<void> _saveAddress(
    AppStrings strings,
    List<CountryModel> supportedCountries,
  ) async {
    if (_isSaving) return;

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _addressLine1Controller.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.fillRequired)));
      return;
    }

    if (_selectedCountryCode == null || _selectedCountryCode!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.countryCodeReq)));
      return;
    }

    final finalCountryCode = _selectedCountryCode!.trim().toUpperCase();

    if (supportedCountries.isNotEmpty) {
      final isCountryValid = supportedCountries.any(
        (c) => c.code == finalCountryCode,
      );
      if (!isCountryValid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.countryCodeReq)));
        return;
      }
    }

    String? normalizedPhone;
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isNotEmpty) {
      normalizedPhone = PhoneUtils.normalizeToE164(rawPhone, finalCountryCode);
      if (normalizedPhone == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.invalidPhoneFormat)));
        return;
      }
    }

    String finalLabel = _selectedLabelType;
    if (_selectedLabelType == 'OTHER') {
      final custom = _customLabelController.text.trim().toUpperCase();
      finalLabel = custom.isNotEmpty ? custom : 'OTHER';
    }

    setState(() {
      _isSaving = true;
    });

    final newAddress = AddressModel(
      id: widget.addressToEdit?.id ?? '',
      label: finalLabel,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      country: finalCountryCode,
      latitude: widget.addressToEdit?.latitude,
      longitude: widget.addressToEdit?.longitude,
      postalCode: _postalController.text.trim().isEmpty
          ? null
          : _postalController.text.trim(),
      phone: normalizedPhone,
      isDefaultShipping: _isDefaultShipping,
      isDefaultBilling: _isDefaultBilling,
    );

    try {
      AddressModel resultAddress;
      if (widget.addressToEdit == null) {
        await ref.read(addressProvider.notifier).addAddress(newAddress);
        resultAddress = newAddress;
      } else {
        await ref.read(addressProvider.notifier).updateAddress(newAddress);
        resultAddress = newAddress;
      }

      if (mounted) {
        Navigator.of(context).pop<AddressModel>(resultAddress);
      }
    } catch (e) {
      if (mounted) {
        final errMsg = AppErrorUtils.extractErrorMessage(
          e,
          fallback: strings.errorSavingAddress,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errMsg)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildFieldLabel(
    BuildContext context,
    String label, {
    bool isOptional = false,
    AppStrings? strings,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textTheme.fieldLabel),
          if (isOptional)
            Text(
              strings?.optionalTag ?? 'Optional',
              style: context.textTheme.secondaryNoticeText,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final countriesAsync = ref.watch(supportedCountriesProvider);

    if (_selectedCountryCode == null &&
        countriesAsync.value?.isNotEmpty == true) {
      final countries = countriesAsync.value!;
      _selectedCountryCode = countries
          .firstWhere((c) => c.code == 'KW', orElse: () => countries.first)
          .code;
    }

    final selectedCountryModel = countriesAsync.value
        ?.where((c) => c.code == _selectedCountryCode)
        .firstOrNull;
    final countryFlag = _selectedCountryCode != null
        ? countryCodeToFlagEmoji(_selectedCountryCode!)
        : '🌐';
    final countryName = selectedCountryModel?.name ?? 'Kuwait';
    final countryCode = _selectedCountryCode ?? 'KW';

    final dialingPrefix = PhoneUtils.getDialingPrefix(countryCode) ?? '+';
    final completionRatio = _getRequiredCompletionRatio();

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
          widget.addressToEdit == null
              ? strings.addAddress
              : strings.editAddress,
          style: context.textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Address Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.addressLabelHeader,
                  style: context.textTheme.secondaryNoticeText,
                ),
                Text(
                  strings.shownInYourList,
                  style: context.textTheme.secondaryNoticeText,
                ),
              ],
            ),
            SizedBox(height: 10.h(context)),
            AddressLabelSelector(
              selectedLabelType: _selectedLabelType,
              customLabelController: _customLabelController,
              strings: strings,
              isDark: isDark,
              onLabelTypeChanged: (type) =>
                  setState(() => _selectedLabelType = type),
            ),

            SizedBox(height: 20.h(context)),

            // Section 2: Delivery Details Header
            Text(
              strings.deliveryDetailsHeader,
              style: context.textTheme.secondaryNoticeText,
            ),
            SizedBox(height: 12.h(context)),

            // Country Selector Input Box
            _buildFieldLabel(
              context,
              strings.countryCodeReq.replaceAll('*', '').trim(),
            ),
            GestureDetector(
              onTap: countriesAsync.when(
                data: (countries) => countries.isNotEmpty
                    ? () => AddressCountrySelectorSheet.show(
                        context,
                        countries,
                        _selectedCountryCode,
                        strings,
                        (code) => setState(() => _selectedCountryCode = code),
                      )
                    : null,
                loading: () => null,
                error: (_, __) => null,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w(context),
                  vertical: 10.h(context),
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(16.w(context)),
                ),
                child: Row(
                  children: [
                    Text(
                      countryFlag,
                      style: TextStyle(fontSize: 14.sp(context)),
                    ),
                    SizedBox(width: 8.w(context)),
                    Text(countryName, style: context.textTheme.titleSmall),
                    SizedBox(width: 6.w(context)),
                    Text(
                      countryCode,
                      style: context.textTheme.secondaryNoticeText,
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h(context)),

            // Street Address
            _buildFieldLabel(context, strings.streetAddress),
            AppTextField(
              controller: _addressLine1Controller,
              hintText: strings.developmentDeliveryAddress,
              bkgColor: Theme.of(context).cardColor,
            ),

            SizedBox(height: 16.h(context)),

            // Apt, suite, building
            _buildFieldLabel(
              context,
              strings.aptSuiteBuildingOptional
                  .replaceAll('(Optional)', '')
                  .replaceAll('(اختياري)', '')
                  .trim(),
              isOptional: true,
              strings: strings,
            ),
            AppTextField(
              controller: _addressLine2Controller,
              hintText: strings.buildingFloorHint,
              bkgColor: Theme.of(context).cardColor,
            ),

            SizedBox(height: 16.h(context)),

            // City & State / Region
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(context, strings.city),
                      AppTextField(
                        controller: _cityController,
                        hintText: strings.defaultCityCountry.split(',').first,
                        bkgColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(
                        context,
                        strings.stateRegionLabel,
                        isOptional: true,
                        strings: strings,
                      ),
                      AppTextField(
                        controller: _stateController,
                        hintText: '—',
                        bkgColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h(context)),

            // Postal Code & Phone Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(
                        context,
                        strings.postalCode,
                        isOptional: true,
                        strings: strings,
                      ),
                      AppTextField(
                        controller: _postalController,
                        hintText: strings.ifRequiredHint,
                        bkgColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(context, strings.phoneNumber),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w(context),
                          vertical: 9.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(16.w(context)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              dialingPrefix,
                              style: context.textTheme.titleSmall,
                            ),
                            SizedBox(width: 8.w(context)),
                            Container(
                              width: 1,
                              height: 20.h(context),
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(width: 8.w(context)),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: '2121 2121',
                                ),
                                style: context.textTheme.field,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h(context)),

            // Section 3: Recipient
            Text(
              strings.recipientHeader,
              style: context.textTheme.secondaryNoticeText,
            ),
            SizedBox(height: 12.h(context)),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(context, strings.firstNameReq),
                      AppTextField(
                        controller: _firstNameController,
                        hintText: strings.firstNameHint,
                        bkgColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(context, strings.lastNameReq),
                      AppTextField(
                        controller: _lastNameController,
                        hintText: strings.lastNameHint,
                        bkgColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h(context)),

            // Default Switches
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                strings.setDefaultAddress,
                style: context.textTheme.titleMedium,
              ),
              value: _isDefaultShipping,
              activeTrackColor: AppColors.primary,
              onChanged: _isSaving
                  ? null
                  : (val) => setState(() => _isDefaultShipping = val),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                strings.setDefaultBillingAddress,
                style: context.textTheme.titleMedium,
              ),
              value: _isDefaultBilling,
              activeTrackColor: AppColors.primary,
              onChanged: _isSaving
                  ? null
                  : (val) => setState(() => _isDefaultBilling = val),
            ),

            SizedBox(height: 24.h(context)),

            // Required fields completion progress bar
            AddressCompletionProgressCard(
              completionRatio: completionRatio,
              isDark: isDark,
              strings: strings,
            ),

            SizedBox(height: 16.h(context)),

            // Save Address Button
            AppButton(
              text: widget.addressToEdit == null
                  ? strings.saveAddress
                  : strings.updateAddress,
              onPressed: _isSaving
                  ? null
                  : () => _saveAddress(strings, countriesAsync.value ?? []),
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
