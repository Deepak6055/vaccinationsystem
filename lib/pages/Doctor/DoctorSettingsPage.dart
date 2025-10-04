import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/CustomBottomNav.dart';

class DoctorSettingsPage extends StatefulWidget {
  const DoctorSettingsPage({super.key});

  @override
  State<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends State<DoctorSettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  bool _loading = true;

  String? _docId;
  int _selectedIndex = 2;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, "/doctor_home");
        break;
      case 1:
        Navigator.pushReplacementNamed(context, "/chat");
        break;
      case 2:
        // Already on settings
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Assume doctor email is unique → we match by email
    final snap = await FirebaseFirestore.instance
        .collection("doctors")
        .where("email", isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      _docId = doc.id;
      final data = doc.data();

      _nameController.text = data["name"] ?? "";
      _qualificationController.text = data["qualification"] ?? "";
      _licenseController.text = data["license_number"] ?? "";
      _specializationController.text = data["specialization"] ?? "";
    }

    setState(() => _loading = false);
  }

  Future<void> _saveDoctorData() async {
    if (_docId == null) return;

    await FirebaseFirestore.instance.collection("doctors").doc(_docId).update({
      "name": _nameController.text,
      "qualification": _qualificationController.text,
      "license_number": _licenseController.text,
      "specialization": _specializationController.text,
      "updated_at": DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _qualificationController, decoration: const InputDecoration(labelText: "Qualification")),
            TextField(controller: _licenseController, decoration: const InputDecoration(labelText: "License Number")),
            TextField(controller: _specializationController, decoration: const InputDecoration(labelText: "Specialization")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDoctorData,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role:"doctor",
      ),
    );
  }
}
