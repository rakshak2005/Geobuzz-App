import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/rule_engine.dart';
import '../../../shared/models/rule_model.dart';
import '../../../shared/models/rule_trigger.dart';
import '../../../shared/models/rule_action.dart';
import '../../../shared/models/history_item.dart';
import '../../../shared/widgets/alarm_banner.dart';
import '../../../shared/widgets/command_palette_modal.dart';
import '../../rules/domain/rule_provider.dart';
import '../../rules/presentation/rule_wizard_screen.dart';
import '../../history/domain/history_provider.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/presentation/auth_screen.dart';

class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({super.key});

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _selectedIndex =
      0; // 0: Overview, 1: Automations, 2: Map canvas, 3: Activity stream, 4: Settings
  final TextEditingController _searchController = TextEditingController();
  bool _gpsStreamLive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RuleProvider>().loadRules();
      context.read<HistoryProvider>().loadHistory();
      RuleEngine.instance.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RuleWizardScreen()),
    );
  }

  void _openCommandPalette() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => CommandPaletteModal(
        onNavigate: (idx) => setState(() => _selectedIndex = idx),
        onOpenCreateWizard: _openCreateWizard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;
            if (isDesktop) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP PIXEL-PERFECT STITCH LAYOUT
  // ==========================================
  // ==========================================
  // DESKTOP PIXEL-PERFECT STITCH LAYOUT
  // ==========================================
  Widget _buildDesktopLayout() {
    final authProvider = context.watch<AuthProvider>();
    final ruleProvider = context.watch<RuleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF3F7),
      body: Stack(
        children: [
          // 1. Dynamic Luminous Atmospheric Aura Mesh Background
          _buildAtmosphericBackground(),

          // 2. Foreground Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------
              // LEFT SIDEBAR (Frosted Translucent Glass)
              // ------------------------------------
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 230,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.90),
                          Colors.white.withValues(alpha: 0.78),
                        ],
                      ),
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(4, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Logo Header (Official GeoBuzz Branding)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Geo',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1E293B),
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Buzz',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF00A2A5),
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'AUTOMATE BY LOCATION',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 2. WORKSPACE SECTION
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Text(
                            'WORKSPACE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildSidebarNavButton(0, 'Home', Icons.grid_view_rounded),
                        _buildSidebarNavButton(1, 'Automations', Icons.bolt_rounded),
                        _buildSidebarNavButton(2, 'Map', Icons.map_outlined),
                        _buildSidebarNavButton(3, 'Activity', Icons.show_chart_rounded),

                        const SizedBox(height: 28),

                        // 3. SYSTEM SECTION
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Text(
                            'SYSTEM',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildSidebarNavButton(4, 'Settings', Icons.settings_outlined),

                        const Spacer(),

                        // 4. GPS Status Switch Card (Glassmorphic)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.92),
                                      Colors.white.withValues(alpha: 0.70),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A2A5).withValues(alpha: 0.10),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _gpsStreamLive
                                            ? const Color(0xFF00A2A5)
                                            : const Color(0xFF94A3B8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _gpsStreamLive ? 'GPS active' : 'GPS paused',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          const Text(
                                            '±8m accuracy',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 28,
                                      width: 44,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Switch(
                                          value: _gpsStreamLive,
                                          activeTrackColor: const Color(0xFF00A2A5),
                                          activeThumbColor: Colors.white,
                                          inactiveThumbColor: Colors.white,
                                          inactiveTrackColor: const Color(0xFFCBD5E1),
                                          trackOutlineColor:
                                              WidgetStateProperty.all(Colors.transparent),
                                          onChanged: (val) {
                                            setState(() => _gpsStreamLive = val);
                                            if (val) {
                                              RuleEngine.instance.initialize();
                                            } else {
                                              LocationService.instance.stopPositionStream();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 5. User Profile Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    (authProvider.userName ?? 'R')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authProvider.userName ?? 'Rakshak',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Online',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded,
                                    color: Color(0xFF94A3B8), size: 19),
                                tooltip: 'Logout',
                                onPressed: () {
                                  authProvider.logout();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ------------------------------------
              // MAIN CONTENT AREA
              // ------------------------------------
              Expanded(
                child: Column(
                  children: [
                    // Top Search & Status Action Bar (Frosted Glass)
                    _buildDesktopTopBar(),
                    const AlarmBanner(),
                    Expanded(
                      child: _selectedIndex == 0
                          ? _buildSpatialOperatingCenterView(ruleProvider)
                          : _buildSecondaryTabView(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ATMOSPHERIC MESH GRADIENT BACKDROP
  // ==========================================
  Widget _buildAtmosphericBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE2EDF4),
                Color(0xFFDCE8F0),
                Color(0xFFE8EFF5),
                Color(0xFFDFEAF2),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Top-Right Vibrant Cyan / Teal Aura Orb
              Positioned(
                top: -100,
                right: -60,
                child: Container(
                  width: 650,
                  height: 650,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00C7C9).withValues(alpha: 0.45),
                        const Color(0xFF00A2A5).withValues(alpha: 0.28),
                        const Color(0xFF06B6D4).withValues(alpha: 0.12),
                        const Color(0xFF00A2A5).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
              // Center-Left Electric Indigo / Lavender Aura Orb
              Positioned(
                top: 160,
                left: -120,
                child: Container(
                  width: 580,
                  height: 580,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.38),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                        const Color(0xFF818CF8).withValues(alpha: 0.08),
                        const Color(0xFF6366F1).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
              // Center-Right Warm Sunset Amber Aura Orb
              Positioned(
                top: 320,
                right: 180,
                child: Container(
                  width: 440,
                  height: 440,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.28),
                        const Color(0xFFFB923C).withValues(alpha: 0.14),
                        const Color(0xFFF59E0B).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // Bottom-Left Mint / Emerald Radiance Orb
              Positioned(
                bottom: -80,
                left: 100,
                child: Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.38),
                        const Color(0xFF34D399).withValues(alpha: 0.18),
                        const Color(0xFF10B981).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Bottom-Right Deep Azure Orb
              Positioned(
                bottom: -100,
                right: -80,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0284C7).withValues(alpha: 0.32),
                        const Color(0xFF38BDF8).withValues(alpha: 0.14),
                        const Color(0xFF0284C7).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarNavButton(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFFE3F7F5) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFFF0FDFB),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? const Color(0xFF007A7C)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF007A7C)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------
  // TOP BAR (Search + GPS Pill + New Automation) (Frosted Glass)
  // ------------------------------------
  Widget _buildDesktopTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      color: Colors.transparent,
      child: Row(
        children: [
          // Search Bar with ⌘ K (Frosted Glass)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: InkWell(
                onTap: _openCommandPalette,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380, minWidth: 220),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Search places, automations, activity...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                        ),
                        child: const Text(
                          '⌘ K',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          // GPS Telemetry Pill (Frosted Glass)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEBF5F1).withValues(alpha: 0.90),
                      const Color(0xFFEBF5F1).withValues(alpha: 0.65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A2A5).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GPS active · ±8m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // + New Automation Button (Teal Gradient with glow)
          ElevatedButton.icon(
            onPressed: _openCreateWizard,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Create automation',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A2A5),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF00A2A5).withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------
  // MAIN SPATIAL OPERATING CENTER VIEW
  // ------------------------------------
  Widget _buildSpatialOperatingCenterView(RuleProvider ruleProvider) {
    final rules = ruleProvider.rules;
    final activeRules = rules.where((r) => r.isActive).toList();
    final activeCount = activeRules.length;
    final totalCount = rules.length;
    final todayStr = DateFormat('EEE, d MMM').format(DateTime.now());
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName ?? 'there';

    // Dynamic subtitle status message (Audit #4, #5)
    final String statusMessage = activeCount == 0
        ? (totalCount == 0
            ? 'No automations configured yet.'
            : '0 automations running · Turn on an automation below.')
        : (activeCount == 1
            ? '1 automation is active and ready.'
            : '$activeCount automations are active and ready.');

    final String activeKpiFooter = activeCount == 0
        ? 'No automations running'
        : (activeCount == 1
            ? '1 running normally'
            : 'All $activeCount running normally');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet =
            constraints.maxWidth >= 650 && constraints.maxWidth < 1050;
        final contentPadding = isMobile
            ? const EdgeInsets.fromLTRB(16, 12, 16, 24)
            : const EdgeInsets.fromLTRB(28, 0, 28, 28);

        return Stack(
          children: [
            // Ambient Atmospheric Glass Glow Orbs
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00A2A5).withValues(alpha: 0.18),
                      const Color(0xFF00A2A5).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 280,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.10),
                      const Color(0xFF6366F1).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                      const Color(0xFF10B981).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content ScrollView
            SingleChildScrollView(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'HELLO, ${userName.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Color(0xFF00A2A5),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.85),
                                        Colors.white.withValues(alpha: 0.65),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 13, color: Color(0xFF00A2A5)),
                                      const SizedBox(width: 6),
                                      Text(
                                        todayStr,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your day, automated.',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: activeCount > 0
                                ? const Color(0xFF00A2A5)
                                : const Color(0xFF64748B),
                            fontWeight:
                                activeCount > 0 ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HELLO, ${userName.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Color(0xFF00A2A5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your day, automated.',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusMessage,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: activeCount > 0
                                    ? const Color(0xFF00A2A5)
                                    : const Color(0xFF64748B),
                                fontWeight: activeCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Today, Date Pill
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.88),
                                    Colors.white.withValues(alpha: 0.65),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 15, color: Color(0xFF00A2A5)),
                                  const SizedBox(width: 8),
                                  Text(
                                    todayStr,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: isMobile ? 14 : 20),

                  // ------------------------------------
                  // ROW 1: 3 STAT CARDS (Responsive Wrap/Row)
                  // ------------------------------------
                  if (isMobile)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTopStatCard(
                                title: 'ACTIVE AUTOMATIONS',
                                value: activeCount.toString().padLeft(2, '0'),
                                footerText: activeKpiFooter,
                                footerColor: activeCount > 0
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFF94A3B8),
                                icon: Icons.bolt_rounded,
                                iconBg: const Color(0xFFE6F7F5),
                                iconColor: const Color(0xFF00A2A5),
                                isMobile: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTopStatCard(
                                title: 'SAVED PLACES',
                                value: totalCount.toString().padLeft(2, '0'),
                                footerText: '$totalCount places configured',
                                footerColor: const Color(0xFF64748B),
                                icon: Icons.bookmark_border_rounded,
                                iconBg: const Color(0xFFE6F7F5),
                                iconColor: const Color(0xFF00A2A5),
                                isMobile: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTopStatCard(
                          title: 'LOCATION STATUS',
                          value: 'Ready',
                          footerText: 'GPS active · ±8m',
                          footerColor: const Color(0xFF0D9488),
                          icon: Icons.filter_center_focus_rounded,
                          iconBg: const Color(0xFFE6F7F5),
                          iconColor: const Color(0xFF00A2A5),
                          isMobile: true,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // Card 1: ACTIVE AUTOMATIONS
                        Expanded(
                          child: _buildTopStatCard(
                            title: 'ACTIVE AUTOMATIONS',
                            value: activeCount.toString().padLeft(2, '0'),
                            footerText: activeKpiFooter,
                            footerColor: activeCount > 0
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF94A3B8),
                            icon: Icons.bolt_rounded,
                            iconBg: const Color(0xFFE6F7F5),
                            iconColor: const Color(0xFF00A2A5),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Card 2: SAVED PLACES
                        Expanded(
                          child: _buildTopStatCard(
                            title: 'SAVED PLACES',
                            value: totalCount.toString().padLeft(2, '0'),
                            footerText: '$totalCount places configured',
                            footerColor: const Color(0xFF64748B),
                            icon: Icons.bookmark_border_rounded,
                            iconBg: const Color(0xFFE6F7F5),
                            iconColor: const Color(0xFF00A2A5),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Card 3: LOCATION STATUS
                        Expanded(
                          child: _buildTopStatCard(
                            title: 'LOCATION STATUS',
                            value: 'Ready',
                            footerText: 'GPS active · ±8m',
                            footerColor: const Color(0xFF0D9488),
                            icon: Icons.filter_center_focus_rounded,
                            iconBg: const Color(0xFFE6F7F5),
                            iconColor: const Color(0xFF00A2A5),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: isMobile ? 14 : 20),

                  // ------------------------------------
                  // ROW 2: RADAR CANVAS + UP NEXT PANEL
                  // ------------------------------------
                  if (isMobile || isTablet)
                    Column(
                      children: [
                        _buildLiveGeofenceRadarCard(isMobile: isMobile),
                        const SizedBox(height: 14),
                        _buildUpNextPanelCard(rules, isMobile: isMobile),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: LIVE LOCATION (Flex 6)
                        Expanded(
                          flex: 6,
                          child: _buildLiveGeofenceRadarCard(),
                        ),
                        const SizedBox(width: 20),

                        // Right: UP NEXT (Flex 4)
                        Expanded(
                          flex: 4,
                          child: _buildUpNextPanelCard(rules),
                        ),
                      ],
                    ),
                  SizedBox(height: isMobile ? 14 : 20),

                  // ------------------------------------
                  // ROW 3: SAVED PLACES + RECENT ACTIVITY
                  // ------------------------------------
                  if (isMobile || isTablet)
                    Column(
                      children: [
                        _buildSavedPlacesBottomCard(rules, isMobile: isMobile),
                        const SizedBox(height: 14),
                        _buildRecentActivityBottomCard(isMobile: isMobile),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: SAVED PLACES (Flex 6)
                        Expanded(
                          flex: 6,
                          child: _buildSavedPlacesBottomCard(rules),
                        ),
                        const SizedBox(width: 20),

                        // Right: RECENT ACTIVITY (Flex 4)
                        Expanded(
                          flex: 4,
                          child: _buildRecentActivityBottomCard(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // REUSABLE GLASSMORPHIC CONTAINER
  // ==========================================
  Widget _buildGlassmorphicContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? height,
    double? width,
    double borderRadius = 20,
    List<Color>? gradientColors,
    Color? borderColor,
    bool glow = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ?? [
                Colors.white.withValues(alpha: 0.82),
                Colors.white.withValues(alpha: 0.52),
                Colors.white.withValues(alpha: 0.38),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.95),
              width: 1.5,
            ),
            boxShadow: [
              // Ambient soft diffuse glow
              BoxShadow(
                color: (glow
                        ? const Color(0xFF00A2A5)
                        : const Color(0xFF0F172A))
                    .withValues(alpha: glow ? 0.12 : 0.06),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              // Crisp edge depth shadow
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ==========================================
  // TOP STAT CARD WIDGET (Glassmorphism)
  // ==========================================
  Widget _buildTopStatCard({
    required String title,
    required String value,
    required String footerText,
    required Color footerColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool isMobile = false,
  }) {
    return _buildGlassmorphicContainer(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      borderRadius: 18,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 9.5 : 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isMobile ? 0.6 : 1.0,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: isMobile ? 30 : 34,
                height: isMobile ? 30 : 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(alpha: 0.18),
                      iconColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: isMobile ? 16 : 18),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 26 : 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            footerText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: footerColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RADAR CANVAS WIDGET (Live Location)
  // ==========================================
  Widget _buildLiveGeofenceRadarCard(
      {List<RuleModel>? rules, bool isMobile = false}) {
    final activeRules = rules ?? context.watch<RuleProvider>().rules;
    return LiveGeofenceRadarCard(
      rules: activeRules,
      onOpenMapCanvas: () => setState(() => _selectedIndex = 2),
      isMobile: isMobile,
    );
  }

  // ==========================================
  // UP NEXT PANEL CARD (Glassmorphism)
  // ==========================================
  Widget _buildUpNextPanelCard(List<RuleModel> rules,
      {bool isMobile = false}) {
    final activeRules = rules.where((r) => r.isActive).toList();

    return _buildGlassmorphicContainer(
      height: isMobile ? null : 340,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + More Options button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFF00A2A5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeRules.isEmpty
                        ? 'No active automations'
                        : '${activeRules.length} ${activeRules.length == 1 ? "automation ready" : "automations ready"}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00A2A5).withValues(alpha: 0.16),
                        const Color(0xFF00A2A5).withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00A2A5).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFF007A7C), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Automation List or Empty State
          if (activeRules.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8)),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.power_settings_new_rounded,
                        color: Color(0xFF94A3B8), size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'No automations currently running',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable an automation below or create a new one to let GeoBuzz act automatically.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildUpNextItem(
              title: activeRules[0].name,
              subtitle:
                  'Arrive within ${activeRules[0].radius.toInt()} m of ${activeRules[0].location.name} → ${_formatActionHuman(activeRules[0].action)}',
              icon: _getActionIcon(activeRules[0].action.type),
              accentColor:
                  _getActionAccentColor(activeRules[0].action.type),
            ),
            if (activeRules.length > 1) ...[
              const SizedBox(height: 10),
              _buildUpNextItem(
                title: activeRules[1].name,
                subtitle:
                    '${activeRules[1].trigger.type.displayName} within ${activeRules[1].radius.toInt()} m of ${activeRules[1].location.name} → ${_formatActionHuman(activeRules[1].action)}',
                icon: _getActionIcon(activeRules[1].action.type),
                accentColor:
                    _getActionAccentColor(activeRules[1].action.type),
              ),
            ],
          ],

          if (isMobile)
            const SizedBox(height: 16)
          else
            const Spacer(),

          // + Create automation CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openCreateWizard,
              icon:
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Create automation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A2A5),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor:
                    const Color(0xFF00A2A5).withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionAccentColor(ActionType type) {
    switch (type) {
      case ActionType.alarm:
        return const Color(0xFFF59E0B);
      case ActionType.soundProfile:
        return const Color(0xFF8B5CF6);
      case ActionType.wifi:
        return const Color(0xFF3B82F6);
      case ActionType.bluetooth:
        return const Color(0xFF0284C7);
      case ActionType.reminder:
        return const Color(0xFF10B981);
    }
  }

  IconData _getActionIcon(ActionType type) {
    switch (type) {
      case ActionType.alarm:
        return Icons.alarm_rounded;
      case ActionType.soundProfile:
        return Icons.volume_off_rounded;
      case ActionType.wifi:
        return Icons.wifi_rounded;
      case ActionType.bluetooth:
        return Icons.bluetooth_rounded;
      case ActionType.reminder:
        return Icons.notifications_active_rounded;
    }
  }

  String _formatActionHuman(RuleAction action) {
    switch (action.type) {
      case ActionType.alarm:
        return 'Ring alarm for ${action.alarmDurationSeconds} sec';
      case ActionType.soundProfile:
        return 'Switch to ${action.soundProfileMode ?? "Silent"}';
      case ActionType.wifi:
        return 'Toggle Wi-Fi';
      case ActionType.bluetooth:
        return 'Toggle Bluetooth';
      case ActionType.reminder:
        return action.reminderTitle?.isNotEmpty == true
            ? 'Notify "${action.reminderTitle}"'
            : 'Show reminder';
    }
  }

  Widget _buildUpNextItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.18),
                  accentColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accentColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F7F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007A7C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM ROW: SAVED PLACES CARD (Glassmorphism)
  // ==========================================
  Widget _buildSavedPlacesBottomCard(List<RuleModel> rules,
      {bool isMobile = false}) {
    return _buildGlassmorphicContainer(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'SAVED PLACES',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your saved places',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 1),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00A2A5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Card 1: Home (Mint glass background)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFE3F7F5).withValues(alpha: 0.8),
                        const Color(0xFFE3F7F5).withValues(alpha: 0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home_outlined,
                            color: Color(0xFF00A2A5), size: 18),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        rules.isNotEmpty ? rules[0].location.name : 'Home',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rules.isNotEmpty
                            ? '${rules[0].radius.toInt()} m radius'
                            : '100 m radius',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Card 2: Studio / Office (Slate glass background)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF1F5F7).withValues(alpha: 0.85),
                        const Color(0xFFF1F5F7).withValues(alpha: 0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.work_outline_rounded,
                            color: Color(0xFF00A2A5), size: 18),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        rules.length > 1 ? rules[1].location.name : 'Office',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rules.length > 1
                            ? '${rules[1].radius.toInt()} m radius'
                            : '100 m radius',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM ROW: RECENT ACTIVITY CARD (Glassmorphism)
  // ==========================================
  Widget _buildRecentActivityBottomCard({bool isMobile = false}) {
    final historyProvider = context.watch<HistoryProvider>();
    final history = historyProvider.history;

    return _buildGlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Activity timeline',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 3),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00A2A5).withValues(alpha: 0.16),
                        const Color(0xFF00A2A5).withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00A2A5).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(Icons.north_east_rounded,
                      color: Color(0xFF007A7C), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Log item 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(Icons.volume_off_rounded,
                    color: Color(0xFF8B5CF6), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.isNotEmpty
                          ? history[0].ruleName
                          : 'Office Silent Mode',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      history.isNotEmpty
                          ? 'Arrived at ${history[0].locationName} · ${history[0].message}'
                          : 'Arrived at Office · Silent mode enabled',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                history.isNotEmpty
                    ? DateFormat('hh:mm a').format(history[0].timestamp)
                    : '9:12 AM',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Log item 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(Icons.alarm_rounded,
                    color: Color(0xFFF59E0B), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.length > 1
                          ? history[1].ruleName
                          : 'Bus Stop Alert',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      history.length > 1
                          ? 'Approaching ${history[1].locationName} · ${history[1].message}'
                          : 'Approaching Majestic Bus Stop · Alarm triggered',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                history.length > 1
                    ? DateFormat('hh:mm a').format(history[1].timestamp)
                    : 'Yesterday',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECONDARY TABS (Automations, Map, Activity, Settings)
  // ==========================================
  String _automationFilter = 'All';
  final TextEditingController _automationsSearchController =
      TextEditingController();

  Widget _buildSecondaryTabView() {
    final ruleProvider = context.watch<RuleProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    switch (_selectedIndex) {
      case 1: // Automations (Audit #25, #26, #39)
        final query = _automationsSearchController.text.trim().toLowerCase();
        final filteredRules = ruleProvider.rules.where((r) {
          final matchesSearch = query.isEmpty ||
              r.name.toLowerCase().contains(query) ||
              r.location.name.toLowerCase().contains(query);
          if (!matchesSearch) return false;

          switch (_automationFilter) {
            case 'Active':
              return r.isActive;
            case 'Paused':
              return !r.isActive;
            case 'Alarm':
              return r.action.type == ActionType.alarm;
            case 'Sound':
              return r.action.type == ActionType.soundProfile;
            case 'Wi-Fi':
              return r.action.type == ActionType.wifi;
            case 'Reminder':
              return r.action.type == ActionType.reminder;
            default:
              return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Automations',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(
                          '${ruleProvider.activeCount} active · ${ruleProvider.rules.length} total',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreateWizard,
                    icon: const Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Create automation',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A2A5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search & Filter Toolbar (Audit #25)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _automationsSearchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search automations or places...',
                          hintStyle:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 18, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Active',
                    'Paused',
                    'Alarm',
                    'Sound',
                    'Wi-Fi',
                    'Reminder'
                  ].map((filter) {
                    final isSelected = _automationFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00A2A5),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF00A2A5)
                                : const Color(0xFFE2E8F0)),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setState(() => _automationFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Automation Templates Section (Audit #39)
              if (ruleProvider.rules.isEmpty) ...[
                _buildAutomationTemplatesBanner(),
                const SizedBox(height: 20),
              ],

              if (filteredRules.isEmpty)
                _buildEmptyRulesPlaceholder()
              else
                ...filteredRules.map((rule) => _buildCleanRuleCard(rule)),
            ],
          ),
        );

      case 2: // Map
        return Container(
          margin: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildLiveGeofenceRadarCard(),
        );

      case 3: // Activity
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const Text('Activity History',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            if (historyProvider.history.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No events recorded yet',
                          style: TextStyle(color: Color(0xFF64748B)))))
            else
              ...historyProvider.history
                  .map((item) => _buildCleanHistoryCard(item)),
          ],
        );

      case 4: // Settings
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const Text('Settings',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildCleanSettingsTile('High Precision Location',
                'Continuous ±8m accuracy evaluation', Icons.gps_fixed_rounded),
            _buildCleanSettingsTile(
                'Background Service',
                'Runs reliably in background without interruption',
                Icons.battery_charging_full_rounded),
            _buildCleanSettingsTile(
                'Sound & Do Not Disturb Access',
                'Allows sound mode switching',
                Icons.do_not_disturb_on_outlined),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAutomationTemplatesBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCECEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A2A5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Try ready-made automations',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Quickly set up popular routines with one tap.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTemplateChip('Work Silence', 'Office · Arrive → Silent',
                  Icons.volume_off_rounded, const Color(0xFF8B5CF6)),
              _buildTemplateChip('Bus Stop Alert', 'Transit · Approach → Alarm',
                  Icons.alarm_rounded, const Color(0xFFF59E0B)),
              _buildTemplateChip('Home Wi-Fi', 'Home · Arrive → Wi-Fi',
                  Icons.wifi_rounded, const Color(0xFF3B82F6)),
              _buildTemplateChip('Grocery Note', 'Market · Arrive → Note',
                  Icons.notifications_active_rounded, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(
      String title, String subtitle, IconData icon, Color accent) {
    return InkWell(
      onTap: _openCreateWizard,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1EBEA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF0F172A))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanRuleCard(RuleModel rule) {
    final accent = _getActionAccentColor(rule.action.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(_getActionIcon(rule.action.type), color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rule.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rule.isActive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rule.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: rule.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'When I ${rule.trigger.type.displayName.toLowerCase()} within ${rule.radius.toInt()} m of ${rule.location.name} → ${_formatActionHuman(rule.action)}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 28,
            width: 44,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: rule.isActive,
                activeTrackColor: const Color(0xFF00A2A5),
                activeThumbColor: Colors.white,
                onChanged: (val) =>
                    context.read<RuleProvider>().toggleRule(rule.id, val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.ruleName} (${item.triggerType})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A))),
                Text(item.message,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(DateFormat('hh:mm a').format(item.timestamp),
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildCleanSettingsTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00A2A5), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyRulesPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_location_alt_outlined,
              size: 40, color: Color(0xFF00A2A5)),
          const SizedBox(height: 12),
          const Text('No automations found',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
              'Create an automation to take action when you arrive, leave, or approach a place.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openCreateWizard,
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: const Text('Create automation',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A2A5)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOBILE / TABLET FALLBACK
  // ==========================================
  Widget _buildMobileLayout() {
    final ruleProvider = context.watch<RuleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 16,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Geo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Buzz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00A2A5),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // GPS live status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'GPS active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Color(0xFF64748B), size: 22),
            onPressed: _openCommandPalette,
            tooltip: 'Search (⌘K)',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildSpatialOperatingCenterView(ruleProvider)
          : _buildSecondaryTabView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        selectedItemColor: const Color(0xFF00A2A5),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bolt_rounded), label: 'Automations'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded), label: 'Activity'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateWizard,
        backgroundColor: const Color(0xFF00A2A5),
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Create automation',
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }
}

// ==========================================
// DEDICATED LIVE GEOFENCE RADAR CARD WIDGET
// ==========================================
class LiveGeofenceRadarCard extends StatefulWidget {
  final List<RuleModel> rules;
  final VoidCallback onOpenMapCanvas;
  final bool isMobile;

  const LiveGeofenceRadarCard({
    super.key,
    required this.rules,
    required this.onOpenMapCanvas,
    this.isMobile = false,
  });

  @override
  State<LiveGeofenceRadarCard> createState() => _LiveGeofenceRadarCardState();
}

class _LiveGeofenceRadarCardState extends State<LiveGeofenceRadarCard> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight = widget.isMobile ? 260 : 340;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ValueListenableBuilder<Position?>(
          valueListenable: LocationService.instance.currentPosition,
          builder: (context, pos, _) {
            final LatLng userLoc = pos != null
                ? LatLng(pos.latitude, pos.longitude)
                : const LatLng(12.9716, 77.5946); // Default Bengaluru coords

            final activeGeofences =
                widget.rules.where((r) => r.isActive).toList();

            return Stack(
              children: [
                // 1. Live Interactive FlutterMap
                ExcludeSemantics(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLoc,
                      initialZoom: 14.5,
                      minZoom: 4,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // OpenStreetMap CartoDB Positron / OSM Light Tiles
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.geobuzz.geobuzz',
                      ),

                      // Active Geofence Circles
                      CircleLayer(
                        circles: [
                          // User GPS accuracy circle
                          CircleMarker(
                            point: userLoc,
                            radius: 50,
                            useRadiusInMeter: true,
                            color:
                                const Color(0xFF00A2A5).withValues(alpha: 0.18),
                            borderColor: const Color(0xFF00A2A5),
                            borderStrokeWidth: 1.5,
                          ),
                          // Geofence rules circles
                          ...activeGeofences.map((rule) {
                            return CircleMarker(
                              point: LatLng(rule.location.latitude,
                                  rule.location.longitude),
                              radius: rule.radius,
                              useRadiusInMeter: true,
                              color: const Color(0xFF00A2A5)
                                  .withValues(alpha: 0.12),
                              borderColor: const Color(0xFF00A2A5)
                                  .withValues(alpha: 0.6),
                              borderStrokeWidth: 1.5,
                            );
                          }),
                        ],
                      ),

                      // Markers
                      MarkerLayer(
                        markers: [
                          // User Current Location Pulse Marker
                          Marker(
                            point: userLoc,
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF00A2A5)
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00A2A5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00A2A5)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Active Geofences Pin Markers
                          ...activeGeofences.map((rule) {
                            return Marker(
                              point: LatLng(rule.location.latitude,
                                  rule.location.longitude),
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF00A2A5), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.place_rounded,
                                  color: Color(0xFF00A2A5),
                                  size: 18,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Top-Left Overlay Pill: Live location · Bengaluru
                Positioned(
                  top: widget.isMobile ? 10 : 14,
                  left: widget.isMobile ? 10 : 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 8 : 12,
                        vertical: widget.isMobile ? 5 : 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: widget.isMobile ? 6 : 8,
                          height: widget.isMobile ? 6 : 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: widget.isMobile ? 5 : 7),
                        Text(
                          'Live location',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 9.5 : 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· Bengaluru',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 9.5 : 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Top-Right: Fullscreen & Controls
                Positioned(
                  top: widget.isMobile ? 10 : 14,
                  right: widget.isMobile ? 10 : 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recenter Button
                      InkWell(
                        onTap: () {
                          _mapController.move(userLoc, 15.0);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(widget.isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            Icons.my_location_rounded,
                            size: widget.isMobile ? 14 : 16,
                            color: const Color(0xFF00A2A5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Expand to Map Canvas
                      InkWell(
                        onTap: widget.onOpenMapCanvas,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(widget.isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            Icons.fullscreen_rounded,
                            size: widget.isMobile ? 14 : 16,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Bottom-Left: You are here status pill
                Positioned(
                  bottom: widget.isMobile ? 10 : 14,
                  left: widget.isMobile ? 10 : 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 8 : 10,
                        vertical: widget.isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          color: const Color(0xFF00A2A5),
                          size: widget.isMobile ? 11 : 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'You are here · ±8m accuracy',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 9.5 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Bottom-Right: Active Places Counter
                Positioned(
                  bottom: widget.isMobile ? 10 : 14,
                  right: widget.isMobile ? 10 : 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 8 : 10,
                        vertical: widget.isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A2A5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF00A2A5).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_outlined,
                            color: Colors.white,
                            size: widget.isMobile ? 12 : 14),
                        const SizedBox(width: 4),
                        Text(
                          '${activeGeofences.length} ${activeGeofences.length == 1 ? "active place" : "active places"}',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 10 : 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
