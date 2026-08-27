import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/rules/domain/rule_provider.dart';
import 'features/history/domain/history_provider.dart';
import 'features/home/presentation/responsive_scaffold.dart';
import 'features/onboarding/presentation/permission_onboarding_screen.dart';
import 'shared/widgets/geobuzz_preloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeoBuzzApp());
}

class GeoBuzzApp extends StatelessWidget {
  const GeoBuzzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RuleProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'GeoBuzz - Automate by Location',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Default to sleek dark theme
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialNavigation();
  }

  Future<void> _checkInitialNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    bool hasLocationPermission = false;
    try {
      final permission = await Geolocator.checkPermission();
      hasLocationPermission =
          permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (_) {
      hasLocationPermission = false;
    }

    if (!mounted) return;

    if (!hasLocationPermission) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PermissionOnboardingScreen(
            onComplete: () async {
              if (!authProvider.isAuthenticated) {
                await authProvider.continueAsGuest();
              }
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ResponsiveScaffold()),
                );
              }
            },
          ),
        ),
      );
    } else {
      if (!authProvider.isAuthenticated) {
        await authProvider.continueAsGuest();
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResponsiveScaffold()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GeoBuzzPreloader(
              size: 110,
            ),
            const SizedBox(height: 28),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Geo',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Buzz',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AUTOMATE BY LOCATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your phone knows where you are. GeoBuzz knows what to do.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMutedDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
