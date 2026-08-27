import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'geo_location.dart';
import 'rule_trigger.dart';
import 'rule_action.dart';

class RuleModel extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final GeoLocation location;
  final double radius;
  final RuleTrigger trigger;
  final RuleAction action;
  final bool isActive;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RuleModel({
    required this.id,
    this.userId,
    required this.name,
    required this.location,
    required this.radius,
    required this.trigger,
    required this.action,
    this.isActive = true,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'location_json': jsonEncode(location.toMap()),
      'radius': radius,
      'trigger_json': jsonEncode(trigger.toMap()),
      'action_json': jsonEncode(action.toMap()),
      'isActive': isActive ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'location': location.toMap(),
      'radius': radius,
      'trigger': trigger.toMap(),
      'action': action.toMap(),
      'isActive': isActive,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel.fromMap(json);

  factory RuleModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> locMap;
    if (map['location_json'] != null) {
      locMap = jsonDecode(map['location_json'] as String);
    } else if (map['location'] is Map) {
      locMap = Map<String, dynamic>.from(map['location'] as Map);
    } else {
      locMap = {};
    }

    Map<String, dynamic> trigMap;
    if (map['trigger_json'] != null) {
      trigMap = jsonDecode(map['trigger_json'] as String);
    } else if (map['trigger'] is Map) {
      trigMap = Map<String, dynamic>.from(map['trigger'] as Map);
    } else {
      trigMap = {'type': map['trigger']?.toString() ?? 'ENTER'};
    }

    Map<String, dynamic> actMap;
    if (map['action_json'] != null) {
      actMap = jsonDecode(map['action_json'] as String);
    } else if (map['action'] is Map) {
      actMap = Map<String, dynamic>.from(map['action'] as Map);
    } else {
      actMap = {'type': map['action']?.toString() ?? 'REMINDER'};
    }

    return RuleModel(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString(),
      name: map['name'] as String? ?? 'Untitled Rule',
      location: GeoLocation.fromMap(locMap),
      radius: (map['radius'] as num?)?.toDouble() ?? 100.0,
      trigger: RuleTrigger.fromMap(trigMap),
      action: RuleAction.fromMap(actMap),
      isActive: map['isActive'] == 1 || map['isActive'] == true || map['is_active'] == 1 || map['is_active'] == true,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : (map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : (map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  RuleModel copyWith({
    String? id,
    String? userId,
    String? name,
    GeoLocation? location,
    double? radius,
    RuleTrigger? trigger,
    RuleAction? action,
    bool? isActive,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RuleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      trigger: trigger ?? this.trigger,
      action: action ?? this.action,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        location,
        radius,
        trigger,
        action,
        isActive,
        isSynced,
        createdAt,
        updatedAt,
      ];
}
