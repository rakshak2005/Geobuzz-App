import 'package:equatable/equatable.dart';

enum GeofenceStatus {
  unknown,
  outside,
  inside,
  near,
}

class GeofenceState extends Equatable {
  final String ruleId;
  final GeofenceStatus status;
  final double? lastDistance;
  final DateTime lastEvaluatedAt;
  final DateTime? lastTriggeredAt;
  final String? lastTriggeredEvent; // ENTER, EXIT, NEAR

  const GeofenceState({
    required this.ruleId,
    this.status = GeofenceStatus.unknown,
    this.lastDistance,
    required this.lastEvaluatedAt,
    this.lastTriggeredAt,
    this.lastTriggeredEvent,
  });

  Map<String, dynamic> toMap() {
    return {
      'ruleId': ruleId,
      'status': status.name,
      'lastDistance': lastDistance,
      'lastEvaluatedAt': lastEvaluatedAt.toIso8601String(),
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      'lastTriggeredEvent': lastTriggeredEvent,
    };
  }

  factory GeofenceState.fromMap(Map<String, dynamic> map) {
    return GeofenceState(
      ruleId: map['ruleId'] as String,
      status: GeofenceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GeofenceStatus.unknown,
      ),
      lastDistance: (map['lastDistance'] as num?)?.toDouble(),
      lastEvaluatedAt: map['lastEvaluatedAt'] != null
          ? DateTime.tryParse(map['lastEvaluatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastTriggeredAt: map['lastTriggeredAt'] != null
          ? DateTime.tryParse(map['lastTriggeredAt'].toString())
          : null,
      lastTriggeredEvent: map['lastTriggeredEvent'] as String?,
    );
  }

  GeofenceState copyWith({
    String? ruleId,
    GeofenceStatus? status,
    double? lastDistance,
    DateTime? lastEvaluatedAt,
    DateTime? lastTriggeredAt,
    String? lastTriggeredEvent,
  }) {
    return GeofenceState(
      ruleId: ruleId ?? this.ruleId,
      status: status ?? this.status,
      lastDistance: lastDistance ?? this.lastDistance,
      lastEvaluatedAt: lastEvaluatedAt ?? this.lastEvaluatedAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      lastTriggeredEvent: lastTriggeredEvent ?? this.lastTriggeredEvent,
    );
  }

  @override
  List<Object?> get props => [
        ruleId,
        status,
        lastDistance,
        lastEvaluatedAt,
        lastTriggeredAt,
        lastTriggeredEvent,
      ];
}
