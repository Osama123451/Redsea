import 'package:flutter/material.dart';

/// نموذج طلب تبادل الخبرات
class ExperienceSwapRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String targetExpertId;
  final String targetExperienceId;
  final String targetExperienceTitle;
  final String offeredExperienceId;
  final String offeredExperienceTitle;
  final String message;
  final String status; // pending, accepted, rejected, cancelled
  final DateTime timestamp;

  ExperienceSwapRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.targetExpertId,
    required this.targetExperienceId,
    required this.targetExperienceTitle,
    required this.offeredExperienceId,
    required this.offeredExperienceTitle,
    this.message = '',
    this.status = 'pending',
    required this.timestamp,
  });

  factory ExperienceSwapRequest.fromMap(String id, Map<dynamic, dynamic> map) {
    return ExperienceSwapRequest(
      id: id,
      requesterId: map['requesterId']?.toString() ?? '',
      requesterName: map['requesterName']?.toString() ?? '',
      targetExpertId: map['targetExpertId']?.toString() ?? '',
      targetExperienceId: map['targetExperienceId']?.toString() ?? '',
      targetExperienceTitle: map['targetExperienceTitle']?.toString() ?? '',
      offeredExperienceId: map['offeredExperienceId']?.toString() ?? '',
      offeredExperienceTitle: map['offeredExperienceTitle']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'targetExpertId': targetExpertId,
      'targetExperienceId': targetExperienceId,
      'targetExperienceTitle': targetExperienceTitle,
      'offeredExperienceId': offeredExperienceId,
      'offeredExperienceTitle': offeredExperienceTitle,
      'message': message,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
