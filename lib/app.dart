import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/config/app_environment.dart';
import 'core/config/tenant_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/dio_client.dart';
import 'core/services/notification_navigation_handler.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/devices/presentation/providers/device_provider.dart';
import 'features/main_shell_screen.dart';
import 'features/storefront/presentation/providers/storefront_provider.dart';
import 'features/tenant_selection/presentation/screens/tenant_selection_screen.dart';

class EcommerceApp extends ConsumerWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(tenantProvider);
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final isTenantConfirmed = ref.watch(tenantConfirmationProvider);
    ref.watch(deviceRegistrationProvider);

    final isArabic = language == AppLanguage.ar;

    AppNotificationService().onNotificationTap = (data) {
      final token = ref.read(authTokenProvider);
      NotificationNavigationHandler.processNotificationTap(
        data,
        authToken: token,
      );
    };

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: tenant.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true),
      themeMode: themeMode,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: Theme(
          data: themeMode == ThemeMode.dark
              ? AppTheme.darkTheme(context)
              : AppTheme.lightTheme(context),
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        ),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      home: (AppEnvironment.isWhiteLabel || isTenantConfirmed)
          ? const StartupStorefrontGate()
          : const TenantSelectionScreen(),
    );
  }
}

class StartupStorefrontGate extends ConsumerWidget {
  const StartupStorefrontGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storefrontAsync = ref.watch(storefrontProvider);

    return storefrontAsync.when(
      data: (_) => const MainShellScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) {
        if (error is FormatException ||
            error is StateError ||
            (error is DioException && error.response?.statusCode == 404)) {
          return const TenantSelectionScreen();
        }

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unable to load store configuration. Please check your network connection and retry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(storefrontProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
