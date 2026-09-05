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
  int _selectedIndex = 0; // 0: Overview, 1: Automations, 2: Map canvas, 3: Activity stream, 4: Settings
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
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openCommandPalette,
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
  Widget _buildDesktopLayout() {
    final authProvider = context.watch<AuthProvider>();
    final ruleProvider = context.watch<RuleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8), // Neutral light background canvas
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------
          // LEFT SIDEBAR (Width: 230)
          // ------------------------------------
          Container(
            width: 230,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE5EBEF), width: 1),
              ),
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

                // 4. GPS Status Switch Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00A2A5), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A2A5).withValues(alpha: 0.08),
                          blurRadius: 10,
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
                            color: _gpsStreamLive ? const Color(0xFF00A2A5) : const Color(0xFF94A3B8),
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
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: _gpsStreamLive,
                            activeTrackColor: const Color(0xFF00A2A5),
                            activeThumbColor: Colors.white,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
                      ],
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            (authProvider.userName ?? 'R').substring(0, 1).toUpperCase(),
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
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 19),
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

          // ------------------------------------
          // MAIN CONTENT AREA
          // ------------------------------------
          Expanded(
            child: Column(
              children: [
                // Top Search & Status Action Bar
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
                  color: isSelected ? const Color(0xFF007A7C) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF007A7C) : const Color(0xFF475569),
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
  // TOP BAR (Search + GPS Pill + New Automation)
  // ------------------------------------
  Widget _buildDesktopTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      color: Colors.transparent,
      child: Row(
        children: [
          // Search Bar with ⌘ K
          InkWell(
            onTap: _openCommandPalette,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360, minWidth: 200),
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF0F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDEE5EA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
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
          const Spacer(),

          // GPS Telemetry Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5F1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD1EBE1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
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
          const SizedBox(width: 14),

          // + New Automation Button (Teal filled)
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
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final activeCount = ruleProvider.activeCount;
    final totalCount = rules.length;
    final todayStr = DateFormat('EEE, d MMM').format(DateTime.now());
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName ?? 'there';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1050;
        final contentPadding = isMobile
            ? const EdgeInsets.fromLTRB(16, 12, 16, 24)
            : const EdgeInsets.fromLTRB(28, 0, 28, 28);

        return SingleChildScrollView(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF00A2A5)),
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
                      '$activeCount automations are active and ready.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
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
                          '$activeCount automations are active and ready.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    // Today, Date Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF00A2A5)),
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
                            footerText: 'All running normally',
                            footerColor: const Color(0xFF0D9488),
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
                            value: totalCount > 0 ? totalCount.toString().padLeft(2, '0') : '03',
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
                      title: 'AUTOMATION STATUS',
                      value: 'Active',
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
                        footerText: 'All running normally',
                        footerColor: const Color(0xFF0D9488),
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
                        value: totalCount > 0 ? totalCount.toString().padLeft(2, '0') : '03',
                        footerText: '$totalCount places configured',
                        footerColor: const Color(0xFF64748B),
                        icon: Icons.bookmark_border_rounded,
                        iconBg: const Color(0xFFE6F7F5),
                        iconColor: const Color(0xFF00A2A5),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Card 3: GPS ACCURACY
                    Expanded(
                      child: _buildTopStatCard(
                        title: 'SYSTEM STATUS',
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
              // ROW 2: RADAR CANVAS + ACTIVE AUTOMATIONS
              // ------------------------------------
              if (isMobile || isTablet)
                Column(
                  children: [
                    _buildLiveGeofenceRadarCard(isMobile: isMobile),
                    const SizedBox(height: 14),
                    _buildAutomationPulseCard(rules, isMobile: isMobile),
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

                    // Right: ACTIVE AUTOMATIONS (Flex 4)
                    Expanded(
                      flex: 4,
                      child: _buildAutomationPulseCard(rules),
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
        );
      },
    );
  }

  // ==========================================
  // TOP STAT CARD WIDGET
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
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
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
                width: isMobile ? 28 : 32,
                height: isMobile ? 28 : 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
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
  Widget _buildLiveGeofenceRadarCard({List<RuleModel>? rules, bool isMobile = false}) {
    final activeRules = rules ?? context.watch<RuleProvider>().rules;
    return LiveGeofenceRadarCard(
      rules: activeRules,
      onOpenMapCanvas: () => setState(() => _selectedIndex = 2),
      isMobile: isMobile,
    );
  }

  // ==========================================
  // ACTIVE AUTOMATIONS CARD
  // ==========================================
  Widget _buildAutomationPulseCard(List<RuleModel> rules, {bool isMobile = false}) {
    return Container(
      height: isMobile ? null : 340,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + More Options button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ACTIVE AUTOMATIONS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ready to run',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6F3F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_horiz_rounded, color: Color(0xFF007A7C), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Item 1
          _buildAutomationPulseItem(
            title: rules.isNotEmpty ? rules[0].name : 'Office Silence',
            subtitle: rules.isNotEmpty
                ? 'When I ${rules[0].trigger.type.displayName.toLowerCase()} within ${rules[0].radius.toInt()} m → ${_formatActionHuman(rules[0].action)}'
                : 'When I arrive within 100 m → Silent mode',
            icon: rules.isNotEmpty ? _getActionIcon(rules[0].action.type) : Icons.volume_off_rounded,
          ),
          const SizedBox(height: 10),

          // Item 2
          _buildAutomationPulseItem(
            title: rules.length > 1 ? rules[1].name : 'Bus Stop Alarm',
            subtitle: rules.length > 1
                ? 'When I ${rules[1].trigger.type.displayName.toLowerCase()} within ${rules[1].radius.toInt()} m → ${_formatActionHuman(rules[1].action)}'
                : 'When I approach within 200 m → Ring alarm',
            icon: rules.length > 1 ? _getActionIcon(rules[1].action.type) : Icons.alarm_rounded,
          ),

          SizedBox(height: isMobile ? 14 : 20),

          // + Create automation CTA (Full-width Teal Button)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openCreateWizard,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
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
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
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
        return 'Ring alarm (${action.alarmDurationSeconds}s)';
      case ActionType.soundProfile:
        return 'Switch to ${action.soundProfileMode ?? "Silent"}';
      case ActionType.wifi:
        return 'Toggle WiFi';
      case ActionType.bluetooth:
        return 'Toggle Bluetooth';
      case ActionType.reminder:
        return action.reminderTitle?.isNotEmpty == true
            ? 'Notify "${action.reminderTitle}"'
            : 'Show reminder';
    }
  }

  Widget _buildAutomationPulseItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F7F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00A2A5), size: 17),
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
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM ROW: SAVED PLACES CARD
  // ==========================================
  Widget _buildSavedPlacesBottomCard(List<RuleModel> rules, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
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
              // Card 1: Home (Mint background)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F7F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home_outlined, color: Color(0xFF00A2A5), size: 20),
                      const SizedBox(height: 16),
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
                        rules.isNotEmpty ? '${rules[0].radius.toInt()} m radius' : '100 m radius',
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

              // Card 2: Studio / Office (Slate background)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.work_outline_rounded, color: Color(0xFF00A2A5), size: 20),
                      const SizedBox(height: 16),
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
                        rules.length > 1 ? '${rules[1].radius.toInt()} m radius' : '100 m radius',
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
  // BOTTOM ROW: RECENT ACTIVITY CARD
  // ==========================================
  Widget _buildRecentActivityBottomCard({bool isMobile = false}) {
    final historyProvider = context.watch<HistoryProvider>();
    final history = historyProvider.history;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.north_east_rounded, color: Color(0xFF007A7C), size: 18),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFF00A2A5), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.isNotEmpty ? history[0].ruleName : 'Silent mode triggered at Office',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      history.isNotEmpty
                          ? DateFormat('hh:mm a').format(history[0].timestamp)
                          : 'Today • 9:12 AM',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Log item 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.length > 1 ? history[1].ruleName : 'Arrived at destination',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      history.length > 1
                          ? DateFormat('hh:mm a').format(history[1].timestamp)
                          : 'Yesterday • 6:26 PM',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
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
  // SECONDARY TABS (Automations, Map, Activity, Settings)
  // ==========================================
  Widget _buildSecondaryTabView() {
    final ruleProvider = context.watch<RuleProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    switch (_selectedIndex) {
      case 1: // Automations
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Automations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ElevatedButton.icon(
                    onPressed: _openCreateWizard,
                    icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    label: const Text('Create automation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2A5)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (ruleProvider.rules.isEmpty)
                _buildEmptyRulesPlaceholder()
              else
                ...ruleProvider.rules.map((rule) => _buildCleanRuleCard(rule)),
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
            const Text('Activity History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            if (historyProvider.history.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No events recorded yet', style: TextStyle(color: Color(0xFF64748B)))))
            else
              ...historyProvider.history.map((item) => _buildCleanHistoryCard(item)),
          ],
        );

      case 4: // Settings
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildCleanSettingsTile('High Precision Location', 'Continuous ±8m accuracy evaluation', Icons.gps_fixed_rounded),
            _buildCleanSettingsTile('Background Service', 'Runs reliably in background without interruption', Icons.battery_charging_full_rounded),
            _buildCleanSettingsTile('Sound & Do Not Disturb Access', 'Allows sound mode switching', Icons.do_not_disturb_on_outlined),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCleanRuleCard(RuleModel rule) {
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F7F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getActionIcon(rule.action.type), color: const Color(0xFF00A2A5), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('When I ${rule.trigger.type.displayName.toLowerCase()} within ${rule.radius.toInt()} m of ${rule.location.name} → ${_formatActionHuman(rule.action)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: rule.isActive,
              activeTrackColor: const Color(0xFF00A2A5),
              activeThumbColor: Colors.white,
              onChanged: (val) => context.read<RuleProvider>().toggleRule(rule.id, val),
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
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.ruleName} (${item.triggerType})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text(item.message, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(DateFormat('hh:mm a').format(item.timestamp), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
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
          const Icon(Icons.add_location_alt_outlined, size: 40, color: Color(0xFF00A2A5)),
          const SizedBox(height: 12),
          const Text('No automations created yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Create your first automation to take action when you arrive, leave, or approach a place.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openCreateWizard,
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: const Text('Create automation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2A5)),
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
            icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Automations'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Activity'),
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

            final activeGeofences = widget.rules.where((r) => r.isActive).toList();

            return Stack(
              children: [
                // 1. Live Interactive FlutterMap
                FlutterMap(
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          color: const Color(0xFF00A2A5).withValues(alpha: 0.18),
                          borderColor: const Color(0xFF00A2A5),
                          borderStrokeWidth: 1.5,
                        ),
                        // Geofence rules circles
                        ...activeGeofences.map((rule) {
                          return CircleMarker(
                            point: LatLng(rule.location.latitude, rule.location.longitude),
                            radius: rule.radius,
                            useRadiusInMeter: true,
                            color: const Color(0xFF00A2A5).withValues(alpha: 0.12),
                            borderColor: const Color(0xFF00A2A5).withValues(alpha: 0.6),
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
                                    color: const Color(0xFF00A2A5).withValues(alpha: 0.25),
                                  ),
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A2A5),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00A2A5).withValues(alpha: 0.6),
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
                            point: LatLng(rule.location.latitude, rule.location.longitude),
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00A2A5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
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

                // 2. Top-Left Overlay Pill: Live location · Bengaluru
                Positioned(
                  top: widget.isMobile ? 10 : 14,
                  left: widget.isMobile ? 10 : 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 12, vertical: widget.isMobile ? 5 : 7),
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
                    padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 10, vertical: widget.isMobile ? 4 : 6),
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
                    padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 10, vertical: widget.isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A2A5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A2A5).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_outlined, color: Colors.white, size: widget.isMobile ? 12 : 14),
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
