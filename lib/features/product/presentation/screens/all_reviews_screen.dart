import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/models/review_models.dart';
import 'package:ecommerce/features/product/presentation/providers/reviews_provider.dart';
import '../widgets/review_card_tile.dart';
import '../widgets/review_summary_card.dart';

class AllReviewsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const AllReviewsScreen({super.key, required this.product});

  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(productReviewsControllerProvider(widget.product.id).notifier)
          .loadNextPage();
    }
  }

  void _showEditDialog(
    BuildContext context,
    ProductReviewModel review,
    AppStrings strings,
  ) {
    int editRating = review.rating;
    final titleCtrl = TextEditingController(text: review.title ?? '');
    final commentCtrl = TextEditingController(text: review.comment ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            title: Text(strings.editReview),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => editRating = index + 1),
                        child: Icon(
                          index < editRating ? Icons.star : Icons.star_border,
                          color: AppColors.starYellow,
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: strings.reviewTitleOptional,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    decoration: InputDecoration(
                      labelText: strings.reviewCommentLabel,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(strings.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final titleText = titleCtrl.text.trim();
                  final commentText = commentCtrl.text.trim();
                  if (titleText.isEmpty && commentText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.pleaseEnterTitleOrComment),
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogCtx).pop();
                  try {
                    await ref
                        .read(
                          productReviewsControllerProvider(
                            widget.product.id,
                          ).notifier,
                        )
                        .updateReview(
                          review.id,
                          rating: editRating,
                          title: titleText.isNotEmpty ? titleText : null,
                          comment: commentText.isNotEmpty ? commentText : null,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.reviewUpdatedSuccess)),
                      );
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
                child: Text(strings.saveBtn),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProductReviewModel review,
    AppStrings strings,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.deleteReviewTitle),
        content: Text(strings.confirmDeleteReview),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await ref
                    .read(
                      productReviewsControllerProvider(
                        widget.product.id,
                      ).notifier,
                    )
                    .deleteReview(review.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.reviewDeletedSuccess)),
                  );
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.badgeRed,
            ),
            child: Text(strings.deleteBtn),
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

    final currentUser = ref.watch(currentUserProvider).value;
    final reviewsAsync = ref.watch(
      productReviewsControllerProvider(widget.product.id),
    );

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
          strings.productReviews,
          style: context.textTheme.titleLarge,
        ),
      ),
      body: reviewsAsync.when(
        data: (stateData) {
          final summary = stateData.summary;
          final reviews = stateData.items;

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(
                    productReviewsControllerProvider(
                      widget.product.id,
                    ).notifier,
                  )
                  .refresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                if (summary != null)
                  SliverToBoxAdapter(
                    child: ReviewSummaryCard(
                      summary: summary,
                      strings: strings,
                      isDark: isDark,
                    ),
                  ),
                if (reviews.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40.w(context)),
                      child: AppEmptyWidget(
                        title: strings.noReviewsYetForProduct,
                        icon: Icons.rate_review_outlined,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w(context)),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final review = reviews[index];
                        final isOwner =
                            currentUser != null &&
                            currentUser.id == review.user.id;

                        return ReviewCardTile(
                          review: review,
                          isOwner: isOwner,
                          isDark: isDark,
                          onEdit: () =>
                              _showEditDialog(context, review, strings),
                          onDelete: () =>
                              _confirmDelete(context, review, strings),
                        );
                      }, childCount: reviews.length),
                    ),
                  ),
                if (stateData.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h(context)),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (stateData.loadMoreError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h(context)),
                      child: Column(
                        children: [
                          Text(
                            strings.failedToLoadMoreReviews,
                            style: context.textTheme.redTitleSmall,
                          ),
                          SizedBox(height: 8.h(context)),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(
                                    productReviewsControllerProvider(
                                      widget.product.id,
                                    ).notifier,
                                  )
                                  .loadNextPage();
                            },
                            child: Text(strings.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: strings.failedToLoadReviews,
          onRetry: () => ref.invalidate(
            productReviewsControllerProvider(widget.product.id),
          ),
        ),
      ),
    );
  }
}
