import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../components/CustomBottomNav.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUid; // used to display name
  const ChatScreen({required this.chatId, required this.otherUid, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  Timer? _refreshTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _markMessagesAsRead());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<String> _otherName() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.otherUid).get();
    if (!doc.exists) return widget.otherUid;
    final d = doc.data()!;
    return (d['name'] ?? d['email'] ?? widget.otherUid).toString();
  }

  Future<void> notifyMessage(String receiverId, String message) async {
    final supabaseUrl = "https://gqdhezcmagpatxrsuoxi.supabase.co";
    final supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"; // Replace with your actual anon key

    final res = await http.post(
      Uri.parse("$supabaseUrl/functions/v1/FCMTOKEN"),
      headers: {
        "Authorization": "Bearer $supabaseAnonKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "senderId": FirebaseAuth.instance.currentUser!.uid,
        "receiverId": receiverId,
        "message": message,
      }),
    );

    print("Notification API Response: [32m${res.body}[0m");
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;
    _msgController.clear(); // Clear immediately on send
    setState(() => _isSending = true);
    try {
      final uid = _auth.currentUser!.uid;
      final msgRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();

      final now = FieldValue.serverTimestamp();

      await msgRef.set({
        'senderId': uid,
        'text': text,
        'createdAt': now,
      });

      // update chat meta
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': text,
        'lastSender': uid,
        'updatedAt': now,
      });

      // Notify receiver via Supabase Edge Function
      await notifyMessage(widget.otherUid, text);

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } catch (e, st) {
      print('[ERROR] Failed to send message: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final msgs = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('readBy', isNotEqualTo: uid) // only unread by this user
        .get();

    for (var doc in msgs.docs) {
      final data = doc.data();
      final readBy = (data['readBy'] as List?) ?? [];
      if (!readBy.contains(uid)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('createdAt');
    final currentUid = _auth.currentUser!.uid;

    void _onNavTap(int index) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, "/parent_home");
          break;
        case 1:
          Navigator.pushReplacementNamed(context, "/chat");
          break;
        case 2:
          Navigator.pushReplacementNamed(context, "/parent_settings");
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _otherName(),
          builder: (context, snap) {
            return Text(snap.data ?? 'Chat');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final msgs = snap.data!.docs;
                // Mark as read when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _markMessagesAsRead());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index].data() as Map<String, dynamic>;
                    final isMe = m['senderId'] == currentUid;
                    final text = m['text'] ?? '';
                    return Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.purple : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _isSending ? null : _sendMessage,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: _isSending
                          ? const SizedBox(
                              key: ValueKey('sending'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, key: ValueKey('send')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "parent",
        currentIndex: 1, // highlight chat icon
      ),
    );
  }
}
