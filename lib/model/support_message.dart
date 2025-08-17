// lib/model/support_message.dart

// Represents a single message inside a thread
class SupportMessage {
  final int id;
  final String threadId;
  final String? senderId;
  final String content;
  final bool isFromAdmin;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.threadId,
    this.senderId,
    required this.content,
    required this.isFromAdmin,
    required this.createdAt,
  });

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'],
      threadId: map['thread_id'],
      senderId: map['sender_id'],
      content: map['content'],
      isFromAdmin: map['is_from_admin'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}