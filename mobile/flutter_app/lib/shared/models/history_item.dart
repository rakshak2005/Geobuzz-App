import 'package:equatable/equatable.dart';

class HistoryItem extends Equatable {
  final String id;
  final String? ruleId;
  final String ruleName;
  final String locationName;
  final String triggerType;
  final String actionType;
  final String status; // SUCCESS, FAILURE, INFO
  final String message;
  final DateTime timestamp;

  const HistoryItem({
    required this.id,
    this.ruleId,
    required this.ruleName,
    required this.locationName,
    required this.triggerType,
    required this.actionType,
    required this.status,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ruleId': ruleId,
      'ruleName': ruleName,
      'locationName': locationName,
      'triggerType': triggerType,
      'actionType': actionType,
      'status': status,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      ruleId: map['ruleId']?.toString(),
      ruleName: map['ruleName'] as String? ?? 'Automation Rule',
      locationName: map['locationName'] as String? ?? 'Unknown Location',
      triggerType: map['triggerType'] as String? ?? 'ENTER',
      actionType: map['actionType'] as String? ?? 'REMINDER',
      status: map['status'] as String? ?? 'SUCCESS',
      message: map['message'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ruleId,
        ruleName,
        locationName,
        triggerType,
        actionType,
        status,
        message,
        timestamp,
      ];
}
