import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/rule_engine.dart';
import '../../../shared/models/rule_model.dart';
import '../../../shared/models/rule_trigger.dart';
import '../../../shared/models/rule_action.dart';
import '../../../shared/widgets/alarm_banner.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../rules/domain/rule_provider.dart';
import '../../rules/presentation/rule_wizard_screen.dart';
import '../../history/domain/history_provider.dart';
import '../../history/presentation/history_screen.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../auth/domain/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SafeArea(
        child: _selectedTabIndex == 0
            ? _buildDashboardTab()
            : const HistoryScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF64748B),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RuleWizardScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Rule', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildDashboardTab() {
    final ruleProvider = context.watch<RuleProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final authProvider = context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await ruleProvider.loadRules();
        await historyProvider.loadHistory();
      },
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.md),
        children: [
          // 1. Top Greeting Header & Profile/Logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GeoBuzz',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, ${authProvider.userName ?? "Explorer"}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
                onPressed: () {
                  authProvider.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Active Alarm Banner (if ringing)
          const AlarmBanner(),

          // 3. Location Engine Status Card
          _buildEngineStatusCard(ruleProvider.activeCount),
          const SizedBox(height: 24),

          // 4. Section: Active Automations Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Automations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                '${ruleProvider.rules.length} Total',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Automation Cards List
          if (ruleProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (ruleProvider.rules.isEmpty)
            _buildEmptyState()
          else
            ...ruleProvider.rules.map((rule) => _buildRuleCard(rule)),

          const SizedBox(height: 24),

          // 6. Section: Recent Activity Snippet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedTabIndex = 1),
                child: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (historyProvider.history.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.roundedMd,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No geofence events recorded yet. Click "Test Trigger" on any card or travel across geofence boundaries.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            )
          else
            ...historyProvider.history.take(3).map((item) => _buildRecentActivityTile(item)),

          const SizedBox(height: 60), // Spacing for FAB
        ],
      ),
    );
  }

  Widget _buildEngineStatusCard(int activeCount) {
    return ValueListenableBuilder<bool>(
      valueListenable: LocationService.instance.isTracking,
      builder: (context, isTracking, _) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(
              color: isTracking ? AppColors.primary.withAlpha(80) : const Color(0xFFE2E8F0),
            ),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTracking ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTracking ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  color: isTracking ? const Color(0xFF059669) : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTracking ? const Color(0xFF059669) : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isTracking ? 'ENGINE ACTIVE' : 'ENGINE PAUSED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isTracking ? const Color(0xFF059669) : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeCount automations running locally',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isTracking,
                activeColor: AppColors.primary,
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

  Widget _buildRuleCard(RuleModel rule) {
    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: RuleEngine.instance.liveDistances,
      builder: (context, distMap, _) {
        final currentDist = distMap[rule.id];
        final isInside = currentDist != null && currentDist <= rule.radius;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Location name, radius badge, enabled toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: rule.isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${rule.location.name} • ${rule.radius.toInt()} m radius',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.isActive,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      context.read<RuleProvider>().toggleRule(rule.id, val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Live Proximity Pill (if available)
              if (currentDist != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInside ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInside ? Icons.check_circle_rounded : Icons.radar_rounded,
                        size: 13,
                        color: isInside ? const Color(0xFF059669) : AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Distance: ${currentDist.toInt()} m (${isInside ? "INSIDE ZONE" : "OUTSIDE ZONE"})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInside ? const Color(0xFF059669) : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Rule Trigger & Action Pills
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppDimensions.roundedMd,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    _buildActionIcon(rule.action.type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rule.trigger.type.displayName} ➔ ${_formatActionDescription(rule.action)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: rule.isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Card Footer: Responsive wrap for actions and trigger button
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      rule.isActive ? StatusBadge.active() : StatusBadge.inactive(),
                      const SizedBox(width: 8),
                      // Test Trigger Simulation Button
                      InkWell(
                        onTap: () async {
                          await RuleEngine.instance.simulateTrigger(rule, 'ENTER');
                          if (context.mounted) {
                            context.read<HistoryProvider>().loadHistory();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Triggered "${rule.name}" (${rule.action.type.displayName})'),
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
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withAlpha(60)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Test Trigger',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RuleWizardScreen(existingRule: rule)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDelete(rule),
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

  Widget _buildActionIcon(ActionType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ActionType.alarm:
        icon = Icons.alarm_rounded;
        color = AppColors.error;
        break;
      case ActionType.soundProfile:
        icon = Icons.volume_off_rounded;
        color = AppColors.warning;
        break;
      case ActionType.wifi:
        icon = Icons.wifi_rounded;
        color = AppColors.secondary;
        break;
      case ActionType.bluetooth:
        icon = Icons.bluetooth_rounded;
        color = Colors.blue;
        break;
      case ActionType.reminder:
        icon = Icons.notifications_active_rounded;
        color = AppColors.primary;
        break;
    }
    return Icon(icon, color: color, size: 18);
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
        return action.reminderTitle?.isNotEmpty == true
            ? action.reminderTitle!
            : 'Reminder';
    }
  }

  Widget _buildRecentActivityTile(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.sm + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.roundedMd,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.ruleName} (${item.triggerType})',
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  item.message ?? '',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('hh:mm a').format(item.timestamp),
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.roundedLg,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_location_alt_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No Automations Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          const Text(
            'Create your first rule to silence your phone at office or set an arrival alarm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RuleWizardScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Rule'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(RuleModel rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Automation?', style: TextStyle(color: Color(0xFF0F172A))),
        content: Text('Are you sure you want to remove "${rule.name}"?', style: const TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<RuleProvider>().deleteRule(rule.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
