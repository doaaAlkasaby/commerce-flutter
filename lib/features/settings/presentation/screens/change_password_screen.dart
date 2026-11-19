import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(AppStrings strings) async {
    if (_isSaving) return;

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.fillRequired)));
      return;
    }

    if (newPass.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(newPass) ||
        !RegExp(r'[a-z]').hasMatch(newPass) ||
        !RegExp(r'[0-9]').hasMatch(newPass) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(newPass)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.passwordComplexityReq)));
      return;
    }

    if (currentPass == newPass) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.newPasswordMustDiffer)));
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.passwordsDoNotMatch)));
      return;
    }

    final requestToken = ref.read(authTokenProvider);

    setState(() {
      _isSaving = true;
    });

    try {
      final authRepo = AuthRepository(ref.read(dioClientProvider));
      await authRepo.changePassword(currentPass, newPass);

      if (mounted && ref.read(authTokenProvider) == requestToken) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.passwordChangedSuccess)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted && ref.read(authTokenProvider) == requestToken) {
        final errMsg = AppErrorUtils.extractErrorMessage(
          e,
          fallback: strings.failedToChangePassword,
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

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = strings.isArabic;
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
          strings.changePassword,
          style: context.textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _currentPasswordController,
              labelText: strings.currentPasswordReq,
              obscureText: _obscureCurrent,
              bkgColor: Theme.of(context).cardColor,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  size: 20.sp(context),
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            SizedBox(height: 16.h(context)),
            AppTextField(
              controller: _newPasswordController,
              labelText: strings.newPasswordReq,
              obscureText: _obscureNew,
              bkgColor: Theme.of(context).cardColor,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                  size: 20.sp(context),
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            SizedBox(height: 16.h(context)),
            AppTextField(
              controller: _confirmPasswordController,
              labelText: strings.confirmNewPasswordReq,
              obscureText: _obscureConfirm,
              bkgColor: Theme.of(context).cardColor,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  size: 20.sp(context),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            SizedBox(height: 32.h(context)),
            AppButton(
              text: strings.changePasswordBtn,
              onPressed: _isSaving ? null : () => _changePassword(strings),
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
