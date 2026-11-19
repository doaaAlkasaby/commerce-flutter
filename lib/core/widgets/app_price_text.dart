import 'package:flutter/material.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class AppPriceTextRow extends StatelessWidget {
  final dynamic price;
  final String? currency;
  final TextStyle? priceStyle;
  final TextStyle? currencyStyle;
  final String? prefix;
  final String? suffix;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool isLarge;
  final Color? color;

  const AppPriceTextRow({
    super.key,
    required this.price,
    this.currency,
    this.priceStyle,
    this.currencyStyle,
    this.prefix,
    this.suffix,
    this.color,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.baseline,
    this.mainAxisSize = MainAxisSize.min,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = isLarge
        ? context.textTheme.primaryDisplayMax?.copyWith(color: color)
        : context.textTheme.primaryDisplaySmall?.copyWith(color: color);
    final basePriceStyle = priceStyle ?? defaultStyle ?? const TextStyle();

    final baseFontSize = basePriceStyle.fontSize ?? 14.sp(context);
    final effectiveCurrencyStyle =
        currencyStyle ??
        basePriceStyle.copyWith(
          fontSize: baseFontSize * 0.65,
          fontWeight: FontWeight.w500,
        );

    final rawPriceStr = price.toString();
    final formatted = formatOrderMoney(rawPriceStr, currency ?? "");

    final parts = formatted.split(' ');
    String pricePart = formatted;
    String currencyPart = '';

    if (parts.length >= 2) {
      if (RegExp(r'^-?\d').hasMatch(parts.first)) {
        pricePart = parts.first;
        currencyPart = parts.sublist(1).join(' ');
      } else if (RegExp(r'^-?\d').hasMatch(parts.last)) {
        pricePart = parts.last;
        currencyPart = parts.sublist(0, parts.length - 1).join(' ');
      }
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: mainAxisSize,
      children: [
        if (prefix != null && prefix!.isNotEmpty)
          Text(prefix!, style: basePriceStyle),
        Text(pricePart, style: basePriceStyle),
        if (currencyPart.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(currencyPart, style: effectiveCurrencyStyle),
        ],
        if (suffix != null && suffix!.isNotEmpty)
          Text(suffix!, style: basePriceStyle),
      ],
    );
  }
}

class AppPriceTextColumn extends StatelessWidget {
  final dynamic price;
  final String currency;
  final TextStyle? priceStyle;
  final TextStyle? currencyStyle;
  final String? prefix;
  final String? suffix;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool isLarge;

  const AppPriceTextColumn({
    super.key,
    required this.price,
    required this.currency,
    this.priceStyle,
    this.currencyStyle,
    this.prefix,
    this.suffix,
    this.crossAxisAlignment = CrossAxisAlignment.end,
    this.mainAxisSize = MainAxisSize.min,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = isLarge
        ? context.textTheme.primaryDisplayLarge
        : context.textTheme.primaryDisplaySmall;
    final basePriceStyle = priceStyle ?? defaultStyle ?? const TextStyle();

    final baseFontSize = basePriceStyle.fontSize ?? 14.sp(context);
    final effectiveCurrencyStyle =
        currencyStyle ??
        basePriceStyle.copyWith(
          fontSize: baseFontSize * 0.45,
          fontWeight: FontWeight.w500,
        );

    final rawPriceStr = price.toString();
    final formatted = formatOrderMoney(rawPriceStr, currency);

    final parts = formatted.split(' ');
    String pricePart = formatted;
    String currencyPart = '';

    if (parts.length >= 2) {
      if (RegExp(r'^-?\d').hasMatch(parts.first)) {
        pricePart = parts.first;
        currencyPart = parts.sublist(1).join(' ');
      } else if (RegExp(r'^-?\d').hasMatch(parts.last)) {
        pricePart = parts.last;
        currencyPart = parts.sublist(0, parts.length - 1).join(' ');
      }
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        if (prefix != null && prefix!.isNotEmpty)
          Text(prefix!, style: basePriceStyle),
        Text(pricePart, style: basePriceStyle),
        if (currencyPart.isNotEmpty)
          Text(currencyPart, style: effectiveCurrencyStyle),
        if (suffix != null && suffix!.isNotEmpty)
          Text(suffix!, style: basePriceStyle),
      ],
    );
  }
}
