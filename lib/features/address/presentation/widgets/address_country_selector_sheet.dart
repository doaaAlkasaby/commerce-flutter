import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/address/models/country_model.dart';
import 'package:ecommerce/features/address/presentation/screens/add_edit_address_screen.dart';

class AddressCountrySelectorSheet extends StatefulWidget {
  final List<CountryModel> countries;
  final String? selectedCode;
  final AppStrings strings;
  final ValueChanged<String> onCountrySelected;

  const AddressCountrySelectorSheet({
    super.key,
    required this.countries,
    this.selectedCode,
    required this.strings,
    required this.onCountrySelected,
  });

  static void show(
    BuildContext context,
    List<CountryModel> countries,
    String? selectedCode,
    AppStrings strings,
    ValueChanged<String> onCountrySelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressCountrySelectorSheet(
        countries: countries,
        selectedCode: selectedCode,
        strings: strings,
        onCountrySelected: onCountrySelected,
      ),
    );
  }

  @override
  State<AddressCountrySelectorSheet> createState() =>
      _AddressCountrySelectorSheetState();
}

class _AddressCountrySelectorSheetState
    extends State<AddressCountrySelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = widget.countries.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.w(context)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w(context)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.strings.countryCodeReq.replaceAll('*', '').trim(),
                  style: context.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
            child: TextField(
              onChanged: (q) => setState(() => _searchQuery = q.trim()),
              decoration: InputDecoration(
                hintText: widget.strings.searchCountryHint,
                prefixIcon: const Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w(context),
                  vertical: 12.h(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.w(context)),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h(context)),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final c = filtered[idx];
                final isSelected = c.code == widget.selectedCode;
                final flag = countryCodeToFlagEmoji(c.code);

                return ListTile(
                  leading: Text(
                    flag,
                    style: TextStyle(fontSize: 24.sp(context)),
                  ),
                  title: Text(c.name, style: context.textTheme.bodyMedium),
                  subtitle: Text(
                    c.code,
                    style: context.textTheme.grayBodySmall,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    widget.onCountrySelected(c.code);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
