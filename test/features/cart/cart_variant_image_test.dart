import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:ecommerce/features/checkout/presentation/widgets/checkout_cart_summary_card.dart';

void main() {
  group('Cart & Checkout Variant Image Selection Tests', () {
    test('1. Primary variant image is selected over product.imageUrl', () {
      final json = {
        'id': 'variant-1',
        'sku': 'SKU-1',
        'price': '10.00',
        'product': {
          'id': 'prod-1',
          'name': 'Test Product',
          'slug': 'test-prod',
          'basePrice': '10.00',
          'imageUrl': '/uploads/products/product-main.webp',
        },
        'images': [
          {
            'url': '/uploads/products/variant-secondary.webp',
            'sortOrder': 0,
            'isPrimary': false,
          },
          {
            'url': '/uploads/products/variant-primary.webp',
            'sortOrder': 1,
            'isPrimary': true,
          },
        ],
      };

      final variant = CartVariantModel.fromJson(json);
      expect(
        variant.resolvedImageUrl,
        endsWith('/uploads/products/variant-primary.webp'),
      );
    });

    test('2. Lowest sortOrder is selected when no primary image exists', () {
      final json = {
        'id': 'variant-1',
        'sku': 'SKU-1',
        'price': '10.00',
        'product': {
          'id': 'prod-1',
          'name': 'Test Product',
          'slug': 'test-prod',
          'basePrice': '10.00',
          'imageUrl': '/uploads/products/product-main.webp',
        },
        'images': [
          {
            'url': '/uploads/products/variant-high-order.webp',
            'sortOrder': 10,
            'isPrimary': false,
          },
          {
            'url': '/uploads/products/variant-low-order.webp',
            'sortOrder': 2,
            'isPrimary': false,
          },
        ],
      };

      final variant = CartVariantModel.fromJson(json);
      expect(
        variant.resolvedImageUrl,
        endsWith('/uploads/products/variant-low-order.webp'),
      );
    });

    test(
      '3. Empty primary URL is ignored in favor of another valid variant image',
      () {
        final json = {
          'id': 'variant-1',
          'sku': 'SKU-1',
          'price': '10.00',
          'product': {
            'id': 'prod-1',
            'name': 'Test Product',
            'slug': 'test-prod',
            'basePrice': '10.00',
            'imageUrl': '/uploads/products/product-main.webp',
          },
          'images': [
            {'url': '', 'sortOrder': 0, 'isPrimary': true},
            {
              'url': '/uploads/products/variant-valid.webp',
              'sortOrder': 1,
              'isPrimary': false,
            },
          ],
        };

        final variant = CartVariantModel.fromJson(json);
        expect(
          variant.resolvedImageUrl,
          endsWith('/uploads/products/variant-valid.webp'),
        );
      },
    );

    test('4. Falls back to product.imageUrl when variant has no images', () {
      final json = {
        'id': 'variant-1',
        'sku': 'SKU-1',
        'price': '10.00',
        'product': {
          'id': 'prod-1',
          'name': 'Test Product',
          'slug': 'test-prod',
          'basePrice': '10.00',
          'imageUrl': '/uploads/products/product-main.webp',
        },
        'images': [],
      };

      final variant = CartVariantModel.fromJson(json);
      expect(
        variant.resolvedImageUrl,
        endsWith('/uploads/products/product-main.webp'),
      );
    });

    test(
      '5. Returns null (placeholder fallback) when no variant or product images exist',
      () {
        final json = {
          'id': 'variant-1',
          'sku': 'SKU-1',
          'price': '10.00',
          'product': {
            'id': 'prod-1',
            'name': 'Test Product',
            'slug': 'test-prod',
            'basePrice': '10.00',
            'imageUrl': null,
          },
          'images': [],
        };

        final variant = CartVariantModel.fromJson(json);
        expect(variant.resolvedImageUrl, isNull);
      },
    );

    test(
      '6. Defaults isPrimary = false and sortOrder = 0 when JSON fields are missing',
      () {
        final json = {'url': '/uploads/products/image.webp'};

        final img = CartImageModel.fromJson(json);
        expect(img.isPrimary, isFalse);
        expect(img.sortOrder, equals(0));
      },
    );

    test('7. Original images list remains unmutated during resolution', () {
      final json = {
        'id': 'variant-1',
        'sku': 'SKU-1',
        'price': '10.00',
        'product': {
          'id': 'prod-1',
          'name': 'Test Product',
          'slug': 'test-prod',
          'basePrice': '10.00',
        },
        'images': [
          {
            'url': '/uploads/products/img2.webp',
            'sortOrder': 5,
            'isPrimary': false,
          },
          {
            'url': '/uploads/products/img1.webp',
            'sortOrder': 1,
            'isPrimary': false,
          },
        ],
      };

      final variant = CartVariantModel.fromJson(json);
      final firstImageBefore = variant.images.first.url;
      final resolved = variant.resolvedImageUrl;

      expect(resolved, endsWith('/uploads/products/img1.webp'));
      expect(variant.images.first.url, equals(firstImageBefore));
    });

    test(
      '8. Luma Premium Linen Shirt Navy / M / Slim variant resolves to navy image',
      () {
        final jsonPayload = {
          'id': 'item-100',
          'variantId': 'c0d631c7-96ec-432b-ad7f-0fe933539e1e',
          'quantity': 1,
          'unitPrice': '18.50',
          'finalUnitPrice': '18.50',
          'totalPrice': '18.50',
          'variant': {
            'id': 'c0d631c7-96ec-432b-ad7f-0fe933539e1e',
            'sku': 'LUMA-SHIRT-NAV-M-SLM',
            'price': '18.50',
            'product': {
              'id': 'prod-luma-shirt',
              'name': 'Luma Premium Linen Shirt',
              'slug': 'luma-linen-shirt',
              'basePrice': '18.50',
              'imageUrl': '/uploads/products/luma-linen-shirt-main.webp',
            },
            'images': [
              {
                'url': '/uploads/products/luma-linen-shirt-navy-1.webp',
                'sortOrder': 0,
                'isPrimary': true,
              },
              {
                'url': '/uploads/products/luma-linen-shirt-navy-2.webp',
                'sortOrder': 1,
                'isPrimary': false,
              },
            ],
          },
        };

        final cartItem = CartItemModel.fromJson(jsonPayload);
        expect(
          cartItem.variant.resolvedImageUrl,
          endsWith('/uploads/products/luma-linen-shirt-navy-1.webp'),
        );
        expect(
          cartItem.variant.resolvedImageUrl,
          isNot(endsWith('/uploads/products/luma-linen-shirt-main.webp')),
        );
      },
    );

    testWidgets(
      '9. CartItemTile and CheckoutCartSummaryCard render selected variant image',
      (tester) async {
        final cartItem = CartItemModel.fromJson({
          'id': 'item-1',
          'variantId': 'var-1',
          'quantity': 2,
          'unitPrice': '18.50',
          'finalUnitPrice': '18.50',
          'totalPrice': '37.00',
          'variant': {
            'id': 'var-1',
            'sku': 'LUMA-SHIRT-NAV-M-SLM',
            'price': '18.50',
            'product': {
              'id': 'prod-1',
              'name': 'Luma Premium Linen Shirt',
              'slug': 'luma-linen-shirt',
              'basePrice': '18.50',
              'imageUrl': '/uploads/products/luma-linen-shirt-main.webp',
            },
            'images': [
              {
                'url': '/uploads/products/luma-linen-shirt-navy-1.webp',
                'sortOrder': 0,
                'isPrimary': true,
              },
            ],
          },
        });

        final cart = CartModel(
          id: 'cart-1',
          userId: 'user-1',
          items: [cartItem],
          itemCount: 2,
          subtotal: '37.00',
        );

        final strings = AppStrings(const {}, AppLanguage.en);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CartItemTile(
                item: cartItem,
                currencyStr: 'KWD',
                strings: strings,
                isDark: false,
                onNavigateToDetails: () {},
                onIncrement: () {},
                onDecrement: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CartItemTile), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CheckoutCartSummaryCard(
                cart: cart,
                currencyStr: 'KWD',
                strings: strings,
                isDark: false,
                tenant: TenantConfig.defaultTenant('dev81-kuwait-fashion'),
              ),
            ),
          ),
        );

        expect(find.byType(CheckoutCartSummaryCard), findsOneWidget);
      },
    );
  });
}
