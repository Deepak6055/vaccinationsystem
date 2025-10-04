import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/logoutuser.dart';
import '../../components/CustomBottomNav.dart';

class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  Future<List<Map<String, dynamic>>> _fetchChildrenWithAppointments() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot parentDoc = await FirebaseFirestore.instance.collection('parents').doc(uid).get();
    if (!parentDoc.exists) return [];

    List<dynamic> childIds = parentDoc['children'] ?? [];
    List<Map<String, dynamic>> children = [];

    for (var childId in childIds) {
      var childDoc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
      if (!childDoc.exists) continue;
      var childData = childDoc.data() as Map<String, dynamic>;

      // Fetch appointments for this child
      var appointmentsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('child_id', isEqualTo: childId)
          .get();
      var appointments = appointmentsSnap.docs.map((doc) => doc.data()).toList();

      children.add({
        'child': childData,
        'appointments': appointments,
      });
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text("Parent Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchChildrenWithAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var children = snapshot.data!;
          if (children.isEmpty) {
            return const Center(child: Text("No children found."));
          }
          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              var child = children[index]['child'];
              var appointments = children[index]['appointments'] as List;
              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(child['name'] ?? 'No Name'),
                  subtitle: Text("Age: "+(child['age']?.toString() ?? '-')+" | Gender: "+(child['gender'] ?? '-')),
                  children: [
                    if (appointments.isEmpty)
                      const ListTile(title: Text("No appointments found.")),
                    ...appointments.map((appt) => ListTile(
                          title: Text("Status: "+(appt['status'] ?? '')),
                          subtitle: Text("Date: "+(appt['date']?.toString() ?? '')),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "parent",
      ),
    );
  }
}
