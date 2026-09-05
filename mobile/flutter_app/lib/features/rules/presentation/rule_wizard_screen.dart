import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/rule_model.dart';
import '../../../shared/models/rule_trigger.dart';
import '../../../shared/models/rule_action.dart';
import '../domain/rule_provider.dart';
import '../../locations/presentation/location_picker_map.dart';

class RuleWizardScreen extends StatefulWidget {
  final RuleModel? existingRule;

  const RuleWizardScreen({super.key, this.existingRule});

  @override
  State<RuleWizardScreen> createState() => _RuleWizardScreenState();
}

class _RuleWizardScreenState extends State<RuleWizardScreen> {
  int _currentStep = 0;

  // Step 1: Location
  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  LatLng _selectedLatLng =
      const LatLng(12.9716, 77.5946); // Default Bengaluru or current pos
  String _address = 'Bengaluru, Karnataka';

  // Step 2: Radius
  double _radiusMeters = 100.0;
  final List<double> _presetRadii = [30.0, 50.0, 100.0, 250.0, 500.0, 1000.0];

  // Step 3: Trigger
  TriggerType _selectedTrigger = TriggerType.enter;
  double _nearThresholdMeters = 200.0;
  bool _triggerImmediatelyIfInside = false;

  // Step 4: Action
  ActionType _selectedAction = ActionType.alarm;
  String _soundProfileMode = 'SILENT';
  String _exitSoundProfileMode = 'RESTORE';
  int _alarmDurationSeconds = 15;
  bool _alarmVibrate = true;
  final TextEditingController _reminderTitleController =
      TextEditingController();
  final TextEditingController _reminderMessageController =
      TextEditingController();
  bool _isOneTimeReminder = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      final r = widget.existingRule!;
      _ruleNameController.text = r.name;
      _locationNameController.text = r.location.name;
      _selectedLatLng = LatLng(r.location.latitude, r.location.longitude);
      _address = r.location.address ?? '';
      _radiusMeters = r.radius;
      _selectedTrigger = r.trigger.type;
      _nearThresholdMeters = r.trigger.nearThresholdMeters ?? 200.0;
      _triggerImmediatelyIfInside = r.trigger.triggerImmediatelyIfInside;
      _selectedAction = r.action.type;
      _soundProfileMode = r.action.soundProfileMode ?? 'SILENT';
      _exitSoundProfileMode = r.action.exitSoundProfileMode ?? 'RESTORE';
      _alarmDurationSeconds = r.action.alarmDurationSeconds;
      _alarmVibrate = r.action.alarmVibrate;
      _reminderTitleController.text = r.action.reminderTitle ?? '';
      _reminderMessageController.text = r.action.reminderMessage ?? '';
      _isOneTimeReminder = r.action.isOneTime;
    } else {
      _ruleNameController.text = 'Location Alarm';
      _locationNameController.text = 'My Location';
      _reminderTitleController.text = 'GeoBuzz Reminder';
      _reminderMessageController.text = 'You arrived at your destination!';

      // Auto-set to current GPS position if available
      final cachedPos = LocationService.instance.currentPosition.value;
      if (cachedPos != null) {
        _selectedLatLng = LatLng(cachedPos.latitude, cachedPos.longitude);
      }
    }
  }

  void _onNext() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _saveRule();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveRule() async {
    final rule = RuleModel(
      id: widget.existingRule?.id ?? const Uuid().v4(),
      name: _ruleNameController.text.trim().isNotEmpty
          ? _ruleNameController.text.trim()
          : 'Automation Rule',
      location: GeoLocation(
        name: _locationNameController.text.trim().isNotEmpty
            ? _locationNameController.text.trim()
            : 'Pinned Location',
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
        address: _address,
      ),
      radius: _radiusMeters,
      trigger: RuleTrigger(
        type: _selectedTrigger,
        nearThresholdMeters:
            _selectedTrigger == TriggerType.near ? _nearThresholdMeters : null,
        triggerImmediatelyIfInside: _triggerImmediatelyIfInside,
      ),
      action: RuleAction(
        type: _selectedAction,
        soundProfileMode: _selectedAction == ActionType.soundProfile
            ? _soundProfileMode
            : null,
        exitSoundProfileMode: _selectedAction == ActionType.soundProfile
            ? _exitSoundProfileMode
            : null,
        alarmDurationSeconds: _alarmDurationSeconds,
        alarmVibrate: _alarmVibrate,
        reminderTitle: _reminderTitleController.text.trim(),
        reminderMessage: _reminderMessageController.text.trim(),
        isOneTime: _isOneTimeReminder,
      ),
      isActive: widget.existingRule?.isActive ?? true,
      createdAt: widget.existingRule?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<RuleProvider>().saveRule(rule);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automation "${rule.name}" activated!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save automation.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          widget.existingRule != null ? 'Edit Automation' : 'Create Automation',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Indicator (Clean teal style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              children: List.generate(5, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: (isCompleted || isCurrent)
                          ? const Color(0xFF00A2A5)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Step Body
          Expanded(
            child: _buildCurrentStep(),
          ),

          // Bottom Navigation Buttons (Fixed Bottom Bar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5EBEF))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A2A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _currentStep == 4
                            ? (widget.existingRule != null ? 'Save Changes' : 'Activate Automation')
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Location();
      case 1:
        return _buildStep2Radius();
      case 2:
        return _buildStep3Trigger();
      case 3:
        return _buildStep4Action();
      case 4:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Location Selection
  Widget _buildStep1Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STEP 1 OF 5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00A2A5),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Choose Geographic Location',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ruleNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Rule Name',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF00A2A5), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00A2A5), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locationNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Location Label (e.g. Office, Home, Bus Stop)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.place_outlined, color: Color(0xFF00A2A5), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00A2A5), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LocationPickerMap(
            initialPosition: _selectedLatLng,
            radiusMeters: _radiusMeters,
            onLocationChanged: (pos, addr) {
              _selectedLatLng = pos;
              _address = addr;
            },
          ),
        ),
      ],
    );
  }

  // STEP 2: Radius Selection
  Widget _buildStep2Radius() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 2 OF 5',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Define Geofence Radius',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'GeoBuzz will detect when your phone enters or leaves this circle.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetRadii.map((r) {
              final isSelected = (_radiusMeters - r).abs() < 1.0;
              return ChoiceChip(
                label: Text('${r.toInt()} m'),
                selected: isSelected,
                selectedColor: const Color(0xFF00A2A5),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00A2A5) : const Color(0xFFCBD5E1),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                onSelected: (_) {
                  setState(() => _radiusMeters = r);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Custom Radius',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F7F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_radiusMeters.toInt()} meters',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF007A7C), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00A2A5),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: const Color(0xFF00A2A5),
                    overlayColor: const Color(0xFF00A2A5).withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _radiusMeters,
                    min: 20.0,
                    max: 2000.0,
                    divisions: 100,
                    label: '${_radiusMeters.toInt()} m',
                    onChanged: (val) {
                      setState(() => _radiusMeters = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD3EBEA)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF00A2A5), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For indoor places (Office/Home), 50m-100m is recommended. For transit alerts, 150m-300m is ideal.',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Trigger Selection
  Widget _buildStep3Trigger() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 3 OF 5',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Choose Event Trigger',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          _buildTriggerCard(
            type: TriggerType.enter,
            title: 'ENTER Radius',
            desc: 'Executes immediately when your device enters the zone.',
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 10),
          _buildTriggerCard(
            type: TriggerType.exit,
            title: 'EXIT Radius',
            desc: 'Executes immediately when your device leaves the zone.',
            icon: Icons.logout_rounded,
          ),
          const SizedBox(height: 10),
          _buildTriggerCard(
            type: TriggerType.enterAndExit,
            title: 'ENTER + EXIT (Two-Way)',
            desc: 'Executes entry action on arrival and exit action on departure (e.g. Silent on arrive, Normal on leave).',
            icon: Icons.sync_alt_rounded,
          ),
          const SizedBox(height: 10),
          _buildTriggerCard(
            type: TriggerType.near,
            title: 'NEAR Proximity Alert',
            desc: 'Triggers when approaching within configured proximity threshold.',
            icon: Icons.radar_rounded,
          ),

          const SizedBox(height: 16),

          // Immediate Trigger Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _triggerImmediatelyIfInside ? const Color(0xFF00A2A5) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SwitchListTile(
              title: const Text(
                'Trigger immediately if already inside radius',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Enable this to test the automation right away if you are already at this location.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
              ),
              value: _triggerImmediatelyIfInside,
              activeColor: const Color(0xFF00A2A5),
              onChanged: (val) {
                setState(() => _triggerImmediatelyIfInside = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCard({
    required TriggerType type,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _selectedTrigger == type;
    return InkWell(
      onTap: () => setState(() => _selectedTrigger = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F7F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A2A5) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00A2A5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF00A2A5), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF007A7C) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00A2A5), size: 20),
          ],
        ),
      ),
    );
  }

  // STEP 4: Action Selection & Configuration
  Widget _buildStep4Action() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 4 OF 5',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Select & Configure Action',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Action Type Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ActionType.values.map((action) {
                final isSelected = _selectedAction == action;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(action.displayName),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00A2A5),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF00A2A5) : const Color(0xFFCBD5E1),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _selectedAction = action),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Action Configuration Details
          _buildActionConfigPanel(),
        ],
      ),
    );
  }

  Widget _buildActionConfigPanel() {
    switch (_selectedAction) {
      case ActionType.soundProfile:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sound Profile Target',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _soundProfileMode,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: const [
                  DropdownMenuItem(value: 'SILENT', child: Text('🔕 Silent Mode')),
                  DropdownMenuItem(value: 'VIBRATE', child: Text('📳 Vibrate Mode')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('🔔 Normal Mode (Ringtone)')),
                ],
                onChanged: (val) => setState(() => _soundProfileMode = val ?? 'SILENT'),
              ),
              const SizedBox(height: 16),
              const Text('On Exit Radius',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _exitSoundProfileMode,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: const [
                  DropdownMenuItem(value: 'RESTORE', child: Text('Restore Previous Device Sound Mode')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('Force Normal Mode')),
                  DropdownMenuItem(value: 'NONE', child: Text('Keep Current State')),
                ],
                onChanged: (val) => setState(() => _exitSoundProfileMode = val ?? 'RESTORE'),
              ),
            ],
          ),
        );

      case ActionType.alarm:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alarm Duration: $_alarmDurationSeconds seconds',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF00A2A5),
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  thumbColor: const Color(0xFF00A2A5),
                ),
                child: Slider(
                  value: _alarmDurationSeconds.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$_alarmDurationSeconds sec',
                  onChanged: (val) => setState(() => _alarmDurationSeconds = val.toInt()),
                ),
              ),
              SwitchListTile(
                title: const Text('Device Vibration Pattern', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                value: _alarmVibrate,
                activeColor: const Color(0xFF00A2A5),
                onChanged: (val) => setState(() => _alarmVibrate = val),
              ),
            ],
          ),
        );

      case ActionType.reminder:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _reminderTitleController,
                decoration: InputDecoration(
                  labelText: 'Reminder Title (e.g. Buy groceries)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reminderMessageController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reminder Message Details',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('One-time Trigger', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                subtitle: const Text('Automatically disable rule once triggered', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                value: _isOneTimeReminder,
                activeColor: const Color(0xFF00A2A5),
                onChanged: (val) => setState(() => _isOneTimeReminder = val),
              ),
            ],
          ),
        );

      case ActionType.wifi:
      case ActionType.bluetooth:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selectedAction.displayName} Automation',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              const SizedBox(height: 8),
              const Text(
                'Due to Android platform security policies, GeoBuzz will present an interactive notification allowing instant one-tap toggle of connectivity settings upon entering or exiting the geofence.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        );
    }
  }

  // STEP 5: Review & Save
  Widget _buildStep5Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 5 OF 5',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Review Automation Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00A2A5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F7F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.place_rounded, color: Color(0xFF00A2A5), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationNameController.text,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 24),
                _buildSummaryRow('Geofence Radius', '${_radiusMeters.toInt()} meters'),
                _buildSummaryRow('Trigger Event', _selectedTrigger.displayName),
                if (_triggerImmediatelyIfInside)
                  _buildSummaryRow('Immediate Execution', 'Enabled (Fires right away)'),
                _buildSummaryRow('Action Type', _selectedAction.displayName),
                if (_selectedAction == ActionType.soundProfile)
                  _buildSummaryRow('Sound Mode', 'ENTER: $_soundProfileMode | EXIT: $_exitSoundProfileMode'),
                if (_selectedAction == ActionType.reminder)
                  _buildSummaryRow('Reminder Note', _reminderTitleController.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      ),
    );
  }
}
