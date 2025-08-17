// lib/services/support_service.dart

import 'dart:async';
import 'package:flutter/material.dart'; // Added for debugPrint
import 'package:my_ecommerce_app/model/support_message.dart';
import 'package:my_ecommerce_app/model/support_thread.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Thread Management ---

  Future<List<SupportThread>> getUserThreads() async {
    final response = await _client
        .from('support_threads')
        .select()
        .eq('user_id', _client.auth.currentUser!.id)
        .order('last_updated', ascending: false);
    
    return response.map((item) => SupportThread.fromMap(item)).toList();
  }
  
  // For admins
  Future<List<SupportThread>> getAllThreads() async {
     final response = await _client
        .from('support_threads')
        .select()
        .order('last_updated', ascending: false);
    
    return response.map((item) => SupportThread.fromMap(item)).toList();
  }

  Future<void> createNewThread(String subject) async {
    await _client.from('support_threads').insert({
      'user_id': _client.auth.currentUser!.id,
      'subject': subject,
    });
  }

  // ✅ FIXED: The missing function is now added to your service.
  Future<void> updateThreadStatus({
    required String threadId,
    required String newStatus, // e.g., 'closed', 'in_progress'
  }) async {
    try {
      await _client
          .from('support_threads')
          .update({'status': newStatus})
          .eq('id', threadId);
    } catch (e) {
      debugPrint('Error updating thread status: $e');
      rethrow; // Rethrow to let the UI know something went wrong if needed
    }
  }
  
  // --- Message Management ---

  Stream<List<SupportMessage>> getMessagesStream(String threadId) {
    return _client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .map((listOfMaps) => listOfMaps.map((map) => SupportMessage.fromMap(map)).toList());
  }

  Future<void> sendMessage({
    required String threadId,
    required String content,
    required bool isFromAdmin,
  }) async {
    await _client.from('support_messages').insert({
      'thread_id': threadId,
      'sender_id': _client.auth.currentUser!.id,
      'content': content,
      'is_from_admin': isFromAdmin,
    });
    
    await _client.from('support_threads')
      .update({'last_updated': DateTime.now().toIso8601String()})
      .eq('id', threadId);
  }
}