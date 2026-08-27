import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/rule_model.dart';
import '../../shared/models/rule_trigger.dart';
import '../../shared/models/rule_action.dart';
import '../../shared/models/geofence_state.dart';
import '../../shared/models/history_item.dart';
import 'database_helper.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import 'sound_profile_service.dart';

class RuleEngine {
  static final RuleEngine instance = RuleEngine._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocationService _locationService = LocationService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final AlarmService _alarmService = AlarmService.instance;
  final SoundProfileService _soundProfileService = SoundProfileService.instance;

  // Active in-memory rule cache & state cache for sub-millisecond evaluation
  final Map<String, GeofenceState> _stateMap = {};
  List<RuleModel> _activeRules = [];
  bool _isInitialized = false;

  final ValueNotifier<int> activeRulesCount = ValueNotifier<int>(0);
  final ValueNotifier<DateTime?> lastEvaluatedTime = ValueNotifier<DateTime?>(null);
  final ValueNotifier<Map<String, double>> liveDistances = ValueNotifier<Map<String, double>>({});

  RuleEngine._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _notificationService.initialize();
    await reloadRules();

    // Load persisted geofence states from SQLite
    final states = await _db.getAllGeofenceStates();
    _stateMap.addAll(states);

    // Start location tracking stream
    _locationService.startPositionStream((position) {
      evaluateRules(position);
    });

    _isInitialized = true;
  }

  Future<void> reloadRules() async {
    _activeRules = await _db.getActiveRules();
    activeRulesCount.value = _activeRules.length;
  }

  Future<void> evaluateRules(Position currentPos) async {
    lastEvaluatedTime.value = DateTime.now();
    final distMap = Map<String, double>.from(liveDistances.value);

    for (final rule in _activeRules) {
      if (!rule.isActive) continue;

      try {
        final distance = _locationService.calculateDistance(
          currentPos.latitude,
          currentPos.longitude,
          rule.location.latitude,
          rule.location.longitude,
        );
        distMap[rule.id] = distance;
        await _evaluateSingleRule(rule, currentPos, distance);
      } catch (e) {
        debugPrint('Error evaluating rule "${rule.name}": $e');
      }
    }

    liveDistances.value = distMap;
  }

  Future<void> _evaluateSingleRule(RuleModel rule, Position currentPos, double distance) async {
    // Get or initialize state for this rule
    var state = _stateMap[rule.id] ??
        await _db.getGeofenceState(rule.id) ??
        GeofenceState(
          ruleId: rule.id,
          status: GeofenceStatus.unknown,
          lastDistance: distance,
          lastEvaluatedAt: DateTime.now(),
        );

    final radius = rule.radius;
    final isInside = distance <= radius;
    final previousStatus = state.status;

    // --- State Machine & Trigger Detection ---
    if (previousStatus == GeofenceStatus.unknown) {
      // First observation - establish baseline state
      final shouldTriggerImmediately = isInside && rule.trigger.triggerImmediatelyIfInside;

      state = state.copyWith(
        status: isInside ? GeofenceStatus.inside : GeofenceStatus.outside,
        lastDistance: distance,
        lastEvaluatedAt: DateTime.now(),
        lastTriggeredAt: shouldTriggerImmediately ? DateTime.now() : null,
        lastTriggeredEvent: shouldTriggerImmediately ? 'ENTER' : null,
      );
      _stateMap[rule.id] = state;
      await _db.saveGeofenceState(state);

      if (shouldTriggerImmediately) {
        await _executeAction(rule, 'ENTER', distance);
      }
      return;
    }

    // 1. Check ENTER trigger (transition from OUTSIDE to INSIDE)
    if (previousStatus == GeofenceStatus.outside && isInside) {
      state = state.copyWith(
        status: GeofenceStatus.inside,
        lastDistance: distance,
        lastEvaluatedAt: DateTime.now(),
        lastTriggeredAt: DateTime.now(),
        lastTriggeredEvent: 'ENTER',
      );
      _stateMap[rule.id] = state;
      await _db.saveGeofenceState(state);

      if (rule.trigger.type == TriggerType.enter ||
          rule.trigger.type == TriggerType.enterAndExit) {
        await _executeAction(rule, 'ENTER', distance);
      }
    }
    // 2. Check EXIT trigger (transition from INSIDE to OUTSIDE)
    else if (previousStatus == GeofenceStatus.inside && !isInside) {
      state = state.copyWith(
        status: GeofenceStatus.outside,
        lastDistance: distance,
        lastEvaluatedAt: DateTime.now(),
        lastTriggeredAt: DateTime.now(),
        lastTriggeredEvent: 'EXIT',
      );
      _stateMap[rule.id] = state;
      await _db.saveGeofenceState(state);

      if (rule.trigger.type == TriggerType.exit ||
          rule.trigger.type == TriggerType.enterAndExit) {
        await _executeAction(rule, 'EXIT', distance);
      }
    }
    // 3. Check NEAR trigger
    else if (rule.trigger.type == TriggerType.near) {
      final nearThreshold = rule.trigger.nearThresholdMeters ?? (radius * 1.5);
      final isNear = distance <= nearThreshold;

      if (previousStatus != GeofenceStatus.near && isNear) {
        state = state.copyWith(
          status: GeofenceStatus.near,
          lastDistance: distance,
          lastEvaluatedAt: DateTime.now(),
          lastTriggeredAt: DateTime.now(),
          lastTriggeredEvent: 'NEAR',
        );
        _stateMap[rule.id] = state;
        await _db.saveGeofenceState(state);
        await _executeAction(rule, 'NEAR', distance);
      } else if (!isNear && previousStatus == GeofenceStatus.near) {
        state = state.copyWith(
          status: isInside ? GeofenceStatus.inside : GeofenceStatus.outside,
          lastDistance: distance,
          lastEvaluatedAt: DateTime.now(),
        );
        _stateMap[rule.id] = state;
        await _db.saveGeofenceState(state);
      }
    } else {
      // Periodic distance update without state change
      state = state.copyWith(
        lastDistance: distance,
        lastEvaluatedAt: DateTime.now(),
      );
      _stateMap[rule.id] = state;
    }
  }

  /// Manually simulate a trigger event for instant testing on any platform
  Future<void> simulateTrigger(RuleModel rule, String triggerEvent) async {
    final dist = liveDistances.value[rule.id] ?? 0.0;
    await _executeAction(rule, triggerEvent, dist);
  }

  Future<void> _executeAction(RuleModel rule, String triggerEvent, double currentDistance) async {
    final action = rule.action;
    final historyId = const Uuid().v4();
    String executionStatus = 'SUCCESS';
    String message = '';

    try {
      switch (action.type) {
        case ActionType.alarm:
          await _alarmService.triggerAlarm(
            ruleName: rule.name,
            durationSeconds: action.alarmDurationSeconds,
            enableVibration: action.alarmVibrate,
          );
          await _notificationService.showNotification(
            id: rule.id.hashCode,
            title: '🚨 GeoBuzz Alarm: ${rule.name}',
            body: '$triggerEvent detected (${currentDistance.toInt()}m from ${rule.location.name})',
            isAlarm: true,
          );
          message = 'Triggered ${action.alarmDurationSeconds}s location alarm';
          break;

        case ActionType.soundProfile:
          if (triggerEvent == 'ENTER') {
            final targetMode = action.soundProfileMode ?? 'SILENT';
            if (!kIsWeb) {
              await _soundProfileService.applySoundProfile(targetMode, saveCurrentState: true);
            }
            await _notificationService.showNotification(
              id: rule.id.hashCode,
              title: '🔕 GeoBuzz Sound Profile: ${rule.name}',
              body: 'Switched sound mode to $targetMode on ENTER',
            );
            message = 'Applied $targetMode sound profile';
          } else if (triggerEvent == 'EXIT') {
            if (!kIsWeb) {
              if (action.exitSoundProfileMode == 'RESTORE' || action.exitSoundProfileMode == null) {
                await _soundProfileService.restorePreviousSoundProfile();
                message = 'Restored previous sound profile on EXIT';
              } else if (action.exitSoundProfileMode == 'NORMAL') {
                await _soundProfileService.applySoundProfile('NORMAL', saveCurrentState: false);
                message = 'Switched sound mode to NORMAL on EXIT';
              }
            } else {
              message = 'Switched sound mode to NORMAL on EXIT';
            }
            await _notificationService.showNotification(
              id: rule.id.hashCode,
              title: '🔔 GeoBuzz Sound Profile: ${rule.name}',
              body: message,
            );
          }
          break;

        case ActionType.wifi:
          await _notificationService.showNotification(
            id: rule.id.hashCode,
            title: '📶 GeoBuzz WiFi: ${rule.name}',
            body: '$triggerEvent detected at ${rule.location.name}. Tap to manage WiFi network.',
          );
          message = 'Prompted WiFi action on $triggerEvent';
          break;

        case ActionType.bluetooth:
          await _notificationService.showNotification(
            id: rule.id.hashCode,
            title: 'ᛒ GeoBuzz Bluetooth: ${rule.name}',
            body: '$triggerEvent detected at ${rule.location.name}. Tap to manage Bluetooth.',
          );
          message = 'Prompted Bluetooth action on $triggerEvent';
          break;

        case ActionType.reminder:
          final title = action.reminderTitle?.isNotEmpty == true
              ? action.reminderTitle!
              : 'GeoBuzz Reminder: ${rule.name}';
          final body = action.reminderMessage?.isNotEmpty == true
              ? action.reminderMessage!
              : 'You arrived near ${rule.location.name}';

          await _notificationService.showNotification(
            id: rule.id.hashCode,
            title: title,
            body: body,
          );
          message = 'Sent reminder notification';

          // If one-time reminder, automatically deactivate the rule
          if (action.isOneTime) {
            await _db.toggleRuleStatus(rule.id, false);
            await reloadRules();
          }
          break;
      }
    } catch (e) {
      executionStatus = 'FAILURE';
      message = 'Failed to execute action: $e';
      debugPrint('Action execution failed: $e');
    }

    // Persist to trigger history log
    final historyItem = HistoryItem(
      id: historyId,
      ruleId: rule.id,
      ruleName: rule.name,
      locationName: rule.location.name,
      triggerType: triggerEvent,
      actionType: action.type.value,
      status: executionStatus,
      message: message,
      timestamp: DateTime.now(),
    );

    await _db.insertHistory(historyItem);
  }
}
