import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/settings/presentation/screens/change_password_screen.dart';
import 'package:ecommerce/features/settings/presentation/screens/edit_profile_screen.dart';
import 'settings_menu_card.dart';

class SettingsAccountActionsCard extends ConsumerStatefulWidget {
  final AppStrings strings;
  final bool isDark;

  const SettingsAccountActionsCard({
    super.key,
    required this.strings,
    required this.isDark,
  });

  @override
  ConsumerState<SettingsAccountActionsCard> createState() =>
      _SettingsAccountActionsCardState();
}

class _SettingsAccountActionsCardState
    extends ConsumerState<SettingsAccountActionsCard> {
  bool _isResendingVerification = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return SettingsMenuCard(
      isDark: widget.isDark,
      children: [
        SettingsMenuItem(
          strings: widget.strings,
          icon: Icons.edit,
          iconColor: AppColors.mintTeal,
          title: widget.strings.editProfile,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
            );
          },
        ),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: widget.strings,
          icon: Icons.lock_outline,
          iconColor: Colors.blue,
          title: widget.strings.password,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            );
          },
        ),
        if (user != null && !user.isEmailVerified) ...[
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          SettingsMenuItem(
            strings: widget.strings,
            icon: Icons.mark_email_unread_outlined,
            iconColor: AppColors.mintTeal,
            title: widget.strings.resendVerificationEmail,
            onTap: _isResendingVerification
                ? () {}
                : () async {
                    setState(() {
                      _isResendingVerification = true;
                    });
                    final messenger = ScaffoldMessenger.of(context);
                    final token = ref.read(authTokenProvider);
                    try {
                      final authRepo = AuthRepository(
                        ref.read(dioClientProvider),
                      );
                      await authRepo.resendVerification(user.email);
                      if (mounted && ref.read(authTokenProvider) == token) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.strings
                                  .get('verification_email_sent_to')
                                  .replaceAll('{email}', user.email),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted && ref.read(authTokenProvider) == token) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(AppErrorUtils.extractErrorMessage(e)),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isResendingVerification = false;
                        });
                      }
                    }
                  },
          ),
        ],
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: widget.strings,
          icon: Icons.logout,
          iconColor: AppColors.primary,
          title: widget.strings.logoutAllDevices,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              final authRepo = AuthRepository(ref.read(dioClientProvider));
              await authRepo.logoutAll();
              ref.read(authTokenProvider.notifier).setToken(null);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(widget.strings.loggedOutAllDevicesSuccess),
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
              );
            }
          },
        ),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: widget.strings,
          icon: Icons.logout,
          iconColor: AppColors.badgeRed,
          title: widget.strings.logOut,
          onTap: () async {
            ref.read(authTokenProvider.notifier).setToken(null);
          },
        ),
      ],
    );
  }
}
