import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_colors.dart';
import 'core/app_settings.dart';
import 'screens/splash/splash_screen.dart';
import 'translations/app_localizations.dart';
import 'features/shared/notifications/data/mobile_notifications_transport.dart';
import 'screens/notification/notification_screen.dart';

class GpsfApp extends StatefulWidget {
  const GpsfApp({super.key, this.notifications});
  final MobileNotificationsTransport? notifications;

  @override
  State<GpsfApp> createState() => _GpsfAppState();
}

class _GpsfAppState extends State<GpsfApp> {
  final _settings = AppSettingsController();
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.notifications?.start(_settings, (id) {
      final userId = _settings.currentUser?.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && userId != null && _settings.currentUser?.id == userId) {
          _navigator.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) => NotificationScreen(initialNotificationId: id),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    widget.notifications?.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      controller: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          final localizations = AppLocalizations(_settings.language);
          return MaterialApp(
            navigatorKey: _navigator,
            title: localizations.text('appTitle'),
            debugShowCheckedModeBanner: false,
            locale: _settings.locale,
            supportedLocales: const [Locale('en'), Locale('km')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            themeMode: _settings.themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark
          ? AppColors.darkPrimary
          : AppColors.primary,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.surface,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
      ),
    );
  }
}
