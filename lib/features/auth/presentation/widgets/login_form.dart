import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.w(context))),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.w(context)),
              ),
            ),
          ),
          SizedBox(height: 16.h(context)),
          Text(
            isArabic ? 'مرحباً بعودتك' : 'Welcome back',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 24.sp(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextPrimary,
                ),
          ),
          SizedBox(height: 4.h(context)),
          Text(
            isArabic ? 'تسجيل الدخول للمتابعة إلى الاستوديو الخاص بك.' : 'Sign in to continue to your studio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp(context),
                  color: AppColors.lightTextSecondary,
                ),
          ),
          SizedBox(height: 20.h(context)),
          Text(
            'Email',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 13.sp(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextSecondary,
                ),
          ),
          SizedBox(height: 6.h(context)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16.w(context)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.lightTextSecondary),
                suffixIcon: Icon(Icons.check_circle, color: AppColors.mintTeal),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          SizedBox(height: 16.h(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 13.sp(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              GestureDetector(
                onTap: onForgotPasswordPressed,
                child: Text(
                  'Forgot password?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13.sp(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h(context)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16.w(context)),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.lightTextSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.lightTextSecondary,
                  ),
                  onPressed: onTogglePasswordVisibility,
                ),
                hintText: 'Enter your password',
                hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w(context), vertical: 14.h(context)),
              ),
            ),
          ),
          SizedBox(height: 24.h(context)),
          SizedBox(
            width: double.infinity,
            height: 54.h(context),
            child: ElevatedButton(
              onPressed: isLoading ? null : onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27.w(context)),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24.w(context),
                      height: 24.h(context),
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'SIGN IN',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 16.sp(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                    ),
            ),
          ),
          SizedBox(height: 18.h(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New to Ivy Kids Studio? ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13.sp(context),
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              GestureDetector(
                onTap: onCreateAccountPressed,
                child: Text(
                  'Create account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13.sp(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h(context)),
          Center(
            child: Text(
              'VERSION 1.0.1',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11.sp(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                    letterSpacing: 1.0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
