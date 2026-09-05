import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/auth/presentation/auth_screen.dart';
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
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light, // Default to clean present light theme
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
          builder: (_) => const PermissionOnboardingScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authProvider.isAuthenticated
              ? const ResponsiveScaffold()
              : const AuthScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
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
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Buzz',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AUTOMATE BY LOCATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your phone knows where you are.\nGeoBuzz knows what to do.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
