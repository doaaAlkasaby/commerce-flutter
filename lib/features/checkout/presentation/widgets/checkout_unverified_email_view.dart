import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';

class CheckoutUnverifiedEmailView extends ConsumerWidget {
  final UserDto user;
  final AppStrings strings;

  const CheckoutUnverifiedEmailView({
    super.key,
    required this.user,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 64,
              color: AppColors.badgeRed,
            ),
            SizedBox(height: 16.h(context)),
            Text(
              strings.emailVerificationRequired,
              style: context.textTheme.titleLarge,
            ),
            SizedBox(height: 8.h(context)),
            Text(
              strings
                  .get('verify_email_desc')
                  .replaceAll('{email}', user.email),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            SizedBox(height: 24.h(context)),
            AppButton(
              text: strings.resendVerificationEmail,
              onPressed: () async {
                try {
                  final repo = AuthRepository(ref.read(dioClientProvider));
                  if (user.email.isNotEmpty) {
                    await repo.resendVerification(user.email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.verificationEmailSent)),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppErrorUtils.extractErrorMessage(e)),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
