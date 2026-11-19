import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';

class AddressLabelSelector extends StatelessWidget {
  final String selectedLabelType;
  final TextEditingController customLabelController;
  final AppStrings strings;
  final bool isDark;
  final ValueChanged<String> onLabelTypeChanged;

  const AddressLabelSelector({
    super.key,
    required this.selectedLabelType,
    required this.customLabelController,
    required this.strings,
    required this.isDark,
    required this.onLabelTypeChanged,
  });

  Widget _buildLabelOption(
    BuildContext context,
    String key,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedLabelType == key;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16.sp(context),
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.lightTextPrimary,
          fontSize: 12.sp(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.w(context)),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          onLabelTypeChanged(key);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w(context),
          children: [
            _buildLabelOption(
              context,
              'HOME',
              strings.homeLabel,
              Icons.home_outlined,
            ),
            _buildLabelOption(
              context,
              'WORK',
              strings.workLabel,
              Icons.work_outline,
            ),
            _buildLabelOption(
              context,
              'OTHER',
              strings.otherLabel,
              Icons.label_outlined,
            ),
          ],
        ),
        if (selectedLabelType == 'OTHER') ...[
          SizedBox(height: 12.h(context)),
          AppTextField(
            controller: customLabelController,
            hintText: strings.addressLabelHint,
            labelText: strings.addressLabelHeader,
            bkgColor: Theme.of(context).cardColor,
          ),
        ],
      ],
    );
  }
}
