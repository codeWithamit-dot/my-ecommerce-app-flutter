// lib/screens/support/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/model/support_message.dart';
import 'package:my_ecommerce_app/model/support_thread.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:my_ecommerce_app/services/support_service.dart';

class ChatScreen extends StatefulWidget {
  final SupportThread thread;
  const ChatScreen({super.key, required this.thread});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupportService _supportService = SupportService();
  late final Stream<List<SupportMessage>> _messagesStream;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _messagesStream = _supportService.getMessagesStream(widget.thread.id);
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- No changes to your logic ---
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    final isAdmin = Provider.of<UserRoleProvider>(context, listen: false).role == 'admin';
    
    _messageController.clear();
    FocusScope.of(context).unfocus(); // Hide keyboard after sending
    
    await _supportService.sendMessage(
      threadId: widget.thread.id,
      content: content,
      isFromAdmin: isAdmin,
    );
  }
  
  Future<void> _resolveTicket() async {
    try {
      await _supportService.updateThreadStatus(
        threadId: widget.thread.id,
        newStatus: 'closed',
      );

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket has been marked as resolved.'),
            backgroundColor: Colors.green,
          )
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'))
        );
      }
    }
  }

  // ✅ UI UPDATE: Rebuilt the message bubble for a modern look
  Widget _buildMessageBubble(SupportMessage message) {
    final bool isMe = message.senderId == _currentUserId;
    
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor = isMe ? const Color(0xFF267873) : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Row(
      mainAxisAlignment: alignment,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(message.content, style: TextStyle(color: textColor, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserRoleProvider>(context, listen: false).role == 'admin';

    return Scaffold(
      // ✅ UI UPDATE: Themed AppBar and background color
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: Text(widget.thread.subject, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin && widget.thread.status != 'closed')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _resolveTicket,
                child: const Text('Mark Resolved', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text("Send a message to start the conversation.", style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    // ✅ UI UPDATE: Using the new message bubble
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ✅ UI UPDATE: Rebuilt the message input bar for a cleaner look
  Widget _buildMessageInput() {
    return Material(
      elevation: 5,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    fillColor: Colors.grey[200],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF267873),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20,),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}