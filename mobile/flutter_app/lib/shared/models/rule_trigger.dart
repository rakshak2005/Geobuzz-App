import 'package:equatable/equatable.dart';

enum TriggerType {
  enter,
  exit,
  enterAndExit,
  near,
}

extension TriggerTypeExtension on TriggerType {
  String get displayName {
    switch (this) {
      case TriggerType.enter:
        return 'Arrive';
      case TriggerType.exit:
        return 'Leave';
      case TriggerType.enterAndExit:
        return 'Arrive & Leave';
      case TriggerType.near:
        return 'Approach';
    }
  }

  String get value {
    switch (this) {
      case TriggerType.enter:
        return 'ENTER';
      case TriggerType.exit:
        return 'EXIT';
      case TriggerType.enterAndExit:
        return 'ENTER_EXIT';
      case TriggerType.near:
        return 'NEAR';
    }
  }

  static TriggerType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'ENTER':
      case 'ARRIVE':
        return TriggerType.enter;
      case 'EXIT':
      case 'LEAVE':
        return TriggerType.exit;
      case 'ENTER_EXIT':
      case 'ENTER + EXIT':
      case 'ARRIVE & LEAVE':
      case 'ARRIVE + LEAVE':
        return TriggerType.enterAndExit;
      case 'NEAR':
      case 'APPROACH':
        return TriggerType.near;
      default:
        return TriggerType.enter;
    }
  }
}

class RuleTrigger extends Equatable {
  final TriggerType type;
  final double? nearThresholdMeters;
  final bool triggerImmediatelyIfInside;

  const RuleTrigger({
    required this.type,
    this.nearThresholdMeters,
    this.triggerImmediatelyIfInside = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'nearThresholdMeters': nearThresholdMeters,
      'triggerImmediatelyIfInside': triggerImmediatelyIfInside ? 1 : 0,
    };
  }

  factory RuleTrigger.fromMap(Map<String, dynamic> map) {
    return RuleTrigger(
      type: TriggerTypeExtension.fromString(map['type'] as String? ?? 'ENTER'),
      nearThresholdMeters: (map['nearThresholdMeters'] as num?)?.toDouble(),
      triggerImmediatelyIfInside: map['triggerImmediatelyIfInside'] == 1 ||
          map['triggerImmediatelyIfInside'] == true,
    );
  }

  @override
  List<Object?> get props => [type, nearThresholdMeters, triggerImmediatelyIfInside];
}
