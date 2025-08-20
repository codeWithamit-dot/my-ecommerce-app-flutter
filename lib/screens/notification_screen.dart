// lib/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // ✅ FINAL FIX: Import path ko theek kar diya gaya hai

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      return [];
    }
  }
  
  // Future ko dobara fetch karne ke liye refresh function
  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE0F7F5),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Center(
                child: Text("You have no notifications yet.", style: TextStyle(fontSize: 16)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['read'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isRead ? Colors.white : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead 
          ? BorderSide(color: Colors.grey.shade300) 
          : BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(
          isRead ? Icons.notifications_none : Icons.notifications_active_rounded,
          color: isRead ? Colors.grey : Theme.of(context).primaryColor,
          size: 30,
        ),
        title: Text(
          notification['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['body'] ?? 'No content'),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().add_jm().format(DateTime.parse(notification['created_at'])),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () async {
          if (!isRead) {
            // Notification ko 'read' mark karo aur UI refresh karo
            await supabase
              .from('notifications')
              .update({'read': true})
              .eq('id', notification['id']);
            _refreshNotifications();
          }
        },
      ),
    );
  }
}