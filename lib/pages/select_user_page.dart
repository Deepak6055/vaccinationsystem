import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/chat_id.dart';
import 'chat_screen.dart';

class SelectUserPage extends StatefulWidget {
  const SelectUserPage({super.key});

  @override
  State<SelectUserPage> createState() => _SelectUserPageState();
}

class _SelectUserPageState extends State<SelectUserPage> {
  String? _roleFilter; // 'parent','doctor','nurse','admin' or null for all

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    Query usersQuery = FirebaseFirestore.instance.collection('users');
    if (_roleFilter != null) usersQuery = usersQuery.where('role', isEqualTo: _roleFilter);

    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                _roleChip('all', 'All'),
                _roleChip('parent', 'Parents'),
                _roleChip('doctor', 'Doctors'),
                _roleChip('nurse', 'Nurses'),
                _roleChip('admin', 'Admins'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersQuery.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs.where((d) => d.id != currentUid).toList();
                if (docs.isEmpty) return const Center(child: Text('No users found'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final u = docs[i].data() as Map<String, dynamic>;
                    final uid = docs[i].id;
                    final name = u['name'] ?? u['email'] ?? uid;
                    final role = u['role'] ?? '';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(role),
                      onTap: () async {
                        final chatId = chatIdFor(currentUid, uid);
                        final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
                        final chatSnapshot = await chatDoc.get();
                        print('[DEBUG] Current UID: $currentUid, Selected/Other UID: $uid');
                        print('[DEBUG] ChatId to use: $chatId');
                        if (!chatSnapshot.exists) {
                          final chatFields = {
                            'participants': [currentUid, uid],
                            'lastMessage': 'Chat started',
                            'lastSender': currentUid,
                            'updatedAt': FieldValue.serverTimestamp(),
                            'lastReadBy': [],
                          };
                          print('[DEBUG] Creating chat with fields: $chatFields');
                          await chatDoc.set(chatFields);
                          final messageFields = {
                            'senderId': currentUid,
                            'text': 'Chat started',
                            'createdAt': FieldValue.serverTimestamp(),
                            'readBy': [currentUid],
                          };
                          print('[DEBUG] Creating initial message: $messageFields');
                          await chatDoc.collection('messages').add(messageFields);
                        } else {
                          print('[DEBUG] Chat already exists for chatId: $chatId');
                        }
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chatId, otherUid: uid),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _roleChip(String key, String label) {
    final selected = (_roleFilter == null && key == 'all') || (_roleFilter == key);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _roleFilter = (key == 'all') ? null : (key == 'all' ? null : key);
        });
      },
    );
  }
}
