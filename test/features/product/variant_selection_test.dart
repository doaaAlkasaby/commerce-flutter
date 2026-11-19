import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/utils/variant_selection_helper.dart';

void main() {
  group('Task 06.10 — Product Variant Selection Helper Tests', () {
    const attrColor = ProductAttributeModel(
      id: 'a-color',
      name: 'Color',
      values: [
        ProductAttributeValueModel(id: 'v-beige', value: 'Beige'),
        ProductAttributeValueModel(id: 'v-black', value: 'Black'),
        ProductAttributeValueModel(id: 'v-burgundy', value: 'Burgundy'),
      ],
    );

    const attrSize = ProductAttributeModel(
      id: 'a-size',
      name: 'Size',
      values: [
        ProductAttributeValueModel(id: 'v-mini', value: 'Mini'),
        ProductAttributeValueModel(id: 'v-med', value: 'Medium'),
      ],
    );

    const attrMat = ProductAttributeModel(
      id: 'a-mat',
      name: 'Material',
      values: [
        ProductAttributeValueModel(id: 'v-veg', value: 'Vegan Leather'),
        ProductAttributeValueModel(id: 'v-gen', value: 'Genuine Leather'),
      ],
    );

    final attributes = [attrColor, attrSize, attrMat];

    final variants = [
      // Beige Mini Vegan
      const ProductVariantModel(
        id: 'var-1',
        sku: 'LUMA-BAG-BEI-MIN-VEG',
        price: 24.0,
        isActive: true,
        pricing: ProductPricingModel(basePrice: 24.0, finalPrice: 24.0),
        images: [],
        attributes: [
          VariantAttributeModel(attributeId: 'a-color', attributeName: 'Color', attributeValueId: 'v-beige', value: 'Beige'),
          VariantAttributeModel(attributeId: 'a-size', attributeName: 'Size', attributeValueId: 'v-mini', value: 'Mini'),
          VariantAttributeModel(attributeId: 'a-mat', attributeName: 'Material', attributeValueId: 'v-veg', value: 'Vegan Leather'),
        ],
        inventory: ProductVariantInventoryModel(quantity: 10, reservedQuantity: 0, availableQuantity: 10),
      ),
      // Beige Mini Genuine
      const ProductVariantModel(
        id: 'var-2',
        sku: 'LUMA-BAG-BEI-MIN-LEA',
        price: 31.0,
        isActive: true,
        pricing: ProductPricingModel(basePrice: 31.0, finalPrice: 31.0),
        images: [],
        attributes: [
          VariantAttributeModel(attributeId: 'a-color', attributeName: 'Color', attributeValueId: 'v-beige', value: 'Beige'),
          VariantAttributeModel(attributeId: 'a-size', attributeName: 'Size', attributeValueId: 'v-mini', value: 'Mini'),
          VariantAttributeModel(attributeId: 'a-mat', attributeName: 'Material', attributeValueId: 'v-gen', value: 'Genuine Leather'),
        ],
        inventory: ProductVariantInventoryModel(quantity: 10, reservedQuantity: 0, availableQuantity: 10),
      ),
      // Black Medium Genuine
      const ProductVariantModel(
        id: 'var-8',
        sku: 'LUMA-BAG-BLK-MED-LEA',
        price: 40.0,
        isActive: true,
        pricing: ProductPricingModel(basePrice: 40.0, finalPrice: 40.0),
        images: [],
        attributes: [
          VariantAttributeModel(attributeId: 'a-color', attributeName: 'Color', attributeValueId: 'v-black', value: 'Black'),
          VariantAttributeModel(attributeId: 'a-size', attributeName: 'Size', attributeValueId: 'v-med', value: 'Medium'),
          VariantAttributeModel(attributeId: 'a-mat', attributeName: 'Material', attributeValueId: 'v-gen', value: 'Genuine Leather'),
        ],
        inventory: ProductVariantInventoryModel(quantity: 10, reservedQuantity: 0, availableQuantity: 10),
      ),
      // Burgundy Medium Genuine (Out of Stock test)
      const ProductVariantModel(
        id: 'var-12',
        sku: 'LUMA-BAG-BUR-MED-LEA',
        price: 42.0,
        isActive: true,
        pricing: ProductPricingModel(basePrice: 42.0, finalPrice: 42.0),
        images: [],
        attributes: [
          VariantAttributeModel(attributeId: 'a-color', attributeName: 'Color', attributeValueId: 'v-burgundy', value: 'Burgundy'),
          VariantAttributeModel(attributeId: 'a-size', attributeName: 'Size', attributeValueId: 'v-med', value: 'Medium'),
          VariantAttributeModel(attributeId: 'a-mat', attributeName: 'Material', attributeValueId: 'v-gen', value: 'Genuine Leather'),
        ],
        inventory: ProductVariantInventoryModel(quantity: 0, reservedQuantity: 0, availableQuantity: 0),
      ),
    ];

    test('1. Initial selection initializes all 3 attribute groups from default variant', () {
      final selection = VariantSelectionHelper.initializeSelection(
        attributes: attributes,
        variants: variants,
        defaultVariantId: 'var-1',
      );

      expect(selection['a-color'], 'v-beige');
      expect(selection['a-size'], 'v-mini');
      expect(selection['a-mat'], 'v-veg');
    });

    test('2. findMatchingVariant finds exact variant when all 3 attribute values match', () {
      final selection = {
        'a-color': 'v-black',
        'a-size': 'v-med',
        'a-mat': 'v-gen',
      };

      final matched = VariantSelectionHelper.findMatchingVariant(variants, selection, 3);
      expect(matched, isNotNull);
      expect(matched?.sku, 'LUMA-BAG-BLK-MED-LEA');
      expect(matched?.pricing.finalPrice, 40.0);
    });

    test('3. findMatchingVariant returns null for incomplete or non-existent combinations', () {
      final incomplete = {
        'a-color': 'v-black',
        'a-size': 'v-med',
      };
      expect(VariantSelectionHelper.findMatchingVariant(variants, incomplete, 3), null);

      final nonExistent = {
        'a-color': 'v-black',
        'a-size': 'v-mini',
        'a-mat': 'v-veg',
      };
      expect(VariantSelectionHelper.findMatchingVariant(variants, nonExistent, 3), null);
    });

    test('4. isValueAvailable returns false for out-of-stock or invalid combinations', () {
      final currentSelection = {
        'a-color': 'v-burgundy',
        'a-size': 'v-med',
        'a-mat': 'v-gen',
      };

      final isAvailable = VariantSelectionHelper.isValueAvailable(
        targetAttributeId: 'a-mat',
        candidateValueId: 'v-gen',
        allAttributes: attributes,
        variants: variants,
        currentSelection: currentSelection,
      );

      expect(isAvailable, false);
    });

    test('5. Currency formatting renders KWD with 3 decimal places (24.000 KWD)', () {
      expect(VariantSelectionHelper.formatCurrency(24.0, 'KWD'), '24.000 KWD');
      expect(VariantSelectionHelper.formatCurrency(39.5, 'KWD'), '39.500 KWD');
      expect(VariantSelectionHelper.formatCurrency(25.0, 'USD'), '\$25.00');
    });
  });
}
