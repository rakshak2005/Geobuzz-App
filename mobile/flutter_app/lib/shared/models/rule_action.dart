import 'package:equatable/equatable.dart';

enum ActionType {
  alarm,
  soundProfile,
  wifi,
  bluetooth,
  reminder,
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.alarm:
        return 'Location Alarm';
      case ActionType.soundProfile:
        return 'Sound Profile';
      case ActionType.wifi:
        return 'WiFi Action';
      case ActionType.bluetooth:
        return 'Bluetooth Action';
      case ActionType.reminder:
        return 'Reminder Notification';
    }
  }

  String get value {
    switch (this) {
      case ActionType.alarm:
        return 'ALARM';
      case ActionType.soundProfile:
        return 'SOUND_PROFILE';
      case ActionType.wifi:
        return 'WIFI';
      case ActionType.bluetooth:
        return 'BLUETOOTH';
      case ActionType.reminder:
        return 'REMINDER';
    }
  }

  static ActionType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'ALARM':
        return ActionType.alarm;
      case 'SOUND_PROFILE':
        return ActionType.soundProfile;
      case 'WIFI':
        return ActionType.wifi;
      case 'BLUETOOTH':
        return ActionType.bluetooth;
      case 'REMINDER':
        return ActionType.reminder;
      default:
        return ActionType.reminder;
    }
  }
}

class RuleAction extends Equatable {
  final ActionType type;
  // Sound profile configs
  final String? soundProfileMode; // SILENT, VIBRATE, NORMAL
  final String? exitSoundProfileMode; // NORMAL, RESTORE, NONE

  // Alarm configs
  final int alarmDurationSeconds;
  final bool alarmVibrate;
  final String? alarmSound;

  // Reminder configs
  final String? reminderTitle;
  final String? reminderMessage;
  final bool isOneTime;

  // Connectivity config
  final String? connectivityAction; // ENABLE, DISABLE, OPEN_SETTINGS

  const RuleAction({
    required this.type,
    this.soundProfileMode,
    this.exitSoundProfileMode,
    this.alarmDurationSeconds = 15,
    this.alarmVibrate = true,
    this.alarmSound,
    this.reminderTitle,
    this.reminderMessage,
    this.isOneTime = false,
    this.connectivityAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'soundProfileMode': soundProfileMode,
      'exitSoundProfileMode': exitSoundProfileMode,
      'alarmDurationSeconds': alarmDurationSeconds,
      'alarmVibrate': alarmVibrate ? 1 : 0,
      'alarmSound': alarmSound,
      'reminderTitle': reminderTitle,
      'reminderMessage': reminderMessage,
      'isOneTime': isOneTime ? 1 : 0,
      'connectivityAction': connectivityAction,
    };
  }

  factory RuleAction.fromMap(Map<String, dynamic> map) {
    return RuleAction(
      type: ActionTypeExtension.fromString(map['type'] as String? ?? 'REMINDER'),
      soundProfileMode: map['soundProfileMode'] as String?,
      exitSoundProfileMode: map['exitSoundProfileMode'] as String?,
      alarmDurationSeconds: (map['alarmDurationSeconds'] as num?)?.toInt() ?? 15,
      alarmVibrate: map['alarmVibrate'] == 1 || map['alarmVibrate'] == true,
      alarmSound: map['alarmSound'] as String?,
      reminderTitle: map['reminderTitle'] as String?,
      reminderMessage: map['reminderMessage'] as String?,
      isOneTime: map['isOneTime'] == 1 || map['isOneTime'] == true,
      connectivityAction: map['connectivityAction'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        type,
        soundProfileMode,
        exitSoundProfileMode,
        alarmDurationSeconds,
        alarmVibrate,
        alarmSound,
        reminderTitle,
        reminderMessage,
        isOneTime,
        connectivityAction,
      ];
}
