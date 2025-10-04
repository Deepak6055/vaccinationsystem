import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaccination_system/components/BadgeIcon.dart';

class CustomBottomNav extends StatelessWidget {
  final int? currentIndex;
  final Function(int) onTap;
  final String role; // Add this

  const CustomBottomNav({
    super.key,
    this.currentIndex,
    required this.onTap,
    required this.role, // Add this
  });

  int _getIndexFromRoute(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    if (role == "doctor") {
      if (route == '/doctor_home') return 0;
      if (route == '/chat') return 1;
      if (route == '/doctor_settings') return 2;
    } else if (role == "nurse") {
      if (route == '/nurse_home') return 0;
      if (route == '/chat') return 1;
      if (route == '/nurse_settings') return 2;
    }
    else if (role == "parent") {
      if (route == '/parent_home') return 0;
      if (route == '/chat') return 1;
      if (route == '/parent_settings') return 2;
    }
    return 0; // default to home
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = currentIndex ?? _getIndexFromRoute(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: uid == null
              ? const Icon(Icons.chat)
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: uid)
                      .snapshots(),
                  builder: (context, snap) {
                    int unread = 0;
                    if (snap.hasData) {
                      for (var chat in snap.data!.docs) {
                        final lastSender = chat['lastSender'];
                        final lastMessage = chat['lastMessage'];
                        final lastReadBy = chat['lastReadBy'] ?? [];
                        if (lastSender != uid && !(lastReadBy as List).contains(uid) && lastMessage != null && lastMessage != "") {
                          unread++;
                        }
                      }
                    }
                    return BadgeIcon(icon: Icons.chat, count: unread);
                  },
                ),
          label: "Chat",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
      selectedItemColor: const Color.fromARGB(255, 158, 37, 180),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    );
  }
}
