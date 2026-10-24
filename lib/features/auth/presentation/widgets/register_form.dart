import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

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
        Text(
          'Full Name',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp(context),
                color: AppColors.lightTextSecondary,
              ),
        ),
        SizedBox(height: 6.h(context)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w(context)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: AppColors.lightTextSecondary),
              hintText: 'Amelia Wood',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        SizedBox(height: 16.h(context)),
        Text(
          'Email',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp(context),
                color: AppColors.lightTextSecondary,
              ),
        ),
        SizedBox(height: 6.h(context)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w(context)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.lightTextSecondary),
              hintText: 'amelia.wood@gmail.com',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        SizedBox(height: 16.h(context)),
        Text(
          'Password',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp(context),
                color: AppColors.lightTextSecondary,
              ),
        ),
        SizedBox(height: 6.h(context)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w(context)),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.lightTextSecondary),
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: onTogglePasswordVisibility,
              ),
              hintText: 'Create a password',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w(context), vertical: 14.h(context)),
            ),
          ),
        ),
        SizedBox(height: 32.h(context)),
        SizedBox(
          width: double.infinity,
          height: 54.h(context),
          child: ElevatedButton(
            onPressed: isLoading ? null : onRegisterPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27.w(context))),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24.w(context),
                    height: 24.h(context),
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'SIGN UP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp(context),
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                  ),
          ),
        ),
      ],
    );
  }
}
