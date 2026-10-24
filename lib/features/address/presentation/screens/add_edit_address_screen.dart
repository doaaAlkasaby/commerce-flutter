import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import '../../models/address_model.dart';
import '../providers/address_provider.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? addressToEdit;

  const AddEditAddressScreen({super.key, this.addressToEdit});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late final TextEditingController _phoneController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.addressToEdit;
    _titleController = TextEditingController(text: addr?.title ?? 'HOME');
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _streetController = TextEditingController(text: addr?.streetAddress ?? '');
    _cityController = TextEditingController(text: addr?.city ?? 'Singapore');
    _postalController = TextEditingController(text: addr?.postalCode ?? '');
    _phoneController = TextEditingController(text: addr?.phoneNumber ?? '');
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_nameController.text.isEmpty || _streetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    final newAddress = AddressModel(
      id: widget.addressToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.toUpperCase(),
      fullName: _nameController.text,
      streetAddress: _streetController.text,
      city: _cityController.text,
      postalCode: _postalController.text,
      phoneNumber: _phoneController.text,
      isDefault: _isDefault,
    );

    if (widget.addressToEdit == null) {
      ref.read(addressProvider.notifier).addAddress(newAddress);
    } else {
      ref.read(addressProvider.notifier).updateAddress(newAddress);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                size: 16,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          widget.addressToEdit == null ? (isArabic ? 'إضافة عنوان' : 'Add Address') : (isArabic ? 'تعديل العنوان' : 'Edit Address'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Address Label (e.g. HOME, WORK)', _titleController),
            const SizedBox(height: 16),
            _buildTextField('Full Name', _nameController),
            const SizedBox(height: 16),
            _buildTextField('Street Address', _streetController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField('City', _cityController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Postal Code', _postalController)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Phone Number', _phoneController),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              title: const Text('Set as default address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: _isDefault,
              activeTrackColor: AppColors.primary,
              onChanged: (val) => setState(() => _isDefault = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                ),
                child: Text(
                  widget.addressToEdit == null ? 'SAVE ADDRESS' : 'UPDATE ADDRESS',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
