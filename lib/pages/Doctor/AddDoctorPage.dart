import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({super.key});

  @override
  State<AddDoctorPage> createState() => _AddDoctorPageState();
}
//doctor@gmail.com
//Doctor@2025
class _AddDoctorPageState extends State<AddDoctorPage> {
  final _nameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  List<String> _selectedVaccines = [];
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<List<Map<String, dynamic>>> _fetchVaccines() async {
    QuerySnapshot snap =
        await FirebaseFirestore.instance.collection('vaccinations').get();
    // Attach docId to each vaccine map
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['docId'] = d.id;
      return data;
    }).toList();
  }

  Future<void> _saveDoctor() async {
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
      final docRef = FirebaseFirestore.instance.collection('doctors').doc();
      await docRef.set({
        "id": docRef.id,
        "name": _nameController.text,
        "qualification": _qualificationController.text,
        "license_number": _licenseController.text,
        "specialization": _specializationController.text,
        "vaccinations": _selectedVaccines,
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      });
      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        "id": cred.user!.uid,
        "name": _nameController.text,
        "email": _emailController.text.trim(),
        "qualification": _qualificationController.text,
        "license_number": _licenseController.text,
        "specialization": _specializationController.text,
        "vaccinations": _selectedVaccines,
        "role": "doctor",
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor added successfully")),
      );
      Navigator.pushReplacementNamed(context, "/admin_home");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add doctor: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Doctor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _qualificationController, decoration: const InputDecoration(labelText: "Qualification")),
            TextField(controller: _licenseController, decoration: const InputDecoration(labelText: "License Number")),
            TextField(controller: _specializationController, decoration: const InputDecoration(labelText: "Specialization")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchVaccines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var vaccines = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Vaccines:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...vaccines.map((vaccine) {
                      final vaccineId = vaccine['docId'];
                      return CheckboxListTile(
                        title: Text(vaccine['name'] ?? ''),
                        value: _selectedVaccines.contains(vaccineId),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedVaccines.add(vaccineId);
                            } else {
                              _selectedVaccines.remove(vaccineId);
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
            ElevatedButton(onPressed: _saveDoctor, child: const Text("Save Doctor")),
          ],
        ),
      ),
    );
  }
}
