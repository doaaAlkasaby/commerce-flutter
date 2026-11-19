import '../../home/models/home_response_model.dart';

class VariantSelectionHelper {
  /// Finds the matching active variant for a complete selection map (Key: attributeId, Value: attributeValueId)
  static ProductVariantModel? findMatchingVariant(
    List<ProductVariantModel> variants,
    Map<String, String> selectedValues,
    int totalAttributesCount,
  ) {
    if (totalAttributesCount > 0 &&
        selectedValues.length < totalAttributesCount) {
      return null;
    }

    for (final variant in variants) {
      if (!variant.isActive) continue;

      bool isMatch = true;
      for (final attr in variant.attributes) {
        if (selectedValues[attr.attributeId] != attr.attributeValueId) {
          isMatch = false;
          break;
        }
      }

      if (isMatch) return variant;
    }

    return null;
  }

  /// Determines whether a candidate attribute value is available (valid active variant with stock > 0)
  /// given the current selections of all OTHER attribute groups.
  static bool isValueAvailable({
    required String targetAttributeId,
    required String candidateValueId,
    required List<ProductAttributeModel> allAttributes,
    required List<ProductVariantModel> variants,
    required Map<String, String> currentSelection,
  }) {
    final otherSelections = Map<String, String>.from(currentSelection)
      ..remove(targetAttributeId);

    for (final variant in variants) {
      if (!variant.isActive) continue;

      final availableStock = variant.inventory?.availableQuantity ?? 10;
      if (availableStock <= 0) continue;

      final hasCandidate = variant.attributes.any(
        (attr) =>
            attr.attributeId == targetAttributeId &&
            attr.attributeValueId == candidateValueId,
      );
      if (!hasCandidate) continue;

      bool matchesOthers = true;
      for (final entry in otherSelections.entries) {
        final attrMatch = variant.attributes.any(
          (attr) =>
              attr.attributeId == entry.key &&
              attr.attributeValueId == entry.value,
        );
        if (!attrMatch) {
          matchesOthers = false;
          break;
        }
      }

      if (matchesOthers) return true;
    }

    return false;
  }

  /// Initial selection algorithm: prefers default active variant with stock, or first active variant with stock.
  static Map<String, String> initializeSelection({
    required List<ProductAttributeModel> attributes,
    required List<ProductVariantModel> variants,
    String? defaultVariantId,
  }) {
    if (attributes.isEmpty || variants.isEmpty) return {};

    ProductVariantModel? chosenVariant;

    if (defaultVariantId != null && defaultVariantId.isNotEmpty) {
      chosenVariant = variants.firstWhere(
        (v) =>
            v.id == defaultVariantId &&
            v.isActive &&
            (v.inventory?.availableQuantity ?? 1) > 0,
        orElse: () => variants.firstWhere(
          (v) => v.isActive && (v.inventory?.availableQuantity ?? 1) > 0,
          orElse: () => variants.firstWhere(
            (v) => v.isActive,
            orElse: () => variants.first,
          ),
        ),
      );
    } else {
      chosenVariant = variants.firstWhere(
        (v) => v.isActive && (v.inventory?.availableQuantity ?? 1) > 0,
        orElse: () => variants.firstWhere(
          (v) => v.isActive,
          orElse: () => variants.first,
        ),
      );
    }

    final selection = <String, String>{};
    for (final attr in chosenVariant.attributes) {
      selection[attr.attributeId] = attr.attributeValueId;
    }

    return selection;
  }

  /// Re-evaluates and reconciles selections when user clicks a value in targetAttributeGroup
  static Map<String, String> selectValue({
    required String targetAttributeId,
    required String selectedValueId,
    required List<ProductAttributeModel> attributes,
    required List<ProductVariantModel> variants,
    required Map<String, String> currentSelection,
  }) {
    final newSelection = Map<String, String>.from(currentSelection);
    newSelection[targetAttributeId] = selectedValueId;

    final directMatch = findMatchingVariant(
      variants,
      newSelection,
      attributes.length,
    );
    if (directMatch != null) return newSelection;

    for (final variant in variants) {
      if (!variant.isActive) continue;
      final availableStock = variant.inventory?.availableQuantity ?? 10;
      if (availableStock <= 0) continue;

      final hasTarget = variant.attributes.any(
        (attr) =>
            attr.attributeId == targetAttributeId &&
            attr.attributeValueId == selectedValueId,
      );

      if (hasTarget) {
        final resolvedSelection = <String, String>{};
        for (final attr in variant.attributes) {
          resolvedSelection[attr.attributeId] = attr.attributeValueId;
        }
        return resolvedSelection;
      }
    }

    return newSelection;
  }

  /// Currency Formatter Helper
  static String formatCurrency(double amount, String currencySymbol) {
    if (currencySymbol.toUpperCase() == 'KWD') {
      return '${amount.toStringAsFixed(3)} $currencySymbol';
    } else {
      final symbol = currencySymbol == 'USD' ? '\$' : currencySymbol;
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }
}
