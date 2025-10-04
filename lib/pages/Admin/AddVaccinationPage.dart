import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVaccinationPage extends StatefulWidget {
  const AddVaccinationPage({super.key});

  @override
  State<AddVaccinationPage> createState() => _AddVaccinationPageState();
}

class _AddVaccinationPageState extends State<AddVaccinationPage> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _batchController = TextEditingController();

  Future<void> _saveVaccination() async {
    final docRef = FirebaseFirestore.instance.collection('vaccinations').doc();

    await docRef.set({
      "id": docRef.id,
      "name": _nameController.text,
      "dosage": _dosageController.text,
      "manufacturer": _manufacturerController.text,
      "batch_number": _batchController.text,
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vaccination added successfully")),
    );
    Navigator.pushReplacementNamed(context, "/admin_home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Vaccination")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Vaccine Name")),
            TextField(controller: _dosageController, decoration: const InputDecoration(labelText: "Dosage")),
            TextField(controller: _manufacturerController, decoration: const InputDecoration(labelText: "Manufacturer")),
            TextField(controller: _batchController, decoration: const InputDecoration(labelText: "Batch Number")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveVaccination, child: const Text("Save Vaccination")),
          ],
        ),
      ),
    );
  }
}
