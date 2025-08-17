// lib/screens/support/admin_threads_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/model/support_thread.dart';
import 'package:my_ecommerce_app/services/support_service.dart';
import 'chat_screen.dart';

class AdminThreadsScreen extends StatefulWidget {
  const AdminThreadsScreen({super.key});
  @override
  State<AdminThreadsScreen> createState() => _AdminThreadsScreenState();
}

class _AdminThreadsScreenState extends State<AdminThreadsScreen> {
  final SupportService _supportService = SupportService();
  late Future<List<SupportThread>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _refreshThreads();
  }
  
  // --- No changes to logic ---
  void _refreshThreads() {
    setState(() {
      _threadsFuture = _supportService.getAllThreads();
    });
  }

  // ✅ UI UPDATE: Reusing the header style
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
  
  // ✅ UI UPDATE: New styled card for each support thread
  Widget _buildThreadCard(BuildContext context, SupportThread thread) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          thread.status == 'closed' ? Icons.check_circle : Icons.support_agent,
          color: thread.statusColor,
          size: 30,
        ),
        title: Text(thread.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('User ID: ${thread.userId.substring(0, 8)}... • ${DateFormat.yMMMd().format(thread.createdAt.toLocal())}'),
        trailing: Chip(
          label: Text(
            thread.status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: thread.statusColor,
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
      // ✅ UI UPDATE: Themed AppBar and background color
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: const Text('Admin - Support Tickets'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshThreads,
            tooltip: 'Refresh Tickets',
          ),
        ],
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
                      final threads = snapshot.data ?? [];
                      if (threads.isEmpty) {
                        return const Center(child: Text('No support tickets found.'));
                      }
                      return ListView.builder(
                        itemCount: threads.length,
                        itemBuilder: (ctx, index) {
                           // ✅ UI UPDATE: Using the new styled card
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
    );
  }
}