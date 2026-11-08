import 'package:flutter/material.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';

class RegisterFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onRegisterPressed;

  const RegisterFormWidget({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: nameController,
          labelText: 'Full Name',
          hintText: 'Amelia Wood',
          prefixIcon: Icons.person_outline,
        ),
        SizedBox(height: 16.h(context)),
        AppTextField(
          controller: emailController,
          labelText: 'Email',
          hintText: 'amelia.wood@gmail.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16.h(context)),
        AppTextField(
          controller: passwordController,
          labelText: 'Password',
          hintText: 'Create a password',
          prefixIcon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: onTogglePasswordVisibility,
          ),
        ),
        SizedBox(height: 32.h(context)),
        AppButton(
          text: 'SIGN UP',
          onPressed: onRegisterPressed,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
