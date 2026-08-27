import 'package:flutter_test/flutter_test.dart';
import 'package:geobuzz/shared/models/geo_location.dart';
import 'package:geobuzz/shared/models/rule_model.dart';
import 'package:geobuzz/shared/models/rule_trigger.dart';
import 'package:geobuzz/shared/models/rule_action.dart';
import 'package:geobuzz/shared/models/geofence_state.dart';

void main() {
  group('RuleModel Serialization & State Machine Tests', () {
    test('RuleModel serialization and deserialization preserves properties', () {
      final rule = RuleModel(
        id: 'test-rule-123',
        name: 'Office Silent Mode',
        location: const GeoLocation(
          name: 'Tech Park Office',
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'MG Road, Bengaluru',
        ),
        radius: 150.0,
        trigger: const RuleTrigger(type: TriggerType.enterAndExit),
        action: const RuleAction(
          type: ActionType.soundProfile,
          soundProfileMode: 'SILENT',
          exitSoundProfileMode: 'RESTORE',
        ),
        isActive: true,
        createdAt: DateTime(2026, 8, 27, 10, 0),
        updatedAt: DateTime(2026, 8, 27, 10, 0),
      );

      final map = rule.toMap();
      final restored = RuleModel.fromMap(map);

      expect(restored.id, equals(rule.id));
      expect(restored.name, equals('Office Silent Mode'));
      expect(restored.location.name, equals('Tech Park Office'));
      expect(restored.location.latitude, equals(12.9716));
      expect(restored.location.longitude, equals(77.5946));
      expect(restored.radius, equals(150.0));
      expect(restored.trigger.type, equals(TriggerType.enterAndExit));
      expect(restored.action.type, equals(ActionType.soundProfile));
      expect(restored.action.soundProfileMode, equals('SILENT'));
      expect(restored.action.exitSoundProfileMode, equals('RESTORE'));
      expect(restored.isActive, isTrue);
    });

    test('GeofenceState tracks discrete states accurately', () {
      final state = GeofenceState(
        ruleId: 'test-rule-123',
        status: GeofenceStatus.inside,
        lastDistance: 45.0,
        lastEvaluatedAt: DateTime(2026, 8, 27, 10, 5),
        lastTriggeredAt: DateTime(2026, 8, 27, 10, 5),
        lastTriggeredEvent: 'ENTER',
      );

      final map = state.toMap();
      final restored = GeofenceState.fromMap(map);

      expect(restored.ruleId, equals('test-rule-123'));
      expect(restored.status, equals(GeofenceStatus.inside));
      expect(restored.lastDistance, equals(45.0));
      expect(restored.lastTriggeredEvent, equals('ENTER'));
    });
  });
}
