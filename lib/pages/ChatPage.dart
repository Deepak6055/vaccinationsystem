import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/CustomBottomNav.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    print('[ChatPage] FirebaseAuth.currentUser: ' + (user?.uid ?? 'null'));
    if (user == null) {
      print('[ChatPage] No user found, defaulting to nurse');
      return 'nurse';
    }
    final email = user.email;
    print('[ChatPage] User email: $email');
    // Query the users collection for this email
    final userSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
    print('[ChatPage] userSnap.docs.length: ${userSnap.docs.length}');
    if (userSnap.docs.isNotEmpty) {
      final data = userSnap.docs.first.data();
      final role = data['role'] ?? '';
      print('[ChatPage] Role from users collection: $role');
      return role.toString();
    }
    print('[ChatPage] No user document found for this email. Returning empty string.');
    return '';
  }

  void _onNavTap(BuildContext context, String role, int index) {
    if (role == 'doctor') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, "/doctor_home");
          break;
        case 1:
          // Already on chat
          break;
        case 2:
          Navigator.pushReplacementNamed(context, "/doctor_settings");
          break;
      }
    } else if (role == 'nurse') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, "/nurse_home");
          break;
        case 1:
          // Already on chat
          break;
        case 2:
          Navigator.pushReplacementNamed(context, "/nurse_settings");
          break;
      }
    } else if (role == 'parent') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, "/parent_home");
          break;
        case 1:
          // Already on chat
          break;
        case 2:
          Navigator.pushReplacementNamed(context, "/parent_settings");
          break;
      }
    } else if (role == 'admin') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, "/admin_home");
          break;
        case 1:
          // Already on chat
          break;
        case 2:
          Navigator.pushReplacementNamed(context, "/admin_settings");
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[ChatPage] build called');
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        print('[ChatPage] FutureBuilder snapshot: connectionState=${snapshot.connectionState}, data=${snapshot.data}, hasError=${snapshot.hasError}');
        final role = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || role == null || role.isEmpty) {
          print('[ChatPage] Still loading or role is empty/null');
          // Show loading while role is being determined
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        print('[ChatPage] Role determined: $role');
        return Scaffold(
          appBar: AppBar(title: const Text("Chat")),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Align(
                alignment: Alignment.centerLeft,
                child: Card(
                  color: Colors.grey,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Hello Doctor 👋"),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Card(
                  color: Colors.purple,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Hello Parent! How can I help?"),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.purple),
                      onPressed: () {
                        // send message logic goes here
                      },
                    )
                  ],
                ),
              ),
              CustomBottomNav(
                onTap: (index) => _onNavTap(context, role, index),
                role: role,
              ),
            ],
          ),
        );
      },
    );
  }
}
