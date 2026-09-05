import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/device_channel_service.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../home/presentation/responsive_scaffold.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PermissionOnboardingScreen({super.key, this.onComplete});

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
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
      final dnd = await DeviceChannelService.isNotificationPolicyAccessGranted();

      if (mounted) {
        setState(() {
          _locationGranted = loc == LocationPermission.always || loc == LocationPermission.whileInUse;
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

  @override
  Widget build(BuildContext context) {
    final int readyCount = (_locationGranted ? 1 : 0) + (_dndGranted ? 1 : 0) + 1;
    final size = MediaQuery.of(context).size;
    final bool isComputer = size.width >= 900;
    final bool isTablet = size.width >= 600 && size.width < 900;
    final bool isCompact = size.width < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: isComputer
            ? _buildComputerLayout(readyCount, size)
            : _buildMobileOrTabletLayout(readyCount, isCompact, isTablet),
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
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Branding, Hero Text, Progress, and CTA
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
                      const SizedBox(height: 28),
                      _buildStatusChip(),
                      const SizedBox(height: 18),
                      const Text(
                        'Your phone is ready\nto work smarter.',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          height: 1.15,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GeoBuzz has the access it needs to quietly keep your routines in sync—wherever your day takes you.',
                        style: TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPrimaryCta(),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Your permissions stay securely on your device',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
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

              // Right Column: Cards Stack
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSetupCard(
                      iconBgColor: const Color(0xFFE0F7F6),
                      iconColor: const Color(0xFF008D96),
                      icon: Icons.location_on_outlined,
                      title: 'Precise Location',
                      desc: 'Detects arrivals and departures from your automation zones.',
                      bottomIcon: Icons.shield_outlined,
                      bottomIconColor: const Color(0xFF10B981),
                      bottomLabel: 'Always allowed',
                      isReady: _locationGranted,
                      onTap: _requestLocationPermission,
                    ),
                    const SizedBox(height: 18),
                    _buildSetupCard(
                      iconBgColor: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF334155),
                      icon: Icons.notifications_off_outlined,
                      title: 'Do Not Disturb',
                      optionalBadge: true,
                      desc: 'Silences or vibrates your phone when you arrive at focus zones.',
                      bottomIcon: Icons.event_available_outlined,
                      bottomIconColor: const Color(0xFF008D96),
                      bottomLabel: 'Policy access granted',
                      isReady: _dndGranted,
                      onTap: _requestDndPermission,
                    ),
                    const SizedBox(height: 18),
                    _buildSetupCard(
                      iconBgColor: const Color(0xFF00A3A6),
                      iconColor: Colors.white,
                      icon: Icons.bolt_rounded,
                      title: 'Background Automation',
                      desc: 'Keeps geofence rules reliable while your screen is locked.',
                      bottomIcon: Icons.show_chart_rounded,
                      bottomIconColor: const Color(0xFF008D96),
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
  Widget _buildMobileOrTabletLayout(int readyCount, bool isCompact, bool isTablet) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 600 : 480,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : (isTablet ? 32.0 : 20.0),
            vertical: isTablet ? 32.0 : 18.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact: isCompact),
              SizedBox(height: isTablet ? 30 : 24),
              _buildProgressSection(readyCount, isCompact: isCompact),
              SizedBox(height: isTablet ? 28 : 22),
              _buildStatusChip(),
              const SizedBox(height: 14),
              Text(
                'Your phone is ready\nto work smarter.',
                style: TextStyle(
                  fontSize: isCompact ? 24 : (isTablet ? 32 : 28),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  height: 1.15,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'GeoBuzz has the access it needs to quietly keep your routines in sync—wherever your day takes you.',
                style: TextStyle(
                  fontSize: isCompact ? 13.5 : 14.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              SizedBox(height: isTablet ? 26 : 20),

              // Setup Cards
              _buildSetupCard(
                iconBgColor: const Color(0xFFE0F7F6),
                iconColor: const Color(0xFF008D96),
                icon: Icons.location_on_outlined,
                title: 'Precise Location',
                desc: 'Detects arrivals and departures from your automation zones.',
                bottomIcon: Icons.shield_outlined,
                bottomIconColor: const Color(0xFF10B981),
                bottomLabel: 'Always allowed',
                isReady: _locationGranted,
                onTap: _requestLocationPermission,
                isCompact: isCompact,
              ),
              const SizedBox(height: 14),
              _buildSetupCard(
                iconBgColor: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF334155),
                icon: Icons.notifications_off_outlined,
                title: 'Do Not Disturb',
                optionalBadge: true,
                desc: 'Silences or vibrates your phone when you arrive at focus zones.',
                bottomIcon: Icons.event_available_outlined,
                bottomIconColor: const Color(0xFF008D96),
                bottomLabel: 'Policy access granted',
                isReady: _dndGranted,
                onTap: _requestDndPermission,
                isCompact: isCompact,
              ),
              const SizedBox(height: 14),
              _buildSetupCard(
                iconBgColor: const Color(0xFF00A3A6),
                iconColor: Colors.white,
                icon: Icons.bolt_rounded,
                title: 'Background Automation',
                desc: 'Keeps geofence rules reliable while your screen is locked.',
                bottomIcon: Icons.show_chart_rounded,
                bottomIconColor: const Color(0xFF008D96),
                bottomLabel: 'Running in the background',
                isReady: true,
                isHighlighted: true,
                isCompact: isCompact,
              ),

              SizedBox(height: isTablet ? 32 : 26),
              const Center(
                child: Text(
                  'Your permissions stay on your device',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              _buildPrimaryCta(),
              SizedBox(height: isTablet ? 24 : 16),
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
        Image.asset(
          'assets/images/logo.png',
          width: isCompact ? 40 : 46,
          height: isCompact ? 40 : 46,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: isCompact ? 40 : 46,
            height: isCompact ? 40 : 46,
            decoration: BoxDecoration(
              color: const Color(0xFF00A3A6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: isCompact ? 22 : 26,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GEOBUZZ',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Automation that moves with you',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: isCompact ? 36 : 40,
          height: isCompact ? 36 : 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.help_outline_rounded,
            size: isCompact ? 18 : 20,
            color: const Color(0xFF475569),
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
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$readyCount of 3 ready',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF008D96),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFFE2E8F0),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: readyCount / 3.0,
              child: Container(
                color: const Color(0xFF00A3A6),
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
        color: const Color(0xFFE6F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 3,
              backgroundColor: Color(0xFF10B981),
            ),
            SizedBox(width: 8),
            Text(
              'Everything looks good',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
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
          backgroundColor: const Color(0xFF00A3A6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your dashboard',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
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
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF00A3A6) : const Color(0xFFE2E8F0),
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
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
                width: isCompact ? 38 : 42,
                height: isCompact ? 38 : 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 20 : 22),
              ),
              SizedBox(width: isCompact ? 10 : 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 14.5 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (optionalBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Color(0xFF64748B),
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
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFF0F766E),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(
              fontSize: isCompact ? 12.5 : 13.5,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
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
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
