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

class _DoctorHomePageState extends State<DoctorHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // ✅ Initialize TabController immediately (no LateInitializationError)
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Future<void> _provideService(
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provide Service'),
        content: const Text(
          'Are you sure you want to provide service for this appointment? '
          'This will mark it as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();

      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({
          "status": "completed",
          "service_provided_by": uid,
          "service_provided_at": DateTime.now().toIso8601String(),
          "doctor_name": doctorDoc.data()?['name'] ?? 'Unknown',
          "service_provided": true,
          "updated_at": DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service provided successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "My Appointments", icon: Icon(Icons.assignment)),
            Tab(text: "All Appointments", icon: Icon(Icons.view_list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyAppointmentsTab(uid),
          _buildAllAppointmentsTab(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "doctor",
      ),
    );
  }

  Widget _buildMyAppointmentsTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No appointments assigned."));
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: docs.map((doc) {
            return _buildAppointmentCard(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAllAppointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('status', whereIn: ['scheduled', 'pending_approval'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No available appointments."));
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: docs.map((doc) {
            return _buildAppointmentCard(doc, showProvideService: true);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    QueryDocumentSnapshot doc, {
    bool showProvideService = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final childId = data['child_id'];
    dynamic vaccineField = data['vaccination_id'];
    String? vaccineId;

    if (vaccineField is List && vaccineField.isNotEmpty) {
      vaccineId = vaccineField.first;
    } else if (vaccineField is String && vaccineField.isNotEmpty) {
      vaccineId = vaccineField;
    }

    final vaccineName = data['vaccination_name'] ?? 'Unknown';
    final status = data['status'] ?? 'unknown';

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get()
          .then((d) => d.exists ? d.data() : null),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(child: ListTile(title: Text('Loading...')));
        }

        final childData = snap.data;
        final childName = childData != null ? childData['name'] ?? childId : childId;
        final childAge = childData?['age']?.toString() ?? 'N/A';
        final childGender = childData?['gender'] ?? 'N/A';

        final appointmentDate = data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : null;
        final dateStr = appointmentDate != null
            ? appointmentDate.toLocal().toString().split(' ')[0]
            : 'Not set';

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 2,
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
                            childName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age: $childAge | Gender: $childGender',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.vaccines, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vaccine: $vaccineName',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (showProvideService && status == 'scheduled') ...[
                  const Divider(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _provideService(doc.id, data),
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Provide Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      case 'pending_approval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
