import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/device_channel_service.dart';
import '../../home/presentation/home_screen.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PermissionOnboardingScreen({super.key, this.onComplete});

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  bool _locationGranted = false;
  bool _dndGranted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _locationGranted = true;
          _dndGranted = true;
        });
      }
      return;
    }

    final loc = await Geolocator.checkPermission();
    final dnd = await DeviceChannelService.isNotificationPolicyAccessGranted();

    if (mounted) {
      setState(() {
        _locationGranted = loc == LocationPermission.always || loc == LocationPermission.whileInUse;
        _dndGranted = dnd;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (mounted) {
        setState(() {
          _locationGranted = true;
        });
      }
    }
  }

  Future<void> _requestDndPermission() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _dndGranted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DND Access granted for web simulation!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return;
    }

    await DeviceChannelService.openNotificationPolicySettings();
    Future.delayed(const Duration(seconds: 2), () async {
      final dnd = await DeviceChannelService.isNotificationPolicyAccessGranted();
      if (mounted) {
        setState(() {
          _dndGranted = dnd;
        });
      }
    });
  }

  void _navigateToHome() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Brand Logo & Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppDimensions.roundedMd,
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GeoBuzz Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Configure essential device capabilities', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Permissions Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionTile(
                      step: 1,
                      title: 'Precise Location Access',
                      desc: 'Detects when you arrive or depart from your configured automation zones.',
                      icon: Icons.location_on_rounded,
                      isGranted: _locationGranted,
                      actionLabel: 'Allow Location',
                      onAction: _requestLocationPermission,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      step: 2,
                      title: 'Do Not Disturb Policy (Optional)',
                      desc: 'Allows GeoBuzz to switch your phone into Silent or Vibrate mode at work or school.',
                      icon: Icons.do_not_disturb_on_rounded,
                      isGranted: _dndGranted,
                      actionLabel: 'Grant Access',
                      onAction: _requestDndPermission,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      step: 3,
                      title: 'Background Automation Service',
                      desc: 'Ensures geofence rules evaluate reliably while the screen is locked.',
                      icon: Icons.battery_charging_full_rounded,
                      isGranted: true,
                      actionLabel: 'Configured',
                      onAction: () {},
                    ),
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Enter GeoBuzz Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required int step,
    required String title,
    required String desc,
    required IconData icon,
    required bool isGranted,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppDimensions.roundedLg,
        border: Border.all(
          color: isGranted ? AppColors.success.withAlpha(100) : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGranted ? AppColors.success.withAlpha(50) : AppColors.surfaceLightDark,
                  borderRadius: AppDimensions.roundedMd,
                ),
                child: Icon(icon, color: isGranted ? AppColors.success : Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
          const SizedBox(height: 12),
          if (!isGranted)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
