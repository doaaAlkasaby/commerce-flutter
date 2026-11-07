import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';

class AppDropDown<T> extends StatelessWidget {
  final T? value;
  final String? labelText;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppDropDown({
    super.key,
    required this.value,
    this.labelText,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(labelText!, style: context.textTheme.fieldLabel?.copyWith(fontSize: 14.sp(context))),
          SizedBox(height: 8.h(context)),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.w(context)), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w(context), vertical: 12.h(context)),
          ),
          hint: Text(hintText, style: context.textTheme.secondaryHint?.copyWith(fontSize: 13.sp(context))),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
