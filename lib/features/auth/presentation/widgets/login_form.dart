import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';

class LoginFormWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLoginPressed;
  final VoidCallback onForgotPasswordPressed;
  final VoidCallback onCreateAccountPressed;
  final bool isArabic;

  const LoginFormWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onLoginPressed,
    required this.onForgotPasswordPressed,
    required this.onCreateAccountPressed,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(36.w(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: Offset(0, -8.h(context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w(context),
              height: 4.h(context),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.w(context)),
              ),
            ),
          ),
          SizedBox(height: 24.h(context)),
          Text(
            isArabic ? 'تسجيل الدخول' : 'Welcome back',
            style: context.textTheme.displaySmall?.copyWith(
              fontSize: 26.sp(context),
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextPrimary,
            ),
          ),
          SizedBox(height: 8.h(context)),
          Text(
            isArabic
                ? 'الرجاء إدخال بيانات حسابك'
                : 'Please enter your account details',
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 14.sp(context),
              color: AppColors.lightTextSecondary,
            ),
          ),
          SizedBox(height: 28.h(context)),
          AppTextField(
            controller: emailController,
            labelText: isArabic ? 'البريد الإلكتروني' : 'Email Address',
            hintText: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 20.h(context)),
          AppTextField(
            controller: passwordController,
            labelText: isArabic ? 'كلمة المرور' : 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.lightTextSecondary,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
          ),
          SizedBox(height: 24.h(context)),
          AppButton(
            text: isArabic ? 'تسجيل الدخول' : 'SIGN IN',
            onPressed: onLoginPressed,
            isLoading: isLoading,
          ),
          SizedBox(height: 16.h(context)),
          Center(
            child: TextButton(
              onPressed: onForgotPasswordPressed,
              child: Text(
                isArabic ? 'هل نسيت كلمة المرور؟' : 'Forgot password?',
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13.sp(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isArabic ? 'ليس لديك حساب؟' : "Don't have an account?",
                style: context.textTheme.titleSmall?.copyWith(
                  fontSize: 13.sp(context),
                  color: AppColors.lightTextSecondary,
                ),
              ),
              TextButton(
                onPressed: onCreateAccountPressed,
                child: Text(
                  isArabic ? 'إنشاء حساب' : 'Sign up',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontSize: 13.sp(context),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
