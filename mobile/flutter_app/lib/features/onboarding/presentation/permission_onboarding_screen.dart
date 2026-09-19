import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/device_channel_service.dart';
import '../../../shared/widgets/geobuzz_brand_logo.dart';
import '../../../shared/widgets/hero_video_background.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../home/presentation/responsive_scaffold.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PermissionOnboardingScreen({super.key, this.onComplete});

  @override
  State<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState
    extends State<PermissionOnboardingScreen> {
  bool _locationGranted = true;
  bool _dndGranted = true;

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

    try {
      final loc = await Geolocator.checkPermission();
      final dnd =
          await DeviceChannelService.isNotificationPolicyAccessGranted();

      if (mounted) {
        setState(() {
          _locationGranted = loc == LocationPermission.always ||
              loc == LocationPermission.whileInUse;
          _dndGranted = dnd;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationGranted = true;
          _dndGranted = true;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    if (kIsWeb) {
      setState(() => _locationGranted = true);
      return;
    }
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
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
      }
      return;
    }

    await DeviceChannelService.openNotificationPolicySettings();
    Future.delayed(const Duration(seconds: 2), () async {
      final dnd =
          await DeviceChannelService.isNotificationPolicyAccessGranted();
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
      return;
    }
    final authProvider = context.read<AuthProvider>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authProvider.isAuthenticated
            ? const ResponsiveScaffold()
            : const AuthScreen(),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        backgroundColor: const Color(0xFF0C0E18),
        title: const Text(
          'Privacy & Permissions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'GeoBuzz is private by design. Your location triggers stay completely on your device and are never sold or shared.',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: Color(0xFF19E6DF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int readyCount =
        (_locationGranted ? 1 : 0) + (_dndGranted ? 1 : 0) + 1;
    final size = MediaQuery.of(context).size;
    final bool isComputer = size.width >= 900;
    final bool isTablet = size.width >= 600 && size.width < 900;
    final bool isCompact = size.width < 380;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Globe Starfield Background matching Homepage
          RepaintBoundary(
            child: HeroVideoBackground(reducedMotion: reducedMotion),
          ),
          // Gradient Scrim for readable high-contrast dark theme
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x80000000),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: isComputer
                ? _buildComputerLayout(readyCount, size)
                : _buildMobileOrTabletLayout(readyCount, isCompact, isTablet),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPUTER / DESKTOP / LAPTOP LAYOUT (≥ 900px)
  // ==========================================
  Widget _buildComputerLayout(int readyCount, Size size) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 36.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Branding, Hero Serif Heading, Progress, and CTA
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(isCompact: false),
                      const SizedBox(height: 36),
                      _buildProgressSection(readyCount, isCompact: false),
                      const SizedBox(height: 24),
                      _buildStatusChip(),
                      const SizedBox(height: 20),
                      const Text(
                        'Your phone is ready\nto work smarter.',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GeoBuzz has the access it needs to quietly keep your routines in sync—wherever your day takes you.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          color: const Color(0xFF94A3B8),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPrimaryCta(),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your permissions stay securely on your device',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Column: Glassmorphic Cards Stack
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSetupCard(
                      iconBgColor: const Color(0xFF19E6DF).withValues(alpha: 0.15),
                      iconColor: const Color(0xFF19E6DF),
                      icon: Icons.location_on_outlined,
                      title: 'Precise Location',
                      desc: 'Detects arrivals and departures from your automation zones.',
                      bottomIcon: Icons.shield_outlined,
                      bottomIconColor: const Color(0xFF34D399),
                      bottomLabel: 'Always allowed',
                      isReady: _locationGranted,
                      onTap: _requestLocationPermission,
                    ),
                    const SizedBox(height: 16),
                    _buildSetupCard(
                      iconBgColor: Colors.white.withValues(alpha: 0.08),
                      iconColor: const Color(0xFFE2E8F0),
                      icon: Icons.notifications_off_outlined,
                      title: 'Do Not Disturb',
                      optionalBadge: true,
                      desc: 'Silences or vibrates your phone when you arrive at focus zones.',
                      bottomIcon: Icons.event_available_outlined,
                      bottomIconColor: const Color(0xFF19E6DF),
                      bottomLabel: 'Policy access granted',
                      isReady: _dndGranted,
                      onTap: _requestDndPermission,
                    ),
                    const SizedBox(height: 16),
                    _buildSetupCard(
                      iconBgColor: const Color(0xFF19E6DF).withValues(alpha: 0.25),
                      iconColor: Colors.white,
                      icon: Icons.bolt_rounded,
                      title: 'Background Automation',
                      desc: 'Keeps geofence rules reliable while your screen is locked.',
                      bottomIcon: Icons.show_chart_rounded,
                      bottomIconColor: const Color(0xFF19E6DF),
                      bottomLabel: 'Running in the background',
                      isReady: true,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE & TABLET LAYOUT (< 900px)
  // ==========================================
  Widget _buildMobileOrTabletLayout(
      int readyCount, bool isCompact, bool isTablet) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 600 : 480,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 18.0 : (isTablet ? 32.0 : 22.0),
            vertical: isTablet ? 32.0 : 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact: isCompact),
              SizedBox(height: isTablet ? 30 : 24),
              _buildProgressSection(readyCount, isCompact: isCompact),
              SizedBox(height: isTablet ? 24 : 18),
              _buildStatusChip(),
              const SizedBox(height: 16),
              Text(
                'Your phone is ready\nto work smarter.',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: isCompact ? 26 : (isTablet ? 36 : 30),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'GeoBuzz has the access it needs to quietly keep your routines in sync—wherever your day takes you.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompact ? 13.5 : 14.5,
                  color: const Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              SizedBox(height: isTablet ? 26 : 20),

              // Setup Cards
              _buildSetupCard(
                iconBgColor: const Color(0xFF19E6DF).withValues(alpha: 0.15),
                iconColor: const Color(0xFF19E6DF),
                icon: Icons.location_on_outlined,
                title: 'Precise Location',
                desc: 'Detects arrivals and departures from your automation zones.',
                bottomIcon: Icons.shield_outlined,
                bottomIconColor: const Color(0xFF34D399),
                bottomLabel: 'Always allowed',
                isReady: _locationGranted,
                onTap: _requestLocationPermission,
                isCompact: isCompact,
              ),
              const SizedBox(height: 14),
              _buildSetupCard(
                iconBgColor: Colors.white.withValues(alpha: 0.08),
                iconColor: const Color(0xFFE2E8F0),
                icon: Icons.notifications_off_outlined,
                title: 'Do Not Disturb',
                optionalBadge: true,
                desc: 'Silences or vibrates your phone when you arrive at focus zones.',
                bottomIcon: Icons.event_available_outlined,
                bottomIconColor: const Color(0xFF19E6DF),
                bottomLabel: 'Policy access granted',
                isReady: _dndGranted,
                onTap: _requestDndPermission,
                isCompact: isCompact,
              ),
              const SizedBox(height: 14),
              _buildSetupCard(
                iconBgColor: const Color(0xFF19E6DF).withValues(alpha: 0.25),
                iconColor: Colors.white,
                icon: Icons.bolt_rounded,
                title: 'Background Automation',
                desc: 'Keeps geofence rules reliable while your screen is locked.',
                bottomIcon: Icons.show_chart_rounded,
                bottomIconColor: const Color(0xFF19E6DF),
                bottomLabel: 'Running in the background',
                isReady: true,
                isHighlighted: true,
                isCompact: isCompact,
              ),

              SizedBox(height: isTablet ? 30 : 24),
              _buildPrimaryCta(),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Your permissions stay securely on your device',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 12),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SHARED REUSABLE COMPONENTS
  // ==========================================
  Widget _buildHeader({required bool isCompact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GeoBuzzBrandLogo(
          size: isCompact ? 34 : 38,
          isDark: true,
          showText: false,
        ),
        SizedBox(width: isCompact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GEOBUZZ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: const Color(0xFF19E6DF),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Automation that moves with you',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompact ? 12 : 13,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _showInfoDialog,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: isCompact ? 36 : 40,
            height: isCompact ? 36 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              size: isCompact ? 18 : 20,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(int readyCount, {required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'SETUP COMPLETE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$readyCount of 3 ready',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF19E6DF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 5,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.12),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: readyCount / 3.0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF19E6DF), Color(0xFF00A3A6)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF19E6DF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF19E6DF).withValues(alpha: 0.3),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 3.5,
              backgroundColor: Color(0xFF34D399),
            ),
            const SizedBox(width: 8),
            Text(
              'Everything looks good',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryCta() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _navigateToHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF061014),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF061014),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Color(0xFF061014),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupCard({
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    bool optionalBadge = false,
    required String desc,
    required IconData bottomIcon,
    required Color bottomIconColor,
    required String bottomLabel,
    required bool isReady,
    bool isHighlighted = false,
    bool isCompact = false,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color(0xFF19E6DF).withValues(alpha: 0.08)
                    : const Color(0xFF0F172A).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF19E6DF).withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.12),
                  width: isHighlighted ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: isCompact ? 40 : 44,
                        height: isCompact ? 40 : 44,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(icon, color: iconColor, size: isCompact ? 20 : 22),
                      ),
                      SizedBox(width: isCompact ? 12 : 14),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isCompact ? 15 : 16.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (optionalBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'OPTIONAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 10,
                          vertical: isCompact ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19E6DF).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF19E6DF).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Color(0xFF19E6DF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ready',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF19E6DF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isCompact ? 13 : 14,
                      color: const Color(0xFFCBD5E1),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        bottomIcon,
                        size: isCompact ? 14 : 16,
                        color: bottomIconColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bottomLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isCompact ? 12 : 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
