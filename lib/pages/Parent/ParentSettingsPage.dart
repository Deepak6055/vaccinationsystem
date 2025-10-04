import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/CustomBottomNav.dart';
import '../ChildDetailsPage.dart';

class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = true;
  String? _parentDocId;
  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Fetch parent document
    final parentSnap = await FirebaseFirestore.instance
        .collection("parents")
        .where("email", isEqualTo: user.email)
        .limit(1)
        .get();

    if (parentSnap.docs.isNotEmpty) {
      final doc = parentSnap.docs.first;
      _parentDocId = doc.id;
      final data = doc.data();

      _nameController.text = data["name"] ?? "";
      _phoneController.text = data["phone"] ?? "";
      _addressController.text = data["address"] ?? "";

      // Fetch children for this parent
      final childrenSnap = await FirebaseFirestore.instance
          .collection("children")
          .where("parent_id", isEqualTo: _parentDocId)
          .get();

      _children = childrenSnap.docs
          .map((d) => {
                "id": d.id,
                ...d.data(),
                "nameController": TextEditingController(text: d["name"] ?? ""),
                "dobController": TextEditingController(text: d["dob"] ?? ""),
                "genderController": TextEditingController(text: d["gender"] ?? ""),
              })
          .toList();
    }

    setState(() => _loading = false);
  }

  Future<void> _saveParentData() async {
    if (_parentDocId == null) return;

    // Save parent info
    await FirebaseFirestore.instance.collection("parents").doc(_parentDocId).update({
      "name": _nameController.text,
      "phone": _phoneController.text,
      "address": _addressController.text,
      "updated_at": DateTime.now().toIso8601String(),
    });

    // Save children info
    for (var child in _children) {
      await FirebaseFirestore.instance.collection("children").doc(child["id"]).update({
        "name": child["nameController"].text,
        "dob": child["dobController"].text,
        "gender": child["genderController"].text,
        "updated_at": DateTime.now().toIso8601String(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile & Children updated successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      appBar: AppBar(title: const Text("Parent Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Parent Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 20),

            const Text("Children Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._children.map((child) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: child["nameController"],
                        decoration: const InputDecoration(labelText: "Child Name"),
                      ),
                      TextField(
                        controller: child["dobController"],
                        decoration: const InputDecoration(labelText: "Date of Birth"),
                      ),
                      TextField(
                        controller: child["genderController"],
                        decoration: const InputDecoration(labelText: "Gender"),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Child"),
              onPressed: () async {
                if (_parentDocId != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChildDetailsPage(parentUuid: _parentDocId!),
                    ),
                  );
                  // Reload after adding
                  _loadParentData();
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveParentData,
              child: const Text("Save Changes"),
            )
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: _onNavTap,
        role: "parent",
      ),
    );
  }
}
