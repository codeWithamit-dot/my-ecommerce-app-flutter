// lib/model/support_thread.dart

import 'package:flutter/material.dart';

// Represents a single conversation thread
class SupportThread {
  final String id;
  final String userId;
  final String subject;
  final String status;
  final DateTime createdAt;
  final DateTime lastUpdated;

  SupportThread({
    required this.id,
    required this.userId,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
  });

  // A helper to get a color based on the status
  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  factory SupportThread.fromMap(Map<String, dynamic> map) {
    return SupportThread(
      id: map['id'],
      userId: map['user_id'],
      subject: map['subject'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }
}