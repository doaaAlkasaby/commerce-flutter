import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import '../providers/help_support_provider.dart';
import '../../utils/support_launcher.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h(context), bottom: 10.h(context)),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          padding: EdgeInsets.all(20.w(ctx)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24.w(ctx)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w(ctx),
                  height: 4.h(ctx),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.w(ctx)),
                  ),
                ),
              ),
              SizedBox(height: 16.h(ctx)),
              Text(
                title,
                style: ctx.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h(ctx)),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(content, style: ctx.textTheme.bodyMedium),
                ),
              ),
              SizedBox(height: 16.h(ctx)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h(context)),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2.h(context)),
          ),
        ],
      ),
      child: Material(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16.w(context)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 40.w(context),
            height: 40.w(context),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp(context)),
          ),
          title: Text(title, style: context.textTheme.titleSmall),
          subtitle: Text(subtitle, style: context.textTheme.grayBodySmall),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14.sp(context),
            color: AppColors.lightTextSecondary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final supportAsync = ref.watch(helpSupportProvider);

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
          strings.helpSupportTitle,
          style: context.textTheme.titleLarge,
        ),
      ),
      body: supportAsync.when(
        data: (model) {
          if (model.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(helpSupportProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: 120.h(context)),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w(context)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.help_outline,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 16.h(context)),
                          Text(
                            strings.noSupportInfo,
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleMedium,
                          ),
                          SizedBox(height: 16.h(context)),
                          ElevatedButton.icon(
                            onPressed: () =>
                                ref.invalidate(helpSupportProvider),
                            icon: const Icon(Icons.refresh),
                            label: Text(strings.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(helpSupportProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                20.w(context),
                10.h(context),
                20.w(context),
                40.h(context),
              ),
              children: [
                // Section 1: Contact Options
                if (model.hasContactInfo) ...[
                  _buildSectionHeader(context, strings.contactUs),
                  if (model.email != null && model.email!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.email_outlined,
                      title: strings.emailSupport,
                      subtitle: model.email!,
                      onTap: () async {
                        final ok = await SupportLauncher.launchEmail(
                          model.email!,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.couldNotLaunchAction),
                            ),
                          );
                        }
                      },
                    ),
                  if (model.phone != null && model.phone!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.phone_outlined,
                      title: strings.callUs,
                      subtitle: model.phone!,
                      onTap: () async {
                        final ok = await SupportLauncher.launchPhone(
                          model.phone!,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.couldNotLaunchAction),
                            ),
                          );
                        }
                      },
                    ),
                  if (model.whatsapp != null && model.whatsapp!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.chat_outlined,
                      title: strings.whatsappSupport,
                      subtitle: model.whatsapp!,
                      onTap: () async {
                        final ok = await SupportLauncher.launchWhatsApp(
                          model.whatsapp!,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.couldNotLaunchAction),
                            ),
                          );
                        }
                      },
                    ),
                  if (model.businessHours != null &&
                      model.businessHours!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 12.h(context)),
                      padding: EdgeInsets.all(16.w(context)),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(16.w(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            color: AppColors.primary,
                            size: 20.sp(context),
                          ),
                          SizedBox(width: 12.w(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.businessHours,
                                  style: context.textTheme.titleSmall,
                                ),
                                SizedBox(height: 2.h(context)),
                                Text(
                                  model.businessHours!,
                                  style: context.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Section 2: FAQ Accordions
                if (model.hasFaqs) ...[
                  _buildSectionHeader(context, strings.faqTitle),
                  ...model.faqs.map((faq) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h(context)),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(16.w(context)),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        title: Text(
                          faq.question,
                          style: context.textTheme.titleSmall,
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16.w(context),
                              0,
                              16.w(context),
                              16.h(context),
                            ),
                            child: Align(
                              alignment: isArabic
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                faq.answer,
                                style: context.textTheme.grayBodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Section 3: Policies
                if (model.hasPolicies) ...[
                  _buildSectionHeader(context, strings.storePolicies),
                  if (model.shippingPolicy != null &&
                      model.shippingPolicy!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.local_shipping_outlined,
                      title: strings.shippingPolicy,
                      subtitle: model.shippingPolicy!,
                      onTap: () async {
                        final val = model.shippingPolicy!;
                        if (SupportLauncher.isHttpsUrl(val)) {
                          final ok = await SupportLauncher.launchWebUrl(val);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.couldNotLaunchAction),
                              ),
                            );
                          }
                        } else {
                          _showPolicyDialog(
                            context,
                            strings.shippingPolicy,
                            val,
                          );
                        }
                      },
                    ),
                  if (model.returnPolicy != null &&
                      model.returnPolicy!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.published_with_changes_outlined,
                      title: strings.returnPolicy,
                      subtitle: model.returnPolicy!,
                      onTap: () async {
                        final val = model.returnPolicy!;
                        if (SupportLauncher.isHttpsUrl(val)) {
                          final ok = await SupportLauncher.launchWebUrl(val);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.couldNotLaunchAction),
                              ),
                            );
                          }
                        } else {
                          _showPolicyDialog(context, strings.returnPolicy, val);
                        }
                      },
                    ),
                  if (model.privacyPolicyUrl != null &&
                      model.privacyPolicyUrl!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.privacy_tip_outlined,
                      title: strings.privacyPolicy,
                      subtitle: model.privacyPolicyUrl!,
                      onTap: () async {
                        final ok = await SupportLauncher.launchWebUrl(
                          model.privacyPolicyUrl!,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.couldNotLaunchAction),
                            ),
                          );
                        }
                      },
                    ),
                  if (model.termsUrl != null && model.termsUrl!.isNotEmpty)
                    _buildContactTile(
                      context: context,
                      icon: Icons.description_outlined,
                      title: strings.termsOfService,
                      subtitle: model.termsUrl!,
                      onTap: () async {
                        final ok = await SupportLauncher.launchWebUrl(
                          model.termsUrl!,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.couldNotLaunchAction),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: strings.failedToLoadStorefront,
          onRetry: () => ref.invalidate(helpSupportProvider),
        ),
      ),
    );
  }
}
