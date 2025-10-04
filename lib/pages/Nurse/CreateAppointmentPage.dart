import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/AddChildDialog.dart';
class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  String? _selectedChild;
  String? _selectedDoctor;
  String? _selectedVaccine;
  DateTime? _selectedDate;

  Future<List<Map<String, dynamic>>> _fetchChildren() async {
    final snap = await FirebaseFirestore.instance.collection("children").get();
    return snap.docs.map((d) => {"id": d.id, "name": d["name"]}).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchDoctors() async {
    final snap = await FirebaseFirestore.instance.collection("doctors").get();
    return snap.docs.map((d) => {"id": d.id, "name": d["name"]}).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchVaccines() async {
    final snap = await FirebaseFirestore.instance.collection("vaccinations").get();
    return snap.docs.map((d) => {"id": d.id, "name": d["name"]}).toList();
  }

  Future<void> _saveAppointment() async {
    if (_selectedChild == null || _selectedDoctor == null || _selectedVaccine == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("appointments").doc();

    await docRef.set({
      "uuid": docRef.id,
      "child_id": _selectedChild,
      "doctor_id": _selectedDoctor,
      "nurse_id": uid,
      "vaccination_id": [_selectedVaccine],
      "date": _selectedDate!.toIso8601String(),
      "status": "scheduled",
      "consent_form_signed": false,
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment created")));
    Navigator.pop(context);
  }

  void _addNewChild() async {
    await showDialog(
      context: context,
      builder: (_) => const AddChildDialog(),
    );
    setState(() {}); // refresh children list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Appointment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Child dropdown
            FutureBuilder(
              future: _fetchChildren(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var children = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        items: children.map((c) => DropdownMenuItem(value: c["id"], child: Text(c["name"]))).toList(),
                        onChanged: (val) => setState(() => _selectedChild = val as String?),
                        decoration: const InputDecoration(labelText: "Select Child"),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addNewChild,
                    )
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Doctor dropdown
            FutureBuilder(
              future: _fetchDoctors(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var doctors = snapshot.data!;
                return DropdownButtonFormField(
                  items: doctors.map((d) => DropdownMenuItem(value: d["id"], child: Text(d["name"]))).toList(),
                  onChanged: (val) => setState(() => _selectedDoctor = val as String?),
                  decoration: const InputDecoration(labelText: "Doctor"),
                );
              },
            ),
            const SizedBox(height: 16),

            // Vaccine dropdown
            FutureBuilder(
              future: _fetchVaccines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var vaccines = snapshot.data!;
                return DropdownButtonFormField(
                  items: vaccines.map((v) => DropdownMenuItem(value: v["id"], child: Text(v["name"]))).toList(),
                  onChanged: (val) => setState(() => _selectedVaccine = val as String?),
                  decoration: const InputDecoration(labelText: "Vaccine"),
                );
              },
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Text(_selectedDate == null ? "Pick Date" : _selectedDate.toString()),
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveAppointment, child: const Text("Save Appointment")),
          ],
        ),
      ),
    );
  }
}
