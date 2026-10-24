import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/auth/presentation/widgets/login_header.dart';
import 'package:ecommerce/features/auth/presentation/widgets/login_form.dart';
import 'package:ecommerce/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ecommerce/features/auth/presentation/screens/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController(text: kDebugMode ? 'customer1@example.com' : '');
  final TextEditingController _passwordController = TextEditingController(text: kDebugMode ? 'Password123!' : '');

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = AuthRepository(ref.read(dioClientProvider));
      final response = await authRepo.login(email, password);

      if (response.success && response.data != null) {
        final accessToken = response.data!.accessToken;
        final refreshToken = response.data!.refreshToken;
        
        ref.read(authTokenProvider.notifier).setToken(accessToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _buildContentWidget(),
    );
  }

  Widget _buildContentWidget() {
    final currentLang = ref.watch(languageProvider);
    final isArabic = currentLang == AppLanguage.ar;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w(context), vertical: 12.h(context)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42.w(context),
                  height: 42.w(context),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2.h(context)),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                      size: 16.sp(context),
                      color: AppColors.lightTextPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w(context), vertical: 8.h(context)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.w(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2.h(context)),
                        ),
                      ],
                    ),
                    child: Text(
                      isArabic ? 'تخطي' : 'Skip',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp(context),
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 2,
            child: LoginHeaderWidget(),
          ),
          LoginFormWidget(
            emailController: _emailController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            isLoading: _isLoading,
            onTogglePasswordVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            onLoginPressed: _handleLogin,
            onForgotPasswordPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            onCreateAccountPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            isArabic: isArabic,
          ),
        ],
      ),
    );
  }
}
