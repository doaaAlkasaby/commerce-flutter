import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_drop_down.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/address/data/address_repository.dart';
import 'package:ecommerce/features/address/models/address_model.dart';
import 'package:ecommerce/features/orders/data/orders_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _billingSameAsDelivery = true;
  final TextEditingController _orderNoteController = TextEditingController();
  bool _isLoading = false;
  
  String? _selectedShippingAddressId;
  String? _selectedBillingAddressId;
  String _paymentMethod = 'CASH_ON_DELIVERY';

  late Future<List<AddressModel>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = AddressRepository(ref.read(dioClientProvider)).getAddresses();
  }

  Future<void> _placeOrder(BuildContext context, AppStrings strings) async {
    if (_selectedShippingAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ordersRepo = OrdersRepository(ref.read(dioClientProvider));
      await ordersRepo.placeOrder({
        'shippingAddressId': _selectedShippingAddressId,
        'billingSameAsShipping': _billingSameAsDelivery,
        if (!_billingSameAsDelivery && _selectedBillingAddressId != null)
          'billingAddressId': _selectedBillingAddressId,
        'paymentMethod': _paymentMethod,
        if (_orderNoteController.text.trim().isNotEmpty)
          'orderNote': _orderNoteController.text.trim(),
      });

      // Refresh cart
      ref.invalidate(cartProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.get('order_placed')),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
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
          strings.checkout,
          style: context.textTheme.titleLarge?.copyWith(
                fontSize: 20.sp(context),
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
        ),
      ),
      body: cartAsync.when(
        data: (cart) {
          return FutureBuilder<List<AddressModel>>(
            future: _addressesFuture,
            builder: (context, snapshot) {
              final addresses = snapshot.data ?? [];
              if (_selectedShippingAddressId == null && addresses.isNotEmpty) {
                _selectedShippingAddressId = addresses.first.id;
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w(context), 10.h(context), 20.w(context), 130.h(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        addresses.isEmpty
                            ? Text('No saved addresses. Please add one.', style: context.textTheme.description?.copyWith(fontSize: 13.sp(context)))
                            : AppDropDown<String>(
                                value: _selectedShippingAddressId,
                                labelText: strings.deliveryAddress,
                                hintText: 'Select delivery address',
                                items: addresses.map((addr) {
                                  return DropdownMenuItem(
                                    value: addr.id,
                                    child: Text('${addr.title}: ${addr.streetAddress}, ${addr.city}'),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedShippingAddressId = val),
                              ),
                        SizedBox(height: 16.h(context)),
                        Row(
                          children: [
                            Checkbox.adaptive(
                              value: _billingSameAsDelivery,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _billingSameAsDelivery = val ?? true),
                            ),
                            Text(
                              isArabic ? 'عنوان الفواتير هو نفس عنوان التوصيل' : 'Billing address is the same as delivery',
                              style: context.textTheme.boldTitleMedium?.copyWith(
                                    fontSize: 13.sp(context),
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h(context)),
                        if (!_billingSameAsDelivery) ...[
                          AppDropDown<String>(
                            value: _selectedBillingAddressId ?? addresses.firstOrNull?.id,
                            labelText: strings.billingAddress,
                            hintText: 'Select billing address',
                            items: addresses.map((addr) {
                              return DropdownMenuItem(
                                value: addr.id,
                                child: Text('${addr.title}: ${addr.streetAddress}, ${addr.city}'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedBillingAddressId = val),
                          ),
                          SizedBox(height: 16.h(context)),
                        ],
                        AppDropDown<String>(
                          value: _paymentMethod,
                          labelText: 'Payment Method',
                          hintText: 'Select payment method',
                          items: const [
                            DropdownMenuItem(value: 'CASH_ON_DELIVERY', child: Text('Cash on Delivery')),
                            DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Credit Card')),
                          ],
                          onChanged: (val) => setState(() => _paymentMethod = val ?? 'CASH_ON_DELIVERY'),
                        ),
                        SizedBox(height: 20.h(context)),
                        Text(
                          '${strings.yourOrder} (${cart.itemCount} items)',
                          style: context.textTheme.boldTitleLarge?.copyWith(
                                fontSize: 16.sp(context),
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                        ),
                        SizedBox(height: 8.h(context)),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : Colors.white,
                            borderRadius: BorderRadius.circular(24.w(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 4.h(context)),
                              ),
                            ],
                          ),
                          child: Column(
                            children: List.generate(cart.items.length, (index) {
                              final item = cart.items[index];
                              final imageUrl = item.variant.images.isNotEmpty ? item.variant.images.first.url : '';
                              return _buildOrderItem(
                                context,
                                imageUrl: imageUrl,
                                name: item.variant.product.name,
                                details: 'Qty: ${item.quantity} · \$${item.finalUnitPrice}',
                                price: '\$${item.totalPrice}',
                                isLast: index == cart.items.length - 1,
                                isDark: isDark,
                              );
                            }),
                          ),
                        ),
                        SizedBox(height: 20.h(context)),
                        AppTextField(
                          controller: _orderNoteController,
                          labelText: strings.orderNote,
                          hintText: 'Delivery instructions, a gift message, or anything we should know...',
                          maxLines: 3,
                        ),
                        SizedBox(height: 20.h(context)),
                        Text(
                          strings.priceSummary,
                          style: context.textTheme.boldTitleLarge?.copyWith(
                                fontSize: 16.sp(context),
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                        ),
                        SizedBox(height: 8.h(context)),
                        Container(
                          padding: EdgeInsets.all(20.w(context)),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : Colors.white,
                            borderRadius: BorderRadius.circular(24.w(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 4.h(context)),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildPriceRow(context, 'Subtotal (${cart.itemCount} items)', '\$${cart.subtotal}', isDark),
                              SizedBox(height: 12.h(context)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery', style: context.textTheme.bodyMedium?.copyWith(fontSize: 14.sp(context))),
                                  Text('Free', style: context.textTheme.boldTitleMedium?.copyWith(fontSize: 14.sp(context), color: AppColors.mintTeal)),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h(context)),
                                child: Divider(height: 1, color: Colors.grey.shade300),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total',
                                        style: context.textTheme.boldTitleLarge?.copyWith(
                                              fontSize: 18.sp(context),
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                      ),
                                      SizedBox(height: 2.h(context)),
                                      Text(
                                        'Including tax',
                                        style: context.textTheme.bodySmall?.copyWith(fontSize: 11.sp(context)),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${cart.subtotal}',
                                    style: context.textTheme.displayMedium?.copyWith(
                                          fontSize: 22.sp(context),
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(24.w(context), 16.h(context), 24.w(context), 28.h(context)),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: Offset(0, -6.h(context)),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(strings.total, style: context.textTheme.labelLarge?.copyWith(fontSize: 11.sp(context), color: AppColors.lightTextSecondary, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2.h(context)),
                                  Text(
                                    '\$${cart.subtotal}',
                                    style: context.textTheme.boldTitleLarge?.copyWith(
                                          fontSize: 22.sp(context),
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20.w(context)),
                              Expanded(
                                child: AppButton(
                                  text: strings.placeOrder,
                                  onPressed: () => _placeOrder(context, strings),
                                  isLoading: _isLoading,
                                  icon: Icons.lock_outline,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h(context)),
                          Text(
                            'Secure checkout · You can review before paying',
                            style: context.textTheme.bodySmall?.copyWith(fontSize: 11.sp(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildOrderItem(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required String details,
    required String price,
    required bool isLast,
    required bool isDark,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w(context)),
          child: Row(
            children: [
              Container(
                width: 60.w(context),
                height: 60.h(context),
                decoration: BoxDecoration(
                  color: AppColors.lightCategoryBg,
                  borderRadius: BorderRadius.circular(16.w(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.w(context)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              SizedBox(width: 14.w(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.textTheme.boldTitleMedium?.copyWith(
                            fontSize: 14.sp(context),
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                    ),
                    SizedBox(height: 4.h(context)),
                    Text(
                      details,
                      style: context.textTheme.bodySmall?.copyWith(fontSize: 12.sp(context)),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: context.textTheme.boldTitleMedium?.copyWith(
                      fontSize: 15.sp(context),
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(fontSize: 14.sp(context)),
        ),
        Text(
          value,
          style: context.textTheme.boldTitleMedium?.copyWith(
                fontSize: 14.sp(context),
                color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
        ),
      ],
    );
  }
}
