import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/location_service.dart';
import '../../core/services/rule_engine.dart';
import '../../features/rules/domain/rule_provider.dart';
import 'package:provider/provider.dart';

class CommandPaletteModal extends StatefulWidget {
  final Function(int tabIndex) onNavigate;
  final VoidCallback onOpenCreateWizard;

  const CommandPaletteModal({
    super.key,
    required this.onNavigate,
    required this.onOpenCreateWizard,
  });

  @override
  State<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends State<CommandPaletteModal> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ruleProvider = context.watch<RuleProvider>();
    final rules = ruleProvider.rules;

    final List<Map<String, dynamic>> staticActions = [
      {
        'title': 'Create New Automation',
        'subtitle': 'Build a new location trigger rule',
        'icon': Icons.add_rounded,
        'action': () {
          Navigator.of(context).pop();
          widget.onOpenCreateWizard();
        },
      },
      {
        'title': 'Go to Dashboard',
        'subtitle': 'System telemetry and live split view',
        'icon': Icons.dashboard_outlined,
        'action': () {
          Navigator.of(context).pop();
          widget.onNavigate(0);
        },
      },
      {
        'title': 'Go to All Automations',
        'subtitle': 'View and manage configured rules',
        'icon': Icons.bolt_outlined,
        'action': () {
          Navigator.of(context).pop();
          widget.onNavigate(1);
        },
      },
      {
        'title': 'Open Map Canvas',
        'subtitle': 'Full-screen geospatial visualizer',
        'icon': Icons.map_outlined,
        'action': () {
          Navigator.of(context).pop();
          widget.onNavigate(2);
        },
      },
      {
        'title': 'View Activity Logs',
        'subtitle': 'Real-time execution timeline',
        'icon': Icons.history_rounded,
        'action': () {
          Navigator.of(context).pop();
          widget.onNavigate(3);
        },
      },
      {
        'title': 'Open Settings',
        'subtitle': 'Device permissions and preferences',
        'icon': Icons.settings_outlined,
        'action': () {
          Navigator.of(context).pop();
          widget.onNavigate(4);
        },
      },
      {
        'title': 'Toggle GPS Background Engine',
        'subtitle': 'Pause or resume continuous location polling',
        'icon': Icons.radar_rounded,
        'action': () {
          Navigator.of(context).pop();
          if (LocationService.instance.isTracking.value) {
            LocationService.instance.stopPositionStream();
          } else {
            RuleEngine.instance.initialize();
          }
        },
      },
    ];

    final filteredStatic = staticActions.where((item) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return (item['title'] as String).toLowerCase().contains(q) ||
          (item['subtitle'] as String).toLowerCase().contains(q);
    }).toList();

    final matchingRules = rules.where((r) {
      if (_query.isEmpty) return false;
      final q = _query.toLowerCase();
      return r.name.toLowerCase().contains(q) ||
          r.location.name.toLowerCase().contains(q);
    }).toList();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 580,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        autofocus: true,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'Search actions, places, automations...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (val) => setState(() => _query = val.trim()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'ESC',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),

              // Results List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (matchingRules.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          'MATCHING AUTOMATIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      ...matchingRules.map((rule) {
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                          ),
                          title: Text(
                            rule.name,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${rule.location.name} • ${rule.radius.toInt()}m radius',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rule.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rule.isActive ? 'ACTIVE' : 'PAUSED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: rule.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onNavigate(1);
                          },
                        );
                      }),
                      const Divider(color: Color(0xFFE2E8F0), height: 16),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        'COMMANDS & NAVIGATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    ...filteredStatic.map((item) {
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(item['icon'] as IconData, size: 16, color: const Color(0xFF334155)),
                        ),
                        title: Text(
                          item['title'] as String,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          item['subtitle'] as String,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                        onTap: item['action'] as VoidCallback,
                      );
                    }),
                  ],
                ),
              ),

              // Bottom shortcuts hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusLg)),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    Text(
                      '↑↓ to navigate   •   ↵ to select   •   ESC to dismiss',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Spacer(),
                    Text(
                      'GeoBuzz Spatial OS',
                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
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
}
