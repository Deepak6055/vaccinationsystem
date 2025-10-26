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

class _NurseHomePageState extends State<NurseHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: const Text("Nurse Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending Approval", icon: Icon(Icons.pending_actions)),
            Tab(text: "My Appointments", icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingApprovalsTab(),
          _buildMyAppointmentsTab(userId),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "nurse",
      ),
    );
  }

  Widget _buildPendingApprovalsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.orange.shade50,
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Review and approve appointment requests from parents",
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("appointments")
                .where("status", isEqualTo: "pending_approval")
                .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No pending appointments to review"),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    final childId = data['child_id'];
                    final vaccineName = data['vaccination_name'] ?? 'Unknown';
                    final vaccineId = data['vaccination_id'] ?? '';
                    
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: FirebaseFirestore.instance
                          .collection('children')
                          .doc(childId)
                          .get()
                          .then((d) => d.exists ? d.data() : null),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Card(child: ListTile(title: Text('Loading...')));
                        }
                        final childData = snapshot.data;
                        final childName = childData != null ? childData['name'] ?? childId : childId;
                        
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Child: $childName",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text("Vaccine: $vaccineName"),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Date: ${_formatDate(data['date'])}",
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _rejectAppointment(doc.id),
                                      child: const Text("Reject"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _approveAppointment(doc.id, childId, data['doctor_id'], vaccineId, data['date'], context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text("Approve"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    Widget _buildMyAppointmentsTab(String userId) {
      return Column(
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
                if (docs.isEmpty) {
                  return const Center(child: Text("No appointments assigned"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    final childId = data['child_id'];
                    dynamic vaccineField = data['vaccination_id'];
                    String? vaccineId;

                    if (vaccineField is List && vaccineField.isNotEmpty) {
                      vaccineId = vaccineField.first;
                    } else if (vaccineField is String && vaccineField.isNotEmpty) {
                      vaccineId = vaccineField;
                    } else {
                      vaccineId = null;
                    }

                    final vaccineName = data['vaccination_name'] ?? 'Unknown';
                    
                    return FutureBuilder<List<Map<String, dynamic>?>>(
                      future: Future.wait([
                        FirebaseFirestore.instance.collection('children').doc(childId).get().then((d) => d.exists ? d.data() : null),
                        vaccineId != null && vaccineId is String
                            ? FirebaseFirestore.instance.collection('vaccinations').doc(vaccineId).get().then((d) => d.exists ? d.data() : null)
                            : Future.value(null),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Card(child: ListTile(title: Text('Loading...')));
                        }
                        final childData = snapshot.data![0];
                        final childName = childData != null ? childData['name'] ?? childId : childId;
                        
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text("Child: $childName"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Vaccine: $vaccineName"),
                                Text("Date: ${_formatDate(data['date'])}"),
                                Text(
                                  "Status: ${data['status'] ?? 'Unknown'}",
                                  style: TextStyle(
                                    color: _getStatusColor(data['status']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
                  },
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
      );
    }

    Color _getStatusColor(String? status) {
      switch (status) {
        case 'scheduled':
          return Colors.blue;
        case 'completed':
          return Colors.green;
        case 'cancelled':
          return Colors.red;
        case 'rescheduled':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    String _formatDate(dynamic dateValue) {
      if (dateValue == null) return 'Not set';
      if (dateValue is Timestamp) {
        return dateValue.toDate().toString().split(' ')[0];
      } else if (dateValue is String) {
        try {
          final date = DateTime.parse(dateValue);
          return date.toString().split(' ')[0];
        } catch (e) {
          return dateValue;
        }
      }
      return dateValue.toString();
    }

    Future<void> _approveAppointment(String appointmentId, String childId, String? doctorId, String vaccineId, dynamic dateValue, BuildContext context) async {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      try {
        await FirebaseFirestore.instance.collection("appointments").doc(appointmentId).update({
          "status": "scheduled",
          "nurse_id": userId,
          "updated_at": DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment approved successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error approving appointment: $e")),
          );
        }
      }
    }

    Future<void> _rejectAppointment(String appointmentId) async {
      final confirmation = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Reject Appointment"),
          content: const Text("Are you sure you want to reject this appointment request?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reject"),
            ),
          ],
        ),
      );

      if (confirmation == true) {
        try {
          await FirebaseFirestore.instance.collection("appointments").doc(appointmentId).update({
            "status": "rejected",
            "updated_at": DateTime.now().toIso8601String(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Appointment rejected")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error rejecting appointment: $e")),
            );
          }
        }
      }
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