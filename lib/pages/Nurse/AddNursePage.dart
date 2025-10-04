import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNursePage extends StatefulWidget {
  const AddNursePage({super.key});

  @override
  State<AddNursePage> createState() => _AddNursePageState();
}
//email:nurse@gmail.com
//password:Nurse@2025
class _AddNursePageState extends State<AddNursePage> {
  final _nameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _registrationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<String> _selectedDoctors = [];
  String? _selectedShift;

  Future<List<Map<String, dynamic>>> _fetchDoctors() async {
    QuerySnapshot snap =
        await FirebaseFirestore.instance.collection('doctors').get();
    // Attach docId to each doctor map
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['docId'] = d.id;
      return data;
    }).toList();
  }

  Future<void> _saveNurse() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final docRef = FirebaseFirestore.instance.collection('nurses').doc();
      await docRef.set({
        "id": docRef.id,
        "name": _nameController.text,
        "qualification": _qualificationController.text,
        "registration_id": _registrationController.text,
        "doctor_ids": _selectedDoctors,
        "shifts": [_selectedShift],
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      });
      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        "id": cred.user!.uid,
        "name": _nameController.text,
        "email": _emailController.text.trim(),
        "qualification": _qualificationController.text,
        "registration_id": _registrationController.text,
        "doctor_ids": _selectedDoctors,
        "shifts": [_selectedShift],
        "role": "nurse",
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nurse added successfully")),
      );
      Navigator.pushReplacementNamed(context, "/admin_home");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add nurse: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Nurse")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _qualificationController, decoration: const InputDecoration(labelText: "Qualification")),
            TextField(controller: _registrationController, decoration: const InputDecoration(labelText: "Registration ID")),
            const SizedBox(height: 20),

            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Shift"),
              items: ["morning", "evening", "night"].map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) => setState(() => _selectedShift = val),
            ),

            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchDoctors(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var doctors = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Assign Doctors:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...doctors.map((doc) {
                      final docId = doc['docId'];
                      return CheckboxListTile(
                        title: Text(doc['name'] ?? ''),
                        value: _selectedDoctors.contains(docId),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedDoctors.add(docId);
                            } else {
                              _selectedDoctors.remove(docId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveNurse, child: const Text("Save Nurse")),
          ],
        ),
      ),
    );
  }
}
