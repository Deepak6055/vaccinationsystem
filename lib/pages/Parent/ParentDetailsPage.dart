import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../ChildDetailsPage.dart';

class ParentDetailsPage extends StatefulWidget {
  const ParentDetailsPage({super.key});

  @override
  State<ParentDetailsPage> createState() => _ParentDetailsPageState();
}

class _ParentDetailsPageState extends State<ParentDetailsPage> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  DateTime? _dob;
  String? _gender; // ✅ simplified gender

  Future<void> _pickDob() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dob = pickedDate;
      });
    }
  }

  Future<void> _saveParent() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _dob == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }

    final parentRef = FirebaseFirestore.instance.collection('parents').doc(user.uid);

    await parentRef.set({
      'uuid': parentRef.id,
      'name': _nameController.text,
      'dob': Timestamp.fromDate(_dob!),
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _gender ?? '',
      'contact_number': _contactController.text,
      'address': _addressController.text,
      'email': user.email,
      'children': [],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'role': 'parent',
      'linked_profile': parentRef.id,
      'created_at': FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChildDetailsPage(parentUuid: parentRef.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dobText = _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : "Select Date of Birth";

    return Scaffold(
      appBar: AppBar(title: const Text("Parent Details")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Full Name",
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Age",
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                hint: const Text("Select Gender"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Contact Number",
                  labelText: "Contact Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: "Address",
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Date of Birth",
                  ),
                  child: Text(dobText),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _saveParent,
                child: const Text("Save & Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
