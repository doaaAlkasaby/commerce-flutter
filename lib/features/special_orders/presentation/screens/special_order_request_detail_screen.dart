import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import '../providers/special_orders_provider.dart';

class SpecialOrderRequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const SpecialOrderRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.blue;
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'QUOTED':
        return Colors.purple;
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.badgeRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(specialOrderRequestDetailProvider(requestId));
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(
        title: Text(strings.requestDetails),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: requestAsync.when(
          data: (request) {
            if (request == null) {
              return Center(child: Text(strings.failedToLoadSpecialOrders));
            }

            final statusColor = _getStatusColor(request.status);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(20.w(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Summary Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w(context)),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.w(context)),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${strings.requestNumber.replaceAll('{number}', '')} ${request.requestNumber}',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w(context),
                                vertical: 4.h(context),
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.w(context)),
                              ),
                              child: Text(
                                request.status,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h(context)),
                        Text(
                          request.createdAt,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (request.contactPhone != null &&
                            request.contactPhone!.isNotEmpty) ...[
                          SizedBox(height: 8.h(context)),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16.sp(context),
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              SizedBox(width: 6.w(context)),
                              Text(
                                request.contactPhone!,
                                style: context.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (request.rejectionReason != null &&
                      request.rejectionReason!.isNotEmpty) ...[
                    SizedBox(height: 16.h(context)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w(context)),
                      decoration: BoxDecoration(
                        color: AppColors.badgeRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.w(context)),
                        border: Border.all(
                          color: AppColors.badgeRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.rejectionReason,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.badgeRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h(context)),
                          Text(
                            request.rejectionReason!,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColors.badgeRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (request.notes != null && request.notes!.isNotEmpty) ...[
                    SizedBox(height: 16.h(context)),
                    Text(
                      strings.orderNote,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h(context)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w(context)),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12.w(context)),
                      ),
                      child: Text(
                        request.notes!,
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h(context)),

                  // Requested Items Section
                  Text(
                    strings.requestedItems,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h(context)),

                  ...request.items.map(
                    (item) => Container(
                      margin: EdgeInsets.only(bottom: 10.h(context)),
                      padding: EdgeInsets.all(14.w(context)),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14.w(context)),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w(context),
                                  vertical: 2.h(context),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.w(context)),
                                ),
                                child: Text(
                                  '${strings.quantityLabel}: ${item.quantity}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.specifications != null &&
                              item.specifications!.isNotEmpty) ...[
                            SizedBox(height: 6.h(context)),
                            Text(
                              '${strings.specifications}: ${item.specifications}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (request.attachments.isNotEmpty) ...[
                    SizedBox(height: 20.h(context)),
                    Text(
                      strings.addPhoto,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h(context)),
                    ...request.attachments.map(
                      (att) => Container(
                        margin: EdgeInsets.only(bottom: 6.h(context)),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w(context),
                          vertical: 8.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(10.w(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              att.isPrescription
                                  ? Icons.medical_services_outlined
                                  : Icons.attach_file,
                              size: 18.sp(context),
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.w(context)),
                            Expanded(
                              child: Text(
                                att.fileName,
                                style: context.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (att.isPrescription)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w(context),
                                  vertical: 2.h(context),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.w(context)),
                                ),
                                child: const Text(
                                  'Rx',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => AppErrorWidget(
            message: strings.failedToLoadSpecialOrders,
            onRetry: () => ref.invalidate(specialOrderRequestDetailProvider(requestId)),
          ),
        ),
      ),
    );
  }
}
