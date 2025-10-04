import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'select_user_page.dart';
import '../components/CustomBottomNav.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    void _onNavTap(int index) async {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userDoc.data()?['role'] ?? 'parent';
      String homeRoute = '/parent_home';
      String chatRoute = '/chat';
      String settingsRoute = '/parent_settings';
      switch (role) {
        case 'doctor':
          homeRoute = '/doctor_home';
          chatRoute = '/chat';
          settingsRoute = '/doctor_settings';
          break;
        case 'nurse':
          homeRoute = '/nurse_home';
          chatRoute = '/chat';
          settingsRoute = '/nurse_settings';
          break;
        case 'admin':
          homeRoute = '/admin_home';
          chatRoute = '/chat';
          settingsRoute = '/admin_settings';
          break;
        case 'parent':
        default:
          homeRoute = '/parent_home';
          chatRoute = '/chat';
          settingsRoute = '/parent_settings';
      }
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, homeRoute);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, chatRoute);
          break;
        case 2:
          Navigator.pushReplacementNamed(context, settingsRoute);
          break;
      }
    }

    Future<void> _startNewChat() async {
      print("started a new chat");
      final selectedUser = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SelectUserPage()),
      );
      if (selectedUser == null) return;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final otherUid = selectedUser is String
          ? selectedUser
          : selectedUser['uid'] ?? selectedUser['email'];
      if (otherUid == null || otherUid == uid) return;
      final chatId = uid.compareTo(otherUid) < 0
          ? "${uid}_$otherUid"
          : "${otherUid}_$uid";
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, otherUid: otherUid),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SelectUserPage()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsRef
            .where('participants', arrayContains: uid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet d start a conversation!"));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final chat = docs[i].data() as Map<String, dynamic>;
              final chatId = docs[i].id;
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUid = participants.firstWhere((p) => p != uid, orElse: () => uid);

              final lastMessage = chat['lastMessage'] ?? '';
              final updatedAt = chat['updatedAt'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                builder: (context, userSnap) {
                  final userData = userSnap.hasData && userSnap.data!.exists
                      ? userSnap.data!.data() as Map<String, dynamic>
                      : null;
                  final displayName = userData != null
                      ? (userData['name'] ?? userData['email'] ?? otherUid)
                      : otherUid;

                  return ListTile(
                    title: Text(displayName),
                    subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: updatedAt != null ? Text(_formatTimestamp(updatedAt)) : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: chatId, otherUid: otherUid),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: const Icon(Icons.chat),
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "parent",
        currentIndex: 1, // highlight chat icon
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      final dt = (ts is Timestamp) ? ts.toDate() : DateTime.parse(ts.toString());
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return '';
    }
  }
}
