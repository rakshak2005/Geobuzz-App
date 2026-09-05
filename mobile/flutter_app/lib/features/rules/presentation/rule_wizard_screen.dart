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
      // Default human names
      _ruleNameController.text = 'Office — Silent mode';
      _locationNameController.text = 'Office';
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
          : 'My Automation',
      location: GeoLocation(
        name: _locationNameController.text.trim().isNotEmpty
            ? _locationNameController.text.trim()
            : 'Saved Place',
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
            content: Text('Automation "${rule.name}" saved and active!'),
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

  String _getTriggerVerb() {
    switch (_selectedTrigger) {
      case TriggerType.enter:
        return 'arrive within';
      case TriggerType.exit:
        return 'leave';
      case TriggerType.enterAndExit:
        return 'arrive or leave';
      case TriggerType.near:
        return 'approach within';
    }
  }

  String _getActionSummary() {
    switch (_selectedAction) {
      case ActionType.soundProfile:
        return _soundProfileMode == 'SILENT'
            ? 'switch to Silent mode'
            : _soundProfileMode == 'VIBRATE'
                ? 'switch to Vibrate mode'
                : 'switch to Normal sound mode';
      case ActionType.alarm:
        return 'ring loud alarm';
      case ActionType.reminder:
        final title = _reminderTitleController.text.trim();
        return title.isNotEmpty ? 'show reminder "$title"' : 'show reminder';
      case ActionType.wifi:
        return 'prompt WiFi toggle';
      case ActionType.bluetooth:
        return 'prompt Bluetooth toggle';
    }
  }

  String _buildLiveAutomationSentence() {
    final placeName = _locationNameController.text.trim().isNotEmpty
        ? _locationNameController.text.trim()
        : 'selected place';
    final radiusText = '${_radiusMeters.toInt()} m';
    final triggerVerb = _getTriggerVerb();
    final actionText = _getActionSummary();

    return 'When I $triggerVerb $radiusText of $placeName → $actionText.';
  }

  static const List<String> _stepNames = [
    'Place',
    'Radius',
    'Trigger',
    'Action',
    'Review',
  ];

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
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar with Label
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final isCurrent = index == _currentStep;
                    final isCompleted = index < _currentStep;
                    return Text(
                      '${index + 1}. ${_stepNames[index]}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.w800 : (isCompleted ? FontWeight.w700 : FontWeight.w500),
                        color: isCurrent
                            ? const Color(0xFF00A2A5)
                            : (isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final isCompleted = index < _currentStep;
                    final isCurrent = index == _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
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
              ],
            ),
          ),

          // Step Body
          Expanded(
            child: _buildCurrentStep(),
          ),

          // Live Automation Sentence Formula Banner (Priority 1 #16, Priority 2 #22)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F6F6),
              border: Border(
                top: BorderSide(color: Color(0xFFCCECEB)),
                bottom: BorderSide(color: Color(0xFFCCECEB)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A2A5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _buildLiveAutomationSentence(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005B5C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
                            ? (widget.existingRule != null ? 'Save Changes' : 'Create Automation')
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

  // STEP 1: Location Selection (Priority 1 #10, #11, #12, #13)
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
                'STEP 1 OF 5 · PLACE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00A2A5),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Choose a place',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Where should GeoBuzz act?',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ruleNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Automation name',
                  hintText: 'e.g. Office — Silent mode, Bus stop alert',
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locationNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Place name',
                  hintText: 'Home, Office, College, Bus Stop...',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.place_outlined, color: Color(0xFF00A2A5), size: 18),
                  suffixIcon: TextButton(
                    onPressed: () {
                      final cachedPos = LocationService.instance.currentPosition.value;
                      if (cachedPos != null) {
                        setState(() {
                          _selectedLatLng = LatLng(cachedPos.latitude, cachedPos.longitude);
                          _locationNameController.text = 'Current Location';
                        });
                      }
                    },
                    child: const Text(
                      'Use current',
                      style: TextStyle(color: Color(0xFF00A2A5), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
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
                onChanged: (_) => setState(() {}),
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

  // STEP 2: Radius Selection (Priority 1 #8, #9, #14, #15)
  Widget _buildStep2Radius() {
    final Map<double, Map<String, String>> radiusInfo = {
      30.0: {'tag': 'Very precise', 'desc': 'Good for nearby entrances'},
      50.0: {'tag': 'Precise', 'desc': 'Good for buildings'},
      100.0: {'tag': 'Recommended', 'desc': 'Good for most places'},
      250.0: {'tag': 'Area-wide', 'desc': 'Good for campuses'},
      500.0: {'tag': 'Neighborhood', 'desc': 'Good for large areas'},
      1000.0: {'tag': 'Wide area', 'desc': 'Good for districts'},
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 2 OF 5 · RADIUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Set the trigger radius',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'GeoBuzz will trigger your automation when you enter or leave this area.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Radius Selection Grid Cards with Real-life Context (Priority 1 #14)
          Column(
            children: _presetRadii.map((r) {
              final isSelected = (_radiusMeters - r).abs() < 1.0;
              final info = radiusInfo[r] ?? {'tag': 'Custom', 'desc': ''};
              final label = r >= 1000 ? '${(r / 1000).toInt()} km' : '${r.toInt()} m';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _radiusMeters = r),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          width: 60,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? const Color(0xFF007A7C) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00A2A5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            info['tag']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            info['desc']!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF00A2A5), size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
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
                      'Custom Radius Slider',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14),
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
                const SizedBox(height: 8),
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

          const SizedBox(height: 14),
          // Improved contextual tip text (Priority 1 #15)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD3EBEA)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF00A2A5), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Smaller radii are more precise but may be affected by GPS accuracy. For most places, 50–150 m is a good starting point. You can adjust the radius anytime.',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Trigger Selection (Priority 1 #7, Priority 2 #23, #24)
  Widget _buildStep3Trigger() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 3 OF 5 · TRIGGER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'When should GeoBuzz act?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the moment that starts your automation.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),

          _buildTriggerCard(
            type: TriggerType.enter,
            title: 'Arrive',
            subtitle: 'When you enter the area',
            desc: 'Executes immediately when you arrive at this place.',
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 10),
          _buildTriggerCard(
            type: TriggerType.exit,
            title: 'Leave',
            subtitle: 'When you exit the area',
            desc: 'Executes immediately when you leave this place.',
            icon: Icons.logout_rounded,
          ),
          const SizedBox(height: 10),
          _buildTriggerCard(
            type: TriggerType.enterAndExit,
            title: 'Arrive & Leave',
            subtitle: 'Two-way automation',
            desc: 'Executes entry action on arrival and exit action on departure.',
            icon: Icons.sync_alt_rounded,
          ),
          const SizedBox(height: 10),
          _buildTriggerCard(
            type: TriggerType.near,
            title: 'Approach',
            subtitle: 'Before reaching the place',
            desc: 'Trigger before reaching your destination (ideal for bus & transit alarms).',
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
                'Test the automation right away if you are already at this location.',
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
    required String subtitle,
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
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: isSelected ? const Color(0xFF007A7C) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $subtitle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? const Color(0xFF007A7C) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
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

  // STEP 4: Action Selection & Configuration (Priority 1 #19)
  Widget _buildStep4Action() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 4 OF 5 · ACTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'What should happen?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick the response GeoBuzz should take when triggered.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Action Type Selector Chips with Semantic Accents
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
              const Text('Target sound mode',
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
              const Text('When leaving place',
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
                  DropdownMenuItem(value: 'RESTORE', child: Text('Restore Previous Sound Mode')),
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
                title: const Text('Vibrate phone pattern', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
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
                  labelText: 'Reminder title (e.g. Buy groceries, Pick up parcel)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reminderMessageController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional note details',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('One-time trigger', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                subtitle: const Text('Disable automation automatically once triggered', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
                'GeoBuzz will prompt an interactive one-tap toggle when entering or leaving this place.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        );
    }
  }

  // STEP 5: Review & Save (Priority 1 #16, #51)
  Widget _buildStep5Review() {
    final placeName = _locationNameController.text.trim().isNotEmpty
        ? _locationNameController.text.trim()
        : 'Selected place';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 5 OF 5 · REVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00A2A5),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Does this look right?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check your automation summary before saving.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Visual Diagram Flow Card (Priority 1 Signature UX)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00A2A5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A2A5).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
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
                      child: const Icon(Icons.place_rounded, color: Color(0xFF00A2A5), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ruleNameController.text.isNotEmpty
                                ? _ruleNameController.text
                                : 'My Automation',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            placeName,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        'Ready to run',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 26),

                _buildSummaryRow('Place', placeName),
                _buildSummaryRow('Trigger radius', '${_radiusMeters.toInt()} meters'),
                _buildSummaryRow('When', _selectedTrigger.displayName),
                _buildSummaryRow('Action', _selectedAction.displayName),
                if (_selectedAction == ActionType.soundProfile)
                  _buildSummaryRow('Sound Profile', 'Arrive: $_soundProfileMode · Leave: $_exitSoundProfileMode'),
                if (_selectedAction == ActionType.reminder)
                  _buildSummaryRow('Reminder Note', _reminderTitleController.text),
                if (_triggerImmediatelyIfInside)
                  _buildSummaryRow('Test execution', 'Immediate if inside place'),
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
