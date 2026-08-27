import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
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
  LatLng _selectedLatLng = const LatLng(12.9716, 77.5946); // Default Bengaluru or current pos
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
  final TextEditingController _reminderTitleController = TextEditingController();
  final TextEditingController _reminderMessageController = TextEditingController();
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
        nearThresholdMeters: _selectedTrigger == TriggerType.near ? _nearThresholdMeters : null,
        triggerImmediatelyIfInside: _triggerImmediatelyIfInside,
      ),
      action: RuleAction(
        type: _selectedAction,
        soundProfileMode: _selectedAction == ActionType.soundProfile ? _soundProfileMode : null,
        exitSoundProfileMode: _selectedAction == ActionType.soundProfile ? _exitSoundProfileMode : null,
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          widget.existingRule != null ? 'Edit Automation' : 'Create Automation',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            color: AppColors.surfaceDark,
            child: Row(
              children: List.generate(5, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : (isCurrent ? AppColors.primary : AppColors.borderDark),
                      borderRadius: BorderRadius.circular(2),
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

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
                    ),
                    child: const Text('Back'),
                  ),
                if (_currentStep > 0) const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 4 ? AppColors.success : AppColors.primary,
                    ),
                    child: Text(
                      _currentStep == 4
                          ? (widget.existingRule != null ? 'Save Changes' : 'Activate Rule')
                          : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
        Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STEP 1 OF 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              const Text('Choose Geographic Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                controller: _ruleNameController,
                decoration: const InputDecoration(
                  labelText: 'Rule Name',
                  prefixIcon: Icon(Icons.edit_rounded, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Location Label (e.g. Office, Home, Bus Stop)',
                  prefixIcon: Icon(Icons.place_rounded, color: AppColors.primaryLight),
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
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP 2 OF 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          const Text('Define Geofence Radius', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
            'GeoBuzz will detect when your phone enters or leaves this circle.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetRadii.map((r) {
              final isSelected = (_radiusMeters - r).abs() < 1.0;
              return ChoiceChip(
                label: Text('${r.toInt()} m'),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceLightDark,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() => _radiusMeters = r);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          Text(
            'Custom Radius: ${_radiusMeters.toInt()} meters',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          ),
          Slider(
            value: _radiusMeters,
            min: 20.0,
            max: 2000.0,
            divisions: 100,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceLightDark,
            label: '${_radiusMeters.toInt()} m',
            onChanged: (val) {
              setState(() => _radiusMeters = val);
            },
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(color: AppColors.borderDark),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.secondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For indoor places (Office/Home), 50m-100m is recommended. For bus stops or transit alerts, 100m-250m is ideal.',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
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
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP 3 OF 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          const Text('Choose Event Trigger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),

          _buildTriggerCard(
            type: TriggerType.enter,
            title: 'ENTER Radius',
            desc: 'Executes immediately when your device enters the zone.',
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 12),
          _buildTriggerCard(
            type: TriggerType.exit,
            title: 'EXIT Radius',
            desc: 'Executes immediately when your device leaves the zone.',
            icon: Icons.logout_rounded,
          ),
          const SizedBox(height: 12),
          _buildTriggerCard(
            type: TriggerType.enterAndExit,
            title: 'ENTER + EXIT (Two-Way)',
            desc: 'Executes entry action on arrival and exit action on departure (e.g. Silent on arrive, Normal on leave).',
            icon: Icons.sync_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildTriggerCard(
            type: TriggerType.near,
            title: 'NEAR Proximity Alert',
            desc: 'Triggers when approaching within configured proximity threshold.',
            icon: Icons.radar_rounded,
          ),

          const SizedBox(height: 20),

          // Immediate Trigger Toggle for testing & current location
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(
                color: _triggerImmediatelyIfInside
                    ? AppColors.primary
                    : AppColors.borderDark,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: const Text(
                  'Trigger immediately if already inside radius',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Enable this to test the alarm right now if you are already at this location.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
                value: _triggerImmediatelyIfInside,
                activeColor: AppColors.primaryLight,
                onChanged: (val) {
                  setState(() => _triggerImmediatelyIfInside = val);
                },
              ),
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
      borderRadius: AppDimensions.roundedLg,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surfaceDark,
          borderRadius: AppDimensions.roundedLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLightDark,
                borderRadius: AppDimensions.roundedMd,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // STEP 4: Action Selection & Configuration
  Widget _buildStep4Action() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP 4 OF 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          const Text('Select & Configure Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _selectedAction = action),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

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
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sound Profile Target', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _soundProfileMode,
                items: const [
                  DropdownMenuItem(value: 'SILENT', child: Text('🔕 Silent Mode')),
                  DropdownMenuItem(value: 'VIBRATE', child: Text('📳 Vibrate Mode')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('🔔 Normal Mode (Ringtone)')),
                ],
                onChanged: (val) => setState(() => _soundProfileMode = val ?? 'SILENT'),
              ),
              const SizedBox(height: 16),
              const Text('On Exit Radius', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _exitSoundProfileMode,
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
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alarm Duration: $_alarmDurationSeconds seconds', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Slider(
                value: _alarmDurationSeconds.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$_alarmDurationSeconds sec',
                onChanged: (val) => setState(() => _alarmDurationSeconds = val.toInt()),
              ),
              SwitchListTile(
                title: const Text('Device Vibration Pattern', style: TextStyle(color: Colors.white)),
                value: _alarmVibrate,
                activeColor: AppColors.primaryLight,
                onChanged: (val) => setState(() => _alarmVibrate = val),
              ),
            ],
          ),
        );

      case ActionType.reminder:
        return Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _reminderTitleController,
                decoration: const InputDecoration(labelText: 'Reminder Title (e.g. Buy groceries)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reminderMessageController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reminder Message Details'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('One-time Trigger', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Automatically disable rule once triggered', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                value: _isOneTimeReminder,
                activeColor: AppColors.primaryLight,
                onChanged: (val) => setState(() => _isOneTimeReminder = val),
              ),
            ],
          ),
        );

      case ActionType.wifi:
      case ActionType.bluetooth:
        return Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selectedAction.displayName} Automation', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                'Due to Android 10+ platform security policies, GeoBuzz will present an interactive notification allowing instant one-tap toggle of connectivity settings upon entering or exiting the geofence.',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              ),
            ],
          ),
        );
    }
  }

  // STEP 5: Review & Save
  Widget _buildStep5Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP 5 OF 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          const Text('Review Automation Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_rounded, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationNameController.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 24),
                _buildSummaryRow('Geofence Radius', '${_radiusMeters.toInt()} meters'),
                _buildSummaryRow('Trigger Event', _selectedTrigger.displayName),
                if (_triggerImmediatelyIfInside)
                  _buildSummaryRow('Immediate Execution', 'Enabled (Fires right away if inside)'),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
