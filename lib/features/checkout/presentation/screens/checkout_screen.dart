import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/address/models/address_model.dart';
import 'package:ecommerce/features/address/presentation/providers/address_provider.dart';
import 'package:ecommerce/features/checkout/models/checkout_models.dart';
import 'package:ecommerce/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:ecommerce/features/checkout/presentation/providers/payment_provider.dart';
import 'package:ecommerce/features/checkout/utils/payment_url_launcher.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';
import 'package:ecommerce/features/orders/presentation/providers/orders_provider.dart';
import 'package:ecommerce/features/orders/presentation/screens/order_details_screen.dart';
import '../widgets/checkout_address_section.dart';
import '../widgets/checkout_bottom_action_bar.dart';
import '../widgets/checkout_cart_summary_card.dart';
import '../widgets/checkout_delivery_method_section.dart';
import '../widgets/checkout_payment_method_section.dart';
import '../widgets/checkout_price_summary_card.dart';
import '../widgets/checkout_unverified_email_view.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _billingSameAsDelivery = true;
  bool _isSubmitting = false;
  bool _isPreviewLoading = false;
  bool _isUncertainSubmission = false;
  String? _previewError;

  String? _selectedShippingAddressId;
  String? _selectedBillingAddressId;
  String? _selectedShippingMethodCode;
  String _paymentMethod = 'CASH_ON_DELIVERY';

  final TextEditingController _couponController = TextEditingController();
  String? _appliedCouponCode;

  String? _idempotencyKey;
  int _previewRevision = 0;

  List<ShippingOptionModel> _shippingOptions = [];
  CheckoutPreviewModel? _preview;

  late Future<List<AddressModel>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _renewIdempotencyKey();
    _loadAddresses();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _renewIdempotencyKey() {
    _idempotencyKey =
        'idemp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  void _loadAddresses() {
    _addressesFuture = ref.read(addressRepositoryProvider).getAddresses();
  }

  void _onCheckoutInputsChanged({
    bool renewIdempotency = true,
    bool clearShippingMethod = false,
  }) {
    if (renewIdempotency) {
      _renewIdempotencyKey();
    }
    _isUncertainSubmission = false;
    if (clearShippingMethod) {
      _selectedShippingMethodCode = null;
      _shippingOptions = [];
      _preview = null;
    }
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    final localizationAsync = ref.read(appLocalizationLoaderProvider);
    final currentLang = ref.read(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    if (_selectedShippingAddressId == null) {
      setState(() {
        _shippingOptions = [];
        _selectedShippingMethodCode = null;
        _preview = null;
        _previewError = strings.selectDeliveryAddressReq;
      });
      return;
    }

    final currentRev = ++_previewRevision;
    setState(() {
      _isPreviewLoading = true;
      _previewError = null;
      _preview = null;
    });

    try {
      final repo = ref.read(checkoutRepositoryProvider);

      final options = await repo.getShippingOptions(
        shippingAddressId: _selectedShippingAddressId!,
        billingAddressId: _billingSameAsDelivery
            ? null
            : _selectedBillingAddressId,
        billingSameAsShipping: _billingSameAsDelivery,
        couponCode: _appliedCouponCode,
      );

      if (!mounted || currentRev != _previewRevision) return;

      setState(() {
        _shippingOptions = options;
        if (options.isEmpty) {
          _selectedShippingMethodCode = null;
        } else {
          final isCurrentValid = options.any(
            (opt) => opt.methodCode == _selectedShippingMethodCode,
          );
          if (!isCurrentValid) {
            _selectedShippingMethodCode = options.first.methodCode;
          }
        }
      });

      if (_selectedShippingMethodCode != null) {
        final preview = await repo.getPreview(
          shippingAddressId: _selectedShippingAddressId!,
          billingAddressId: _billingSameAsDelivery
              ? null
              : _selectedBillingAddressId,
          billingSameAsShipping: _billingSameAsDelivery,
          shippingMethodCode: _selectedShippingMethodCode,
          couponCode: _appliedCouponCode,
        );

        if (!mounted || currentRev != _previewRevision) return;

        setState(() {
          _preview = preview;
        });
      }
    } catch (e) {
      if (!mounted || currentRev != _previewRevision) return;

      String errMsg = AppErrorUtils.extractErrorMessage(
        e,
        fallback: strings.failedToCalcShipping,
      );
      if (e is DioException && e.response?.data is Map) {
        final code = (e.response?.data as Map)['code']?.toString();
        if (code == 'SHIPPING_PROFILE_NOT_CONFIGURED') {
          errMsg = strings.shippingProfileNotConfigured;
        } else if (code == 'NO_ELIGIBLE_FULFILLMENT_WAREHOUSE') {
          errMsg = strings.noEligibleFulfillmentWarehouse;
        }
      }

      setState(() {
        _previewError = errMsg;
        _shippingOptions = [];
        _selectedShippingMethodCode = null;
        _preview = null;
      });
    } finally {
      if (mounted && currentRev == _previewRevision) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }

  void _applyCoupon() {
    final localizationAsync = ref.read(appLocalizationLoaderProvider);
    final currentLang = ref.read(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    if (_selectedShippingAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.selectAddressBeforeCoupon)),
      );
      return;
    }

    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _appliedCouponCode = code;
    });
    _onCheckoutInputsChanged();
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponController.clear();
    });
    _onCheckoutInputsChanged();
  }

  Future<void> _placeOrder() async {
    if (_isSubmitting) return;

    final strings = AppLocalizations.of(context);

    if (_selectedShippingAddressId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.selectDeliveryAddressReq)));
      return;
    }

    if (!_billingSameAsDelivery && _selectedBillingAddressId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.selectBillingAddressReq)));
      return;
    }

    if (_selectedShippingMethodCode == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.selectShippingMethodReq)));
      return;
    }

    if (_preview == null || _isPreviewLoading || _previewError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_previewError ?? strings.waitPreviewComplete)),
      );
      return;
    }

    final requestTenantSlug = ref.read(selectedTenantSlugProvider);
    final requestUserId = ref.read(currentUserProvider).value?.id;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final result = await repo.placeOrder(
        shippingAddressId: _selectedShippingAddressId!,
        billingAddressId: _selectedBillingAddressId,
        billingSameAsShipping: _billingSameAsDelivery,
        shippingMethodCode: _selectedShippingMethodCode!,
        paymentMethod: _paymentMethod,
        couponCode: _appliedCouponCode,
        idempotencyKey: _idempotencyKey,
      );

      _isUncertainSubmission = false;

      if (!mounted ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(currentUserProvider).value?.id != requestUserId) {
        return;
      }

      ref.invalidate(cartProvider);
      ref.invalidate(myOrdersProvider);

      if (_paymentMethod == 'CARD') {
        final paymentId = result.payment?.id;
        if (paymentId != null && paymentId.isNotEmpty) {
          try {
            final paymentRepo = ref.read(paymentRepositoryProvider);
            final initiatedPayment = await paymentRepo.initiatePayment(
              paymentId,
            );
            final rawCheckoutUrl = initiatedPayment.checkoutUrl;
            if (rawCheckoutUrl != null && rawCheckoutUrl.isNotEmpty) {
              final launched = await PaymentUrlLauncher.launchPaymentUrl(
                rawCheckoutUrl,
              );
              if (!launched) {
                messenger.showSnackBar(
                  SnackBar(content: Text(strings.couldNotLaunchPaymentUrl)),
                );
              }
            }
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  AppErrorUtils.extractErrorMessage(
                    e,
                    fallback: strings.errorPlacingOrder,
                  ),
                ),
              ),
            );
          }
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(strings.get('order_placed')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: result.order.id),
        ),
      );
    } catch (e) {
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError)) {
        _isUncertainSubmission = true;
      }

      if (mounted &&
          ref.read(selectedTenantSlugProvider) == requestTenantSlug &&
          ref.read(currentUserProvider).value?.id == requestUserId) {
        final errMsg = AppErrorUtils.extractErrorMessage(
          e,
          fallback: strings.errorPlacingOrder,
        );
        messenger.showSnackBar(SnackBar(content: Text(errMsg)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  PreferredSizeWidget _appBarWidget(
    BuildContext context,
    AppStrings strings,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8F4EE),
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
      title: Text(strings.checkout, style: context.textTheme.titleLarge),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w(context)),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 14.sp(context),
                color: AppColors.lightTextSecondary,
              ),
              SizedBox(width: 4.w(context)),
              Text(
                strings.secureCheckout,
                style: context.textTheme.grayBodySmall,
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(4.h(context)),
        child: Container(height: 4.h(context), color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedTenantSlugProvider, (previous, next) {
      if (previous != null && previous != next) {
        _previewRevision++;
        setState(() {
          _preview = null;
          _shippingOptions = [];
          _selectedShippingAddressId = null;
          _selectedBillingAddressId = null;
          _selectedShippingMethodCode = null;
          _previewError = null;
        });
        _loadAddresses();
      }
    });

    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenant = ref.watch(tenantProvider);
    final currencyStr = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : 'KWD';

    final cartAsync = ref.watch(cartProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8F4EE),
      appBar: _appBarWidget(context, strings, isDark),
      body: user != null && !user.isEmailVerified
          ? CheckoutUnverifiedEmailView(user: user, strings: strings)
          : cartAsync.when(
              data: (cart) {
                return FutureBuilder<List<AddressModel>>(
                  future: _addressesFuture,
                  builder: (context, snapshot) {
                    final addresses = snapshot.data ?? [];
                    if (addresses.isEmpty) {
                      if (_selectedShippingAddressId != null ||
                          _selectedBillingAddressId != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedShippingAddressId = null;
                              _selectedBillingAddressId = null;
                              _selectedShippingMethodCode = null;
                              _shippingOptions = [];
                              _preview = null;
                              _previewError = strings.addAddressCalcShipping;
                            });
                          }
                        });
                      }
                    } else {
                      final shippingExists = addresses.any(
                        (a) => a.id == _selectedShippingAddressId,
                      );
                      if (_selectedShippingAddressId == null ||
                          !shippingExists) {
                        final defaultAddr = addresses.firstWhere(
                          (a) => a.isDefaultShipping,
                          orElse: () => addresses.first,
                        );
                        _selectedShippingAddressId = defaultAddr.id;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _onCheckoutInputsChanged(renewIdempotency: false);
                          }
                        });
                      }

                      if (!_billingSameAsDelivery) {
                        final billingExists = addresses.any(
                          (a) => a.id == _selectedBillingAddressId,
                        );
                        if (_selectedBillingAddressId == null ||
                            !billingExists) {
                          final defaultBilling = addresses.firstWhere(
                            (a) => a.isDefaultBilling,
                            orElse: () => addresses.first,
                          );
                          _selectedBillingAddressId = defaultBilling.id;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _onCheckoutInputsChanged(renewIdempotency: false);
                            }
                          });
                        }
                      }
                    }

                    final selectedAddressModel = addresses.firstWhere(
                      (a) => a.id == _selectedShippingAddressId,
                      orElse: () => addresses.isNotEmpty
                          ? addresses.first
                          : const AddressModel(
                              id: '',
                              firstName: '',
                              lastName: '',
                              addressLine1: 'Development delivery address',
                              city: 'Kuwait City',
                              country: 'KW',
                            ),
                    );

                    final selectedBillingAddressModel = addresses.firstWhere(
                      (a) => a.id == _selectedBillingAddressId,
                      orElse: () => addresses.isNotEmpty
                          ? addresses.firstWhere(
                              (a) => a.isDefaultBilling,
                              orElse: () => addresses.first,
                            )
                          : const AddressModel(
                              id: '',
                              firstName: '',
                              lastName: '',
                              addressLine1: 'Development billing address',
                              city: 'Kuwait City',
                              country: 'KW',
                            ),
                    );

                    final totalMoneyDisplay = _preview != null
                        ? formatOrderMoney(_preview!.totalAmount, currencyStr)
                        : formatOrderMoney(cart.subtotal, currencyStr);

                    return Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20.w(context),
                            10.h(context),
                            20.w(context),
                            140.h(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cart Summary Header Card
                              CheckoutCartSummaryCard(
                                cart: cart,
                                currencyStr: currencyStr,
                                strings: strings,
                                isDark: isDark,
                                tenant: tenant,
                              ),

                              SizedBox(height: 10.h(context)),

                              // 1. Delivery & Billing Address Section
                              CheckoutAddressSection(
                                selectedAddressModel: selectedAddressModel,
                                selectedBillingAddressModel:
                                    selectedBillingAddressModel,
                                addresses: addresses,
                                billingSameAsDelivery: _billingSameAsDelivery,
                                isUncertainSubmission: _isUncertainSubmission,
                                isDark: isDark,
                                strings: strings,
                                onChangeShippingAddress: (chosen) {
                                  setState(() {
                                    _loadAddresses();
                                    if (chosen != null) {
                                      _selectedShippingAddressId = chosen.id;
                                    }
                                  });
                                  _onCheckoutInputsChanged(
                                    clearShippingMethod: true,
                                  );
                                },
                                onChangeBillingAddress: (chosen) {
                                  setState(() {
                                    _loadAddresses();
                                    if (chosen != null) {
                                      _selectedBillingAddressId = chosen.id;
                                    }
                                  });
                                  _onCheckoutInputsChanged();
                                },
                                onBillingSameAsDeliveryChanged: (val) {
                                  setState(() {
                                    _billingSameAsDelivery = val;
                                    if (_billingSameAsDelivery) {
                                      _selectedBillingAddressId = null;
                                    } else {
                                      final defaultBilling = addresses
                                          .firstWhere(
                                            (a) => a.isDefaultBilling,
                                            orElse: () => addresses.first,
                                          );
                                      _selectedBillingAddressId =
                                          defaultBilling.id;
                                    }
                                  });
                                  _onCheckoutInputsChanged();
                                },
                              ),

                              SizedBox(height: 10.h(context)),

                              // 2. Delivery Method Section
                              CheckoutDeliveryMethodSection(
                                shippingOptions: _shippingOptions,
                                selectedShippingMethodCode:
                                    _selectedShippingMethodCode,
                                previewError: _previewError,
                                isPreviewLoading: _isPreviewLoading,
                                isUncertainSubmission: _isUncertainSubmission,
                                currencyStr: currencyStr,
                                isDark: isDark,
                                strings: strings,
                                onSelectShippingMethod: (methodCode) {
                                  setState(
                                    () => _selectedShippingMethodCode =
                                        methodCode,
                                  );
                                  _onCheckoutInputsChanged();
                                },
                              ),

                              // 3. Payment Method Section
                              CheckoutPaymentMethodSection(
                                paymentMethod: _paymentMethod,
                                isUncertainSubmission: _isUncertainSubmission,
                                strings: strings,
                                onPaymentMethodChanged: (method) {
                                  setState(() => _paymentMethod = method);
                                },
                              ),

                              // 4. Coupon & Price Summary Card
                              CheckoutPriceSummaryCard(
                                cart: cart,
                                preview: _preview,
                                shippingOptions: _shippingOptions,
                                selectedShippingMethodCode:
                                    _selectedShippingMethodCode,
                                appliedCouponCode: _appliedCouponCode,
                                isPreviewLoading: _isPreviewLoading,
                                isUncertainSubmission: _isUncertainSubmission,
                                currencyStr: currencyStr,
                                totalMoneyDisplay: totalMoneyDisplay,
                                isDark: isDark,
                                strings: strings,
                                couponController: _couponController,
                                onApplyCoupon: _applyCoupon,
                                onRemoveCoupon: _removeCoupon,
                              ),
                            ],
                          ),
                        ),

                        // 5. Sticky Bottom Action Bar
                        CheckoutBottomActionBar(
                          cart: cart,
                          preview: _preview,
                          isSubmitting: _isSubmitting,
                          isPreviewLoading: _isPreviewLoading,
                          isUncertainSubmission: _isUncertainSubmission,
                          previewError: _previewError,
                          totalMoneyDisplay: totalMoneyDisplay,
                          isDark: isDark,
                          strings: strings,
                          onPlaceOrder: _placeOrder,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => AppErrorWidget(
                message: strings.failedToCalcShipping,
                onRetry: _fetchPreview,
              ),
            ),
    );
  }
}
