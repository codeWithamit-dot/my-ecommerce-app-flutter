// lib/screens/support/user_threads_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/model/support_thread.dart';
import 'package:my_ecommerce_app/services/support_service.dart';
import 'package:my_ecommerce_app/screens/support/chat_screen.dart';

class UserThreadsScreen extends StatefulWidget {
  const UserThreadsScreen({super.key});

  @override
  State<UserThreadsScreen> createState() => _UserThreadsScreenState();
}

class _UserThreadsScreenState extends State<UserThreadsScreen> {
  final SupportService _supportService = SupportService();
  late Future<List<SupportThread>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _refreshThreads();
  }

  void _refreshThreads() {
    setState(() {
      _threadsFuture = _supportService.getUserThreads();
    });
  }

  // ✅ FIX: Logic is reverted to the original, stable version.
  void _createNewThread() {
    final subjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Support Ticket'),
        content: TextField(
          controller: subjectController,
          decoration: const InputDecoration(labelText: 'Subject'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              final subject = subjectController.text.trim();
              if (subject.isNotEmpty) {
                // We pop the dialog first
                Navigator.of(ctx).pop();
                // Then we create the thread
                await _supportService.createNewThread(subject);
                // Finally, we refresh the list to show the new ticket
                _refreshThreads();
              }
            },
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF267873),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildThreadCard(BuildContext context, SupportThread thread) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          thread.status == 'closed' ? Icons.check_circle_outline : Icons.support_agent_outlined,
          color: thread.statusColor,
          size: 30,
        ),
        title: Text(thread.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Opened: ${DateFormat.yMMMd().format(thread.createdAt.toLocal())}'),
        trailing: Chip(
          label: Text(
            thread.status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: thread.statusColor,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ChatScreen(thread: thread)))
              .then((_) => _refreshThreads());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: const Text('My Support Tickets'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _buildSectionHeader("All Tickets"),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshThreads(),
                  child: FutureBuilder<List<SupportThread>>(
                    future: _threadsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('An error occurred: ${snapshot.error}'));
                      }
                      final threads = snapshot.data ?? [];
                      if (threads.isEmpty) {
                        return const Center(
                          child: Text(
                            'You have no support tickets.\nClick the + button to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: threads.length,
                        itemBuilder: (ctx, index) {
                          return _buildThreadCard(context, threads[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewThread,
        tooltip: 'New Ticket',
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}