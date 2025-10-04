import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/CustomBottomNav.dart';

class NurseSettingsPage extends StatefulWidget {
  const NurseSettingsPage({super.key});

  @override
  State<NurseSettingsPage> createState() => _NurseSettingsPageState();
}

class _NurseSettingsPageState extends State<NurseSettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _nurseIdController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _loading = true;
  String? _docId;

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
  void initState() {
    super.initState();
    _loadNurseData();
  }

  Future<void> _loadNurseData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // fetch nurse document by email
    final snap = await FirebaseFirestore.instance
        .collection("nurses")
        .where("email", isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      _docId = doc.id;
      final data = doc.data();

      _nameController.text = data["name"] ?? "";
      _qualificationController.text = data["qualification"] ?? "";
      _nurseIdController.text = data["nurse_id"] ?? "";
      _departmentController.text = data["department"] ?? "";
    }

    setState(() => _loading = false);
  }

  Future<void> _saveNurseData() async {
    if (_docId == null) return;

    await FirebaseFirestore.instance.collection("nurses").doc(_docId).update({
      "name": _nameController.text,
      "qualification": _qualificationController.text,
      "nurse_id": _nurseIdController.text,
      "department": _departmentController.text,
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
      appBar: AppBar(title: const Text("Nurse Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: "Qualification"),
              ),
              TextField(
                controller: _nurseIdController,
                decoration: const InputDecoration(labelText: "Nurse ID"),
              ),
              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: "Department"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveNurseData,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "nurse",
      ),
    );
  }
}
