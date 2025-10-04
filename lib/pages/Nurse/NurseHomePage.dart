import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vaccination_system/pages/Nurse/CreateAppointmentPage.dart';
import '../../utils/logoutuser.dart';
import '../../components/CustomBottomNav.dart';

class NurseHomePage extends StatefulWidget {
  const NurseHomePage({super.key});

  @override
  State<NurseHomePage> createState() => _NurseHomePageState();
}

class _NurseHomePageState extends State<NurseHomePage> {
  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, "/nurse_home");
        break;
      case 1:
        Navigator.pushReplacementNamed(context, "/chat");
        break;
      case 2:
        Navigator.pushReplacementNamed(context, "/nurse_settings");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nurse Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("appointments")
                  .where("nurse_id", isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No appointments assigned"));

                return ListView(
                  children: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    final childId = data['child_id'];
                    final vaccineIds = data['vaccination_id'] as List?;
                    final vaccineId = (vaccineIds != null && vaccineIds.isNotEmpty) ? vaccineIds.first : null;
                    return FutureBuilder<List<Map<String, dynamic>?>>(
                      future: Future.wait([
                        FirebaseFirestore.instance.collection('children').doc(childId).get().then((d) => d.exists ? d.data() : null),
                        vaccineId != null
                            ? FirebaseFirestore.instance.collection('vaccinations').doc(vaccineId).get().then((d) => d.exists ? d.data() : null)
                            : Future.value(null),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Card(child: ListTile(title: Text('Loading...')));
                        }
                        final childData = snapshot.data![0];
                        final vaccineData = snapshot.data![1];
                        final childName = childData != null ? childData['name'] ?? childId : childId;
                        final vaccineName = vaccineData != null ? vaccineData['name'] ?? vaccineId : vaccineId;
                        return Card(
                          child: ListTile(
                            title: Text("Child: $childName | Vaccine: $vaccineName"),
                            subtitle: Text("Date: "+(data['date'] ?? '')+" | Status: "+(data['status'] ?? '')),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == "cancel") {
                                  _cancelAppointment(context, doc.id);
                                } else if (value == "reschedule") {
                                  _rescheduleAppointment(context, doc.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: "cancel", child: Text("Cancel")),
                                const PopupMenuItem(value: "reschedule", child: Text("Reschedule")),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateAppointmentPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text("Create Appointment"),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "nurse",
      ),
    );
  }

  void _cancelAppointment(BuildContext context, String id) async {
    String? reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Cancel Appointment"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Reason for cancellation"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text("Submit")),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      await FirebaseFirestore.instance.collection("appointments").doc(id).update({
        "status": "cancelled",
        "cancellation_reason": reason,
        "updated_at": DateTime.now().toIso8601String(),
      });
    }
  }

  void _rescheduleAppointment(BuildContext context, String id) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      await FirebaseFirestore.instance.collection("appointments").doc(id).update({
        "date": newDate.toIso8601String(),
        "status": "rescheduled",
        "updated_at": DateTime.now().toIso8601String(),
      });
    }
  }
}