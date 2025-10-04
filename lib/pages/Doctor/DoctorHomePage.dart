import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/logoutuser.dart';
import '../../components/CustomBottomNav.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // Home
        break;
      case 1:
        Navigator.pushNamed(context, "/chat");
        break;
      case 2:
        Navigator.pushNamed(context, "/doctor_settings");
        break;
    }
  }

  Future<void> _markCompleted(String appointmentId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
      "status": "completed",
      "updated_at": DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctor_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No appointments assigned."));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final childId = data['child_id'];
              final vaccineIds = data['vaccination_id'] as List?;
              final vaccineId = (vaccineIds != null && vaccineIds.isNotEmpty) ? vaccineIds.first : null;
              final appointmentDate = data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : null;
              final now = DateTime.now();
              final isTodayOrPast = appointmentDate != null && !appointmentDate.isAfter(DateTime(now.year, now.month, now.day));
              return FutureBuilder<List<Map<String, dynamic>?>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('children').doc(childId).get().then((d) => d.exists ? d.data() : null),
                  vaccineId != null
                      ? FirebaseFirestore.instance.collection('vaccinations').doc(vaccineId).get().then((d) => d.exists ? d.data() : null)
                      : Future.value(null),
                ]),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Card(child: ListTile(title: Text('Loading...')));
                  }
                  final childData = snap.data![0];
                  final vaccineData = snap.data![1];
                  final childName = childData != null ? childData['name'] ?? childId : childId;
                  final vaccineName = vaccineData != null ? vaccineData['name'] ?? vaccineId : vaccineId;
                  return Card(
                    child: ListTile(
                      title: Text("Child: $childName | Vaccine: $vaccineName"),
                      subtitle: Text("Status: "+(data['status'] ?? '')+" | Date: "+(appointmentDate != null ? appointmentDate.toLocal().toString().split(' ')[0] : '')),
                      trailing: (data['status'] == "scheduled" && isTodayOrPast)
                          ? ElevatedButton(
                              onPressed: () => _markCompleted(doc.id),
                              child: const Text("Mark Completed"),
                            )
                          : Text(data['status'], style: const TextStyle(color: Colors.green)),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "doctor",
      ),
    );
  }
}
