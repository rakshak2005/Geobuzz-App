import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/rule_engine.dart';
import '../../../shared/models/rule_model.dart';
import '../../../shared/models/rule_trigger.dart';
import '../../../shared/models/rule_action.dart';
import '../../../shared/models/history_item.dart';
import '../../../shared/widgets/geobuzz_brand_logo.dart';
import '../../../shared/widgets/alarm_banner.dart';
import '../../../shared/widgets/status_badge.dart';
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
  int _selectedIndex = 0; // 0: Dashboard, 1: Automations, 2: Map, 3: Activity, 4: Analytics, 5: Settings
  final TextEditingController _searchController = TextEditingController();
  final MapController _radarMapController = MapController();
  final MapController _canvasMapController = MapController();
  String _automationFilter = 'ALL';
  LatLng? _currentLocation;
  double? _currentAccuracy;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RuleProvider>().loadRules();
      context.read<HistoryProvider>().loadHistory();
      RuleEngine.instance.initialize();
      _locateDevice(animateMap: true);
    });

    // Listen to real-time position updates
    LocationService.instance.currentPosition.addListener(_onPositionUpdated);
  }

  void _onPositionUpdated() {
    final pos = LocationService.instance.currentPosition.value;
    if (pos != null && mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _currentAccuracy = pos.accuracy;
      });
    }
  }

  Future<void> _locateDevice({bool animateMap = true}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      if (pos != null && mounted) {
        final newCenter = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentLocation = newCenter;
          _currentAccuracy = pos.accuracy;
          _isLocating = false;
        });

        if (animateMap) {
          try {
            _radarMapController.move(newCenter, 15.0);
          } catch (_) {}
          try {
            _canvasMapController.move(newCenter, 15.0);
          } catch (_) {}
        }
      } else {
        if (mounted) setState(() => _isLocating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    LocationService.instance.currentPosition.removeListener(_onPositionUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RuleWizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 1024;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout(isTablet: isTablet);
        }
      },
    );
  }

  // ==========================================
  // 1. DESKTOP WORKSPACE LAYOUT (Linear/Raycast inspired)
  // ==========================================
  Widget _buildDesktopLayout() {
    final authProvider = context.watch<AuthProvider>();
    final ruleProvider = context.watch<RuleProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          // Persistent Left Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(right: BorderSide(color: AppColors.borderDark, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                const Padding(
                  padding: EdgeInsets.all(AppDimensions.lg),
                  child: GeoBuzzBrandLogo(size: 34, showTagline: true),
                ),
                const Divider(color: AppColors.borderDark, height: 1),

                // Navigation Items
                const SizedBox(height: 12),
                _buildSidebarItem(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
                _buildSidebarItem(1, 'Automations', Icons.bolt_outlined, Icons.bolt_rounded, badgeCount: ruleProvider.rules.length),
                _buildSidebarItem(2, 'Map Canvas', Icons.map_outlined, Icons.map_rounded),
                _buildSidebarItem(3, 'Activity Logs', Icons.history_outlined, Icons.history_rounded),
                _buildSidebarItem(4, 'Analytics', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
                _buildSidebarItem(5, 'Settings', Icons.settings_outlined, Icons.settings_rounded),

                const Spacer(),

                // Engine Status Card in Sidebar
                _buildSidebarEngineWidget(ruleProvider.activeCount),
                const Divider(color: AppColors.borderDark, height: 1),

                // User Profile & Logout
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight.withAlpha(40),
                        child: Text(
                          (authProvider.userName ?? 'E').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.userName ?? 'Explorer',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Pro Account',
                              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.textMutedDark, size: 18),
                        tooltip: 'Sign Out',
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

          // Main Desktop Content Area
          Expanded(
            child: Column(
              children: [
                // Top Global Command Bar
                _buildDesktopTopBar(),

                // Active Alarm Banner
                const AlarmBanner(),

                // Current Tab View
                Expanded(
                  child: _buildCurrentTabView(isDesktop: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon, IconData activeIcon, {int? badgeCount}) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.surfaceLightDark.withAlpha(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.accent : AppColors.textSecondaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLightDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarEngineWidget(int activeCount) {
    return ValueListenableBuilder<bool>(
      valueListenable: LocationService.instance.isTracking,
      builder: (context, isTracking, _) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isTracking ? AppColors.success.withAlpha(80) : AppColors.borderDark,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTracking ? AppColors.success : AppColors.warning,
                  boxShadow: [
                    if (isTracking)
                      BoxShadow(
                        color: AppColors.success.withAlpha(128),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTracking ? 'Engine Active' : 'Engine Paused',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isTracking ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    Text(
                      '$activeCount active zones',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isTracking,
                activeColor: AppColors.primaryLight,
                onChanged: (val) {
                  if (val) {
                    RuleEngine.instance.initialize();
                  } else {
                    LocationService.instance.stopPositionStream();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Row(
        children: [
          // Search Box with Ctrl+K badge
          Container(
            width: 320,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMutedDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search automations, places...',
                      hintStyle: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLightDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ctrl K',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMutedDark),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Quick Action CTA Button
          ElevatedButton.icon(
            onPressed: _openCreateWizard,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Automation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. MOBILE / TABLET LAYOUT
  // ==========================================
  Widget _buildMobileLayout({required bool isTablet}) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const GeoBuzzBrandLogo(size: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
            tooltip: 'New Automation',
            onPressed: _openCreateWizard,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AlarmBanner(),
            Expanded(child: _buildCurrentTabView(isDesktop: false)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.borderDark)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex > 4 ? 4 : _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Rules'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Activity'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateWizard,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ==========================================
  // 3. TAB VIEWS ROUTER
  // ==========================================
  Widget _buildCurrentTabView({required bool isDesktop}) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView(isDesktop: isDesktop);
      case 1:
        return _buildAutomationsView(isDesktop: isDesktop);
      case 2:
        return _buildMapCanvasView(isDesktop: isDesktop);
      case 3:
        return _buildActivityView();
      case 4:
        return _buildAnalyticsView();
      case 5:
        return _buildSettingsView();
      default:
        return _buildDashboardView(isDesktop: isDesktop);
    }
  }

  // ==========================================
  // VIEW A: DASHBOARD VIEW
  // ==========================================
  Widget _buildDashboardView({required bool isDesktop}) {
    final ruleProvider = context.watch<RuleProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? AppDimensions.lg : AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Tagline
          const Text(
            'Good evening, Rakshak',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your phone knows where you are. GeoBuzz knows what to do.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // High Density KPI Cards (Section 13)
          _buildKPIMetricsRow(ruleProvider.rules.length, ruleProvider.activeCount, historyProvider.history.length),
          const SizedBox(height: 24),

          // Desktop: 2-Column Split (Live Map + Rules Stream) | Mobile: Vertical Stack
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Active Rules Stream
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Active Automations', '${ruleProvider.rules.length} Configured'),
                      const SizedBox(height: 12),
                      if (ruleProvider.rules.isEmpty)
                        _buildEmptyRulesState()
                      else
                        ...ruleProvider.rules.map((rule) => _buildModernRuleCard(rule)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Live Map & Proximity Radar
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Live Geofence Radar', 'Real-time Evaluation'),
                      const SizedBox(height: 12),
                      _buildLiveRadarMapWidget(ruleProvider.rules),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildSectionHeader('Active Automations', '${ruleProvider.rules.length} Configured'),
            const SizedBox(height: 12),
            if (ruleProvider.rules.isEmpty)
              _buildEmptyRulesState()
            else
              ...ruleProvider.rules.map((rule) => _buildModernRuleCard(rule)),
            const SizedBox(height: 24),
            _buildSectionHeader('Live Geofence Radar', 'Real-time Evaluation'),
            const SizedBox(height: 12),
            _buildLiveRadarMapWidget(ruleProvider.rules),
          ],
        ],
      ),
    );
  }

  Widget _buildKPIMetricsRow(int totalRules, int activeRules, int triggersToday) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard(
              title: 'Active Automations',
              value: '$activeRules',
              subtext: '$totalRules Total Rules',
              icon: Icons.bolt_rounded,
              accentColor: AppColors.primaryLight,
              width: itemWidth,
            ),
            _buildMetricCard(
              title: 'Saved Locations',
              value: '${totalRules > 0 ? totalRules : 0}',
              subtext: 'Configured Zones',
              icon: Icons.place_rounded,
              accentColor: AppColors.accent,
              width: itemWidth,
            ),
            _buildMetricCard(
              title: 'Triggered Today',
              value: '$triggersToday',
              subtext: 'Actions Executed',
              icon: Icons.track_changes_rounded,
              accentColor: AppColors.success,
              width: itemWidth,
            ),
            _buildMetricCard(
              title: 'Engine Status',
              value: 'Active',
              subtext: 'Continuous GPS Stream',
              icon: Icons.radar_rounded,
              accentColor: AppColors.secondary,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500)),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
      ],
    );
  }

  Widget _buildModernRuleCard(RuleModel rule) {
    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: RuleEngine.instance.liveDistances,
      builder: (context, distMap, _) {
        final currentDist = distMap[rule.id];
        final isInside = currentDist != null && currentDist <= rule.radius;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rule.isActive ? AppColors.borderDark : AppColors.borderDark.withAlpha(60),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActionColor(rule.action.type).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getActionIcon(rule.action.type), color: _getActionColor(rule.action.type), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: rule.isActive ? Colors.white : AppColors.textMutedDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${rule.location.name} • ${rule.radius.toInt()}m geofence',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.isActive,
                    activeColor: AppColors.primaryLight,
                    onChanged: (val) => context.read<RuleProvider>().toggleRule(rule.id, val),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Proximity Indicator & Trigger Tag
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${rule.trigger.type.displayName} ➔ ${_formatActionDescription(rule.action)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  if (currentDist != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInside ? AppColors.success.withAlpha(30) : AppColors.surfaceLightDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isInside ? AppColors.success.withAlpha(80) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${currentDist.toInt()}m (${isInside ? "INSIDE" : "OUTSIDE"})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInside ? AppColors.success : AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Footer: Test Trigger & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () async {
                      await RuleEngine.instance.simulateTrigger(rule, 'ENTER');
                      if (context.mounted) {
                        context.read<HistoryProvider>().loadHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Simulated "${rule.name}" (${rule.action.type.displayName})'),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('Test Trigger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondaryDark),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RuleWizardScreen(existingRule: rule)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () => context.read<RuleProvider>().deleteRule(rule.id),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveRadarMapWidget(List<RuleModel> rules, {bool isFullCanvas = false}) {
    final defaultPos = const LatLng(12.9716, 77.5946);
    final mapCenter = _currentLocation ??
        (rules.isNotEmpty
            ? LatLng(rules.first.location.latitude, rules.first.location.longitude)
            : defaultPos);

    final mapCtrl = isFullCanvas ? _canvasMapController : _radarMapController;

    return Container(
      height: isFullCanvas ? null : 380,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapCtrl,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.geobuzz.geobuzz',
              ),

              // Geofence Circles
              CircleLayer(
                circles: [
                  // 1. Current Location Radar Ripple
                  if (_currentLocation != null)
                    CircleMarker(
                      point: _currentLocation!,
                      radius: _currentAccuracy != null && _currentAccuracy! > 20 ? _currentAccuracy! : 45.0,
                      useRadiusInMeter: true,
                      color: AppColors.accent.withAlpha(30),
                      borderColor: AppColors.accent,
                      borderStrokeWidth: 1.5,
                    ),

                  // 2. Rule Geofence Zones
                  ...rules.map((r) {
                    return CircleMarker(
                      point: LatLng(r.location.latitude, r.location.longitude),
                      radius: r.radius,
                      useRadiusInMeter: true,
                      color: AppColors.primary.withAlpha(40),
                      borderColor: AppColors.accent,
                      borderStrokeWidth: 2,
                    );
                  }),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // 1. Current User Device Location Marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withAlpha(40),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withAlpha(160),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 2. Automation Rule Markers
                  ...rules.map((r) {
                    return Marker(
                      point: LatLng(r.location.latitude, r.location.longitude),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withAlpha(128), blurRadius: 8),
                          ],
                        ),
                        child: Icon(_getActionIcon(r.action.type), color: Colors.white, size: 18),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top Info Badge: GPS Status & Coordinates
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgDark.withAlpha(220),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentLocation != null ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentLocation != null
                        ? 'Live GPS • ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                        : 'Locating Device...',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Floating "Locate Me" GPS Center Button
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _locateDevice(animateMap: true),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withAlpha(240),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        )
                      : const Icon(Icons.my_location_rounded, color: AppColors.accent, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRulesState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_location_alt_rounded, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          const Text('No Automations Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
            'Create your first location rule and let GeoBuzz do the work.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openCreateWizard,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Automation'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW B: AUTOMATIONS LIST VIEW
  // ==========================================
  Widget _buildAutomationsView({required bool isDesktop}) {
    final ruleProvider = context.watch<RuleProvider>();
    final filteredRules = _automationFilter == 'ALL'
        ? ruleProvider.rules
        : ruleProvider.rules.where((r) => r.action.type.value == _automationFilter).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? AppDimensions.lg : AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Automations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                onPressed: _openCreateWizard,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Rule'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Rules'),
                _buildFilterChip('ALARM', 'Alarms'),
                _buildFilterChip('SOUND_PROFILE', 'Sound Profiles'),
                _buildFilterChip('REMINDER', 'Reminders'),
                _buildFilterChip('WIFI', 'WiFi'),
                _buildFilterChip('BLUETOOTH', 'Bluetooth'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (filteredRules.isEmpty)
            _buildEmptyRulesState()
          else
            ...filteredRules.map((rule) => _buildModernRuleCard(rule)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _automationFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _automationFilter = filterKey),
      ),
    );
  }

  // ==========================================
  // VIEW C: MAP CANVAS VIEW
  // ==========================================
  Widget _buildMapCanvasView({required bool isDesktop}) {
    final ruleProvider = context.watch<RuleProvider>();
    return _buildLiveRadarMapWidget(ruleProvider.rules, isFullCanvas: true);
  }

  // ==========================================
  // VIEW D: ACTIVITY LOGS VIEW
  // ==========================================
  Widget _buildActivityView() {
    final historyProvider = context.watch<HistoryProvider>();

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Trigger Activity Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            if (historyProvider.history.isNotEmpty)
              TextButton.icon(
                onPressed: () => historyProvider.clearAllHistory(),
                icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppColors.textSecondaryDark),
                label: const Text('Clear Log', style: TextStyle(color: AppColors.textSecondaryDark)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (historyProvider.history.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No trigger events recorded yet.', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
          )
        else
          ...historyProvider.history.map((item) => _buildHistoryTimelineCard(item)),
      ],
    );
  }

  Widget _buildHistoryTimelineCard(HistoryItem item) {
    final dateStr = DateFormat('dd MMM yyyy • hh:mm a').format(item.timestamp);
    final isSuccess = item.status == 'SUCCESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.success.withAlpha(30) : AppColors.error.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.ruleName} (${item.triggerType})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  item.message,
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW E: ANALYTICS VIEW
  // ==========================================
  Widget _buildAnalyticsView() {
    final ruleProvider = context.watch<RuleProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usage Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Insights on how your location automations run.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          const SizedBox(height: 24),
          _buildKPIMetricsRow(ruleProvider.rules.length, ruleProvider.activeCount, historyProvider.history.length),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW F: SETTINGS VIEW
  // ==========================================
  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        const Text('Preferences & Hardware Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        _buildSettingsTile('Location Precision', 'High GPS Accuracy (±5m)', Icons.location_searching_rounded),
        _buildSettingsTile('Background Service', 'Always Active Foreground Service', Icons.battery_charging_full_rounded),
        _buildSettingsTile('Do Not Disturb Permissions', 'System Policy Granted', Icons.do_not_disturb_rounded),
        _buildSettingsTile('Dark Theme Palette', 'Obsidian Near-Black Navy (Default)', Icons.dark_mode_rounded),
      ],
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
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

  Color _getActionColor(ActionType type) {
    switch (type) {
      case ActionType.alarm:
        return AppColors.error;
      case ActionType.soundProfile:
        return AppColors.warning;
      case ActionType.wifi:
        return AppColors.accent;
      case ActionType.bluetooth:
        return Colors.blue;
      case ActionType.reminder:
        return AppColors.primaryLight;
    }
  }

  String _formatActionDescription(RuleAction action) {
    switch (action.type) {
      case ActionType.alarm:
        return 'Alarm (${action.alarmDurationSeconds}s)';
      case ActionType.soundProfile:
        return '${action.soundProfileMode ?? "Silent"} Mode';
      case ActionType.wifi:
        return 'WiFi Action';
      case ActionType.bluetooth:
        return 'Bluetooth Action';
      case ActionType.reminder:
        return action.reminderTitle?.isNotEmpty == true ? action.reminderTitle! : 'Reminder';
    }
  }
}
