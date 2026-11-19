import 'package:flutter/material.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_drop_down.dart';

class CheckoutPaymentMethodSection extends StatelessWidget {
  final String paymentMethod;
  final bool isUncertainSubmission;
  final AppStrings strings;
  final ValueChanged<String> onPaymentMethodChanged;

  const CheckoutPaymentMethodSection({
    super.key,
    required this.paymentMethod,
    required this.isUncertainSubmission,
    required this.strings,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h(context)),
        AppDropDown<String>(
          value: paymentMethod,
          labelText: strings.paymentMethodStr,
          hintText: 'Select payment method',
          bkgColor: Theme.of(context).cardColor,
          labelStyle: context.textTheme.titleMedium,
          items: [
            DropdownMenuItem(
              value: 'CASH_ON_DELIVERY',
              child: Text(strings.codMethodLabel),
            ),
            if (AppEnvironment.currentEnvironment != EnvironmentType.prod)
              DropdownMenuItem(
                value: 'CARD',
                child: Text('${strings.cardMethodLabel} (Mock Gateway)'),
              )
            else
              DropdownMenuItem(
                value: 'CARD',
                child: Text(strings.cardMethodLabel),
              ),
          ],
          onChanged: (val) {
            if (isUncertainSubmission) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.uncertainOrderAttempt)),
              );
              return;
            }
            onPaymentMethodChanged(val ?? 'CASH_ON_DELIVERY');
          },
        ),
        SizedBox(height: 20.h(context)),
      ],
    );
  }
}
